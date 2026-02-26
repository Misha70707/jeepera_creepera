## 2026-02-26 - MQL5 Symbol Caching Performance
**Learning:** `SymbolInfoInteger(SYMBOL_SPREAD)` is a surprisingly expensive call in MQL5 because it often triggers an internal lookup or recalculation. A manual calculation `(Ask - Bid) / Point` using cached static properties is significantly faster (order of magnitude).
**Action:** Always implement a `CSymbolCache` class for high-frequency trading EAs to cache `Point`, `Digits`, and other static properties in `OnInit`, and update dynamic values like `Spread` manually in `OnTick`.
