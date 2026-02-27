## 2025-11-14 - [Caching Symbol Info]
**Learning:** `SymbolInfoDouble` has significant overhead when called repeatedly in tight loops or high-frequency `OnTick` events. Caching static data (like `Point`, `Digits`) and updating dynamic data (like `Ask`, `Bid`) via `MqlTick` significantly reduces latency.
**Action:** Use `CSymbolCache` for all frequent symbol property accesses to minimize API calls and improve execution speed.
