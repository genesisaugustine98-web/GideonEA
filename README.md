# GideonEA — Self-Contained MT5 Trading Robot

**Author: Genesis Koodanga Augustine**

A self-contained Expert Advisor (EA) for MetaTrader 5 that trades a simple,
evidence-tested idea: when a currency pair's price stretches too far in one
direction in a day, it tends to snap back — so the robot buys the dip and sells
the rally, automatically.

No subscriptions, no cloud services, no API keys. One file, installed on your
own MT5. It runs on a **demo account** — real-money trading is your decision
and your responsibility.

## How it trades (plain words)

- Watches 5 currency pairs on the daily chart (EURUSD, USDJPY, AUDUSD, EURGBP,
  GBPJPY) plus one faster AUDUSD setup on the 4-hour chart.
- Uses the RSI indicator (14 days): below 30 = "oversold, buy"; above 70 =
  "overbought, sell". It stays in a position until the opposite extreme appears.
- Risks a small, fixed slice per trade, sized by each pair's volatility, with a
  wide disaster stop (12× average daily range) in case something extreme happens.
- Once a day. No scalping, no news trading, no guessing.

## The honest numbers

These are **backtest** results (2014–2026, full production simulation with real
spreads, costs, and daily accounting), not promises:

- 5-pair portfolio: **+61.8% total / Sharpe 0.94 / worst dip −4.8%**
- Every change had to pass strict out-of-sample gates before shipping; failed
  ideas (8 challenger strategies, re-optimization, exit tweaks) were rejected
  and documented in the changelog.
- Past performance does not predict future results. Forex is risky.

## Install

1. Open MT5 → File → Open Data Folder → MQL5 → Experts. Copy `GideonEA.mq5`
   there.
2. Open MetaEditor (F4), open the file, press F7 to compile.
3. Drag it onto a daily chart of each of the 5 pairs (and AUDUSD 4-hour for the
   satellite). Full walkthrough with pictures is in [EA_SETUP_GUIDE.md](EA_SETUP_GUIDE.md).

## Files

- `GideonEA.mq5` — the robot (v3.00, the shipped version).
- `EA_SETUP_GUIDE.md` — step-by-step install guide in plain language.
- `CHANGELOG_v3.00.md` — what changed in v3.00 and the evidence behind it.

## License

MIT. Use it, learn from it, share it. If it loses money, that's on the market,
not on me.
