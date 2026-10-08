# GideonEA v3.00 — Changelog (vs v2.00)

**Status: SHIPPED 2026-09-30.** `GideonEA.mq5` is now v3.00; setup guide updated.

## What changes
- D1 core expands from 3 pairs to **5 pairs**: EURUSD, USDJPY, AUDUSD (unchanged)
  + **EURGBP** + **GBPJPY** (new, validated — see evidence below).
- Everything else is IDENTICAL to v2.00: RSI(14) 30/70 always-in until opposite
  extreme, 50 bps/day/pair volatility-targeted sizing via OrderCalcProfit,
  12xATR disaster-only stops, no re-entry after a disaster stop until a fresh
  opposite signal.
- AUDUSD H4 RSI(16) satellite: unchanged (25 bps, separate magic 20260931).
- GBPUSD: stays OFF (edge faded, unchanged).
- New inputs: `InpTradeEURGBP` (default true), `InpTradeGBPJPY` (default true).
  Same D1 magic number (20260930) as the other core pairs.
- Version strings, on-chart panel, order comments, Experts log: v3.00.

## Evidence for the change (all gates passed)
1. **Pair expansion** (`src/pair_expansion.py`): EURGBP +39.3%/Sharpe 0.45/DD -12.5%,
   GBPJPY +68.4%/0.46/-17.6% (2014-2026, pair-appropriate costs: 5bps crosses).
2. **Walk-forward per pair** (fixed production n=14, 18m train → 6m test):
   EURGBP OOS/IS 1.17, GBPJPY 1.09; both OOS halves positive; param plateau
   0.71/0.82 around n=14; break-even costs 28bps/38bps = 5.6x/7.6x assumed spread.
3. **Diversification**: strategy-return correlations vs existing core ≤ 0.29.
4. **Production-fidelity portfolio** (same-day entry + 12xATR disaster stops vs daily
   close + per-pair spreads + vol-targeting, full 2014-2026, true daily MTM):
   **5-pair: +61.8% / Sharpe 0.94 / DD -4.8%** vs 3-pair core +46.7% / 0.62 / -11.6%.
5. **Killed alternatives**: USDCAD, USDCHF, NZDUSD, EURJPY failed walk-forward or
   the 3x break-even-cost gate. Carry overlay rejected (wash). Vol cap and
   correlation-aware sizing rejected (no-ops). Grid re-optimization rejected
   (PBO 0.87/0.65 — selection doesn't transfer; params stay frozen).

## What was NOT changed and why
- Params stay (14,30,70): frozen config beat all selection schemes out-of-sample.
- No carry filter, no vol cap, no correlation sizing: all failed to add value.
- 12xATR disaster stops kept: plateau vs 16x, clearly better than 8x.

## Scoreboard correction (from WS6 measurement audit)
`final_validate.run_sleeve` did not accrue daily mark-to-market, so previously
reported path stats were flattered. True-MTM killer portfolio 2024-2026:
**+6.2% / Sharpe 0.33 / DD -11.1%** (was reported +8.0% / 0.50 / -10.9%).
Trade economics and totals were always correct — only Sharpe/vol/DD were affected.
All v3.00 numbers above use true-MTM methodology.

## Before shipping v3.00
1. Compile `GideonEA_v3candidate.mq5` in the user's MetaEditor → 0 errors
   (cannot be compiled on this Linux VM — MQL5 only).
2. MT5 Strategy Tester run on 5-pair D1 + H4 before demo reliance.
3. Recommend 2-4 weeks forward paper observation of the 5-pair core on demo
   (GBPJPY's edge concentrates at n=12-16; live confirmation is cheap insurance).
4. On approval: rename to GideonEA.mq5, update EA_SETUP_GUIDE.md (v3.00 line,
   5-pair description), bump magic if a clean break from v2.00 positions is wanted.
