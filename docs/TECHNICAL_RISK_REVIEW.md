# GideonEA technical risk review

Review date: 8 November 2026. Source reviewed: GideonEA.mq5 v3.00.

This is a source-level engineering review, not investment advice, a strategy endorsement or proof of profitability.

## Signal calculations

- CalcRSI averages positive and negative close-to-close changes over the period. It is not the conventional Wilder-smoothed RSI calculation. It may be a valid custom oscillator, but should be named and documented distinctly.
- CalcATR averages absolute close-to-close changes. It does not use the high/low true-range formula and does not incorporate intrabar ranges or gaps in the standard ATR manner.
- The README has been corrected to describe the implemented calculations instead of implying conventional RSI/ATR.

## Risk sizing

CalcVolumeVolTarget sizes a position so that an approximate one-volatility-unit move represents the configured fraction of equity. The stop distance is set at InpDisasterAtr (default 12) times that same volatility estimate.

Under a simplified linear price-move assumption, a 12-unit stop can therefore represent roughly 12 times the one-unit target before costs, slippage, gaps, conversion effects and execution differences. For example, a 50 bps one-unit target is not a 50 bps maximum-loss limit; the 12-unit distance can imply approximately 6% of equity at the stop for that position. This is an approximation, not a guaranteed realised loss.

The code does not establish a portfolio-level risk ceiling across all active symbols/engines. Correlated positions can compound exposure.

## Execution and broker compatibility

- The CTrade boolean is not by itself proof that an order was filled at the broker. The EA should inspect ResultRetcode(), deal/order identifiers and the resulting position state before setting hadPos as if a fill occurred.
- Volume is rounded to two decimal places after step sizing. Broker volume precision should be derived from the broker's volume step and verified against min/max/step constraints.
- Stop placement, symbol suffixes, contract size, tick value, currency conversion, filling mode, deviation and server-side stop handling must be verified per broker and symbol.
- Close operations also need reconciliation against broker result codes and actual remaining positions.

## Safe next engineering gates

1. Add a testable calculation layer or MQL5 test harness for signal, sizing and volume-step logic.
2. Compare the custom oscillator with the intended strategy definition and label it explicitly.
3. Decide the intended stop-loss budget and derive volume from the full stop distance, not only a one-unit move.
4. Add an aggregate portfolio risk and correlated-exposure limit.
5. Reconcile every trade request against broker retcodes and actual account positions.
6. Run forward tests on a demo account across broker symbols and contract specifications.
7. Independently reproduce the historical test with raw data, costs, exact parameters and a clean holdout.

No source-level documentation change can certify the trading strategy or make the current volume formula safe for live capital.