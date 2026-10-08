# GideonEA — Setup Guide

**What this is:** a small robot that lives inside your HFM MT5 and trades the
RSI system for you, automatically. It checks the market once a day, opens
trades when the signal fires, and every trade carries a disaster stop-loss
that sits on HFM's server (so you're protected even if your laptop is off).

**What it trades:** EURUSD, USDJPY, AUDUSD, EURGBP, GBPJPY on the daily chart,
plus a smaller AUDUSD position on the 4-hour chart (a second, independent
engine that passed separate testing).
GBPUSD is switched OFF by default — its edge faded in recent years. You can
switch it on later in the settings if you want.

**Money at risk:** none real — this is your demo account. The robot sizes
every trade so that a normal day's wiggle moves it by about 0.5% of the demo
equity per pair (0.25% for the 4-hour engine). The stop-loss is very wide on
purpose — it only exists for true disasters (flash crashes), not for normal
market noise. Testing showed a tight stop actually *destroys* this system by
chopping up winning trades, so v2.00 removed it.

---

## Step 1 — Install HFM MT5 on your computer

1. Go to the HFM website and download **HFM MT5 for Windows** (or Mac).
2. Install it and open it.
3. Click **File → Login to Trade Account**.
4. Enter login **49852679**, your password, and server **HFMarketsGlobal-Demo**.
5. You should see your demo balance at the bottom. 

## Step 2 — Put the robot into MT5

1. In MT5, press **F4** on your keyboard. This opens the MetaEditor (the
   robot workshop).
2. In MetaEditor, click **File → New → Expert Advisor → Next**.
3. Name it `GideonEA`, click Next → Next → Finish.
4. A file with some template code opens. **Select everything (Ctrl+A),
   delete it, and paste in the entire contents of `GideonEA.mq5`** (the file
   Gideon gave you).
5. Press **F7** to compile. At the bottom you should see **"0 errors"**.
   If you see errors, tell Gideon exactly what they say.
6. Close MetaEditor and go back to MT5.

## Step 3 — Attach the robot to a chart

1. Open a **EURUSD, Daily** chart (right-click EURUSD in Market Watch →
   Chart Window, then set the timeframe to D1).
2. In the **Navigator** panel on the left, open **Expert Advisors** — you
   should see **GideonEA**. Drag it onto the chart.
3. A settings window pops up:
   - **Common** tab → tick **"Allow Algo Trading"** → OK.
   - **Inputs** tab → leave everything as it is (GBPUSD is off on purpose).
4. Press the **"Algo Trading"** button in the top toolbar — it must turn
   **green**.
5. You should see a little panel at the top-left of the chart showing each
   pair and its status. A small hat/smile icon also appears at the top-right
   of the chart.

## Step 4 — Check it's alive

1. At the bottom of MT5, open the **Experts** tab.
2. You should see a line like: `GideonEA v3.00 started.`
3. If you see that, you're done. The robot now checks once a day and trades
   when the signal fires.

---

## Everyday use

- **Leave the laptop on** (or at least open MT5 once a day). The robot only
  needs a few minutes around the end of the trading day to check signals.
- **Stop-losses are on HFM's server**, so even if the laptop sleeps, your
  protection is active.
- **To pause the robot:** press the Algo Trading button (turns red), or
  right-click the chart → Expert List → remove GideonEA.
- **The robot never touches trades you place by hand** — it only manages
  trades it opened itself.

## If something looks wrong

- **"0 errors" didn't appear in Step 2:** copy the exact error text to Gideon.
- **Trades appear that you don't understand:** check the Experts tab — the
  robot logs every action with its reason (e.g. `EURUSD: BUY 0.06 lots ...
  (RSI=28.4)`).
- **No trades for days:** normal. This system only trades ~6 times a year
  per pair. Patience is part of the design.
