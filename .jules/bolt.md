## 2024-05-22 - [Dynamic Tick Value Caching Risk]
**Learning:** Caching `SYMBOL_TRADE_TICK_VALUE` in `OnInit` is an anti-pattern for cross-currency pairs because the conversion rate changes dynamically. While safe for short backtests, it can lead to inaccurate position sizing in long-running EAs.
**Action:** Always fetch `TickValue` fresh or update it periodically in `OnTick` for cross-currency pairs. Removed it from `CSymbolCache` to ensure correctness over micro-optimization.
