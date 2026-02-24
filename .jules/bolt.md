# Bolt's Journal

## 2025-11-15 - [MQL5 API Overhead]
**Learning:** Native MQL5 API calls like `SymbolInfoInteger(SYMBOL_SPREAD)` and `SymbolInfoDouble(SYMBOL_ASK)` have significant overhead when called repeatedly in `OnTick` loops. This overhead comes from the terminal-to-EA context switch or internal lookup mechanisms.
**Action:** Use a `CSymbolCache` class to cache static symbol properties (`Point`, `Digits`) in `OnInit` and update dynamic properties (`Ask`, `Bid`, `Spread`) manually from `MqlTick` in `OnTick`. This pattern significantly reduces API calls and improves EA execution speed.
