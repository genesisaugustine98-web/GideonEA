//+------------------------------------------------------------------+
//|                                                     GideonEA.mq5 |
//|            RSI mean-reversion: D1 core (5 pairs) + AUDUSD H4 sat  |
//|                                           built by Gideon for AG |
//+------------------------------------------------------------------+
#property copyright "Gideon for AG BABY"
#property version   "3.00"

#include <Trade\Trade.mqh>

//--- inputs: core D1 engine
input long   InpMagicD1        = 20260930; // D1 core magic number
input int    InpRsiPeriod      = 14;       // D1 RSI period
input double InpRsiBuy         = 30.0;     // RSI below this -> BUY signal
input double InpRsiSell        = 70.0;     // RSI above this -> SELL signal
input double InpVolBps_D1      = 50.0;     // D1 vol target, bps of equity/day/pair
//--- inputs: H4 satellite (AUDUSD)
input long   InpMagicH4        = 20260931; // H4 satellite magic number
input bool   InpTradeH4AUDUSD  = true;     // Trade AUDUSD H4 satellite
input int    InpRsiPeriod_H4   = 16;       // H4 RSI period
input double InpVolBps_H4      = 25.0;     // H4 vol target, bps of equity/day
//--- inputs: risk & execution
input int    InpAtrPeriod      = 14;       // ATR period
input double InpDisasterAtr    = 12.0;     // Disaster stop = this x ATR (tail only)
input double InpMaxSpreadPips  = 30.0;     // Skip entries if spread wider than this
input bool   InpTradeEURUSD    = true;     // Trade EURUSD (D1)
input bool   InpTradeGBPUSD    = false;    // Trade GBPUSD (edge faded -> off)
input bool   InpTradeUSDJPY    = true;     // Trade USDJPY (D1)
input bool   InpTradeAUDUSD    = true;     // Trade AUDUSD (D1)
input bool   InpTradeEURGBP    = true;     // Trade EURGBP (D1) - added v3.00
input bool   InpTradeGBPJPY    = true;     // Trade GBPJPY (D1) - added v3.00
input string InpSymbolSuffix   = "";       // Broker symbol suffix (HFM: leave empty)

CTrade trade;

struct Engine
{
   string          sym;
   ENUM_TIMEFRAMES tf;
   int             rsiPeriod;
   long            magic;
   double          volTarget;   // fraction of equity
   bool            enabled;
   string          tag;         // "D1"/"H4" for display
   int             target;      // -1, 0, +1
   bool            dead;        // true after disaster stop -> wait for fresh signal
   datetime        lastBar;
   bool            hadPos;
   double          rsi;
};

#define NENG 7
Engine gE[NENG];

int DigitsOf(string sym)
{
   return((int)SymbolInfoInteger(sym, SYMBOL_DIGITS));
}

double CalcRSI(const MqlRates &r[], int period, int shift)
{
   double g = 0.0, l = 0.0;
   for(int k = shift; k < shift + period; k++)
   {
      double d = r[k].close - r[k + 1].close;
      if(d > 0) g += d;
      else      l -= d;
   }
   g /= period;
   l /= period;
   if(l == 0.0) return(g == 0.0 ? 50.0 : 100.0);
   return(100.0 - 100.0 / (1.0 + g / l));
}

double CalcATR(const MqlRates &r[], int period, int shift)
{
   double s = 0.0;
   for(int k = shift; k < shift + period; k++)
      s += MathAbs(r[k].close - r[k + 1].close);
   return(s / period);
}

bool SpreadOK(string sym)
{
   long   sp = SymbolInfoInteger(sym, SYMBOL_SPREAD);
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    dg = DigitsOf(sym);
   double pip = pt * ((dg == 3 || dg == 5) ? 10.0 : 1.0);
   double spPips = sp * pt / pip;
   if(spPips > InpMaxSpreadPips)
   {
      Print(sym, ": spread too wide (", DoubleToString(spPips, 1), " pips), skipping entry");
      return(false);
   }
   return(true);
}

double CalcVolumeVolTarget(string sym, double atrMove, double volTarget)
{
   if(atrMove <= 0.0 || volTarget <= 0.0) return(0.0);
   double price = SymbolInfoDouble(sym, SYMBOL_BID);
   if(price <= 0.0) return(0.0);
   double profit1lot = 0.0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY, sym, 1.0, price, price + atrMove, profit1lot))
   {
      Print(sym, ": OrderCalcProfit failed");
      return(0.0);
   }
   if(profit1lot <= 0.0) return(0.0);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double vol = (volTarget * equity) / profit1lot;
   double mn = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(st <= 0.0) return(0.0);
   vol = MathFloor(vol / st) * st;
   if(vol < mn)
   {
      Print(sym, ": account too small for vol-target sizing (need min ",
            DoubleToString(mn, 2), " lots)");
      return(0.0);
   }
   if(vol > mx) vol = mx;
   return(NormalizeDouble(vol, 2));
}

double NetVol(int e)
{
   double nv = 0.0;
   for(int k = PositionsTotal() - 1; k >= 0; k--)
   {
      ulong tk = PositionGetTicket((uint)k);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != gE[e].sym) continue;
      if(PositionGetInteger(POSITION_MAGIC) != gE[e].magic) continue;
      long   pt = PositionGetInteger(POSITION_TYPE);
      double vv = PositionGetDouble(POSITION_VOLUME);
      nv += (pt == POSITION_TYPE_BUY ? vv : -vv);
   }
   return(nv);
}

void CloseAll(int e)
{
   for(int k = PositionsTotal() - 1; k >= 0; k--)
   {
      ulong tk = PositionGetTicket((uint)k);
      if(tk == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != gE[e].sym) continue;
      if(PositionGetInteger(POSITION_MAGIC) != gE[e].magic) continue;
      if(!trade.PositionClose(tk))
         Print(gE[e].sym, "(", gE[e].tag, "): close failed #", tk, " ",
               trade.ResultRetcodeDescription());
   }
}

void ProcessEngine(int e)
{
   string sym = gE[e].sym;
   int need = MathMax(gE[e].rsiPeriod, InpAtrPeriod) + 3;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(sym, gE[e].tf, 0, need, rates) < need)
   {
      Print(sym, "(", gE[e].tag, "): not enough history yet");
      return;
   }

   double rsi = CalcRSI(rates, gE[e].rsiPeriod, 1);
   double atr = CalcATR(rates, InpAtrPeriod, 1);
   gE[e].rsi = rsi;

   int sig = 0;
   if(rsi < InpRsiBuy)       sig =  1;
   else if(rsi > InpRsiSell) sig = -1;
   if(sig != 0 && sig != gE[e].target)
   {
      gE[e].target = sig;
      gE[e].dead = false;      // fresh signal -> re-arm
   }
   int target = gE[e].target;

   double netVol = NetVol(e);
   bool hasPos = (netVol != 0.0);
   if(gE[e].hadPos && !hasPos && target != 0)
   {
      gE[e].dead = true;       // disaster stop fired -> stand down till fresh signal
      Print(sym, "(", gE[e].tag, "): disaster stop hit, standing down");
   }
   gE[e].hadPos = hasPos;

   int curDir = (netVol > 0.0) ? 1 : ((netVol < 0.0) ? -1 : 0);

   if(target == 0)
   {
      if(hasPos) CloseAll(e);
      return;
   }
   if(curDir == target) return;  // already positioned; disaster stop is server-side
   if(curDir != 0) CloseAll(e);  // flip

   if(gE[e].dead)
   {
      Print(sym, "(", gE[e].tag, "): waiting for fresh signal after disaster stop");
      return;
   }
   if(!SpreadOK(sym)) return;

   double price  = (target > 0) ? SymbolInfoDouble(sym, SYMBOL_ASK)
                                : SymbolInfoDouble(sym, SYMBOL_BID);
   double slDist = InpDisasterAtr * atr;
   int    dg = DigitsOf(sym);
   double sl = NormalizeDouble((target > 0) ? price - slDist : price + slDist, dg);

   double vol = CalcVolumeVolTarget(sym, atr, gE[e].volTarget);
   if(vol <= 0.0) return;

   trade.SetExpertMagicNumber(gE[e].magic);
   trade.SetTypeFillingBySymbol(sym);
   bool ok = (target > 0) ? trade.Buy(vol, sym, 0.0, sl, 0.0, "GideonEA v3")
                          : trade.Sell(vol, sym, 0.0, sl, 0.0, "GideonEA v3");
   if(ok)
   {
      Print(sym, "(", gE[e].tag, "): ", (target > 0 ? "BUY " : "SELL "),
            DoubleToString(vol, 2), " lots, disaster-SL ",
            DoubleToString(sl, dg), " (RSI=", DoubleToString(rsi, 1), ")");
      gE[e].hadPos = true;
   }
   else
      Print(sym, "(", gE[e].tag, "): order failed: ", trade.ResultRetcode(), " ",
            trade.ResultRetcodeDescription());
}

void RunOnce()
{
   for(int e = 0; e < NENG; e++)
   {
      if(!gE[e].enabled) continue;
      datetime bt = iTime(gE[e].sym, gE[e].tf, 0);
      if(bt == 0) continue;
      if(bt != gE[e].lastBar)
      {
         gE[e].lastBar = bt;
         ProcessEngine(e);
      }
   }
   string t = "GideonEA v3.00  |  " + TimeToString(TimeCurrent(), TIME_DATE) + "\n";
   for(int e = 0; e < NENG; e++)
   {
      if(!gE[e].enabled) continue;
      string st = "flat";
      if(gE[e].target > 0) st = "LONG";
      if(gE[e].target < 0) st = "SHORT";
      if(gE[e].dead) st += " (stood down)";
      t += StringFormat("%s %s  RSI %.1f  -> %s\n", gE[e].sym, gE[e].tag,
                        gE[e].rsi, st);
   }
   Comment(t);
}

void InitEngine(int e, string base, ENUM_TIMEFRAMES tf, int rsiP, long mg,
                double volT, bool en, string tag)
{
   gE[e].sym       = base + InpSymbolSuffix;
   gE[e].tf        = tf;
   gE[e].rsiPeriod = rsiP;
   gE[e].magic     = mg;
   gE[e].volTarget = volT;
   gE[e].enabled   = en;
   gE[e].tag       = tag;
   gE[e].target    = 0;
   gE[e].dead      = false;
   gE[e].lastBar   = 0;
   gE[e].hadPos    = false;
   gE[e].rsi       = 50.0;
   if(en && iTime(gE[e].sym, tf, 0) == 0)
   {
      Print("symbol not found: ", gE[e].sym, " -> disabled (check Symbol Suffix)");
      gE[e].enabled = false;
   }
}

int OnInit()
{
   InitEngine(0, "EURUSD", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeEURUSD, "D1");
   InitEngine(1, "GBPUSD", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeGBPUSD, "D1");
   InitEngine(2, "USDJPY", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeUSDJPY, "D1");
   InitEngine(3, "AUDUSD", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeAUDUSD, "D1");
   InitEngine(4, "AUDUSD", PERIOD_H4, InpRsiPeriod_H4, InpMagicH4,
              InpVolBps_H4 / 10000.0, InpTradeH4AUDUSD, "H4");
   InitEngine(5, "EURGBP", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeEURGBP, "D1");
   InitEngine(6, "GBPJPY", PERIOD_D1, InpRsiPeriod, InpMagicD1,
              InpVolBps_D1 / 10000.0, InpTradeGBPJPY, "D1");

   trade.SetDeviationInPoints(30);
   EventSetTimer(3600);
   Print("GideonEA v3.00 started.");
   RunOnce();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}

void OnTick()  { RunOnce(); }
void OnTimer() { RunOnce(); }
//+------------------------------------------------------------------+
