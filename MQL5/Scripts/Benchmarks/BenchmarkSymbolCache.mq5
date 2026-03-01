//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5  |
//|                                   tweny_fo_seven_trees_ixty_five |
//|                                             Apache License 2.0   |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      "https://github.com/tweny_fo_seven_trees_ixty_five"
#property version   "1.00"
#property script_show_inputs

#include "../../Include/Performance/SymbolCache.mqh"

input int InpIterations = 10000000; // Number of iterations for benchmark

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("Starting Benchmark: Native SymbolInfoDouble vs CSymbolCache");
   Print("Iterations: ", InpIterations);

   // 1. Native Approach
   uint startTimeNative = GetTickCount();
   double nativeAsk = 0.0;
   double nativeBid = 0.0;

   for(int i = 0; i < InpIterations; i++)
     {
      nativeAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      nativeBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
     }

   uint timeNative = GetTickCount() - startTimeNative;
   Print("Native SymbolInfoDouble Time: ", timeNative, " ms");

   // 2. Cache Approach
   CSymbolCache cache;
   cache.Init(_Symbol);

   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   cache.Update(tick);

   uint startTimeCache = GetTickCount();
   double cacheAsk = 0.0;
   double cacheBid = 0.0;

   for(int i = 0; i < InpIterations; i++)
     {
      // In a real EA, this tick update happens once per OnTick, not in the loop
      // But we simulate the access speed here
      cacheAsk = cache.Ask();
      cacheBid = cache.Bid();
     }

   uint timeCache = GetTickCount() - startTimeCache;
   Print("CSymbolCache Access Time: ", timeCache, " ms");

   // Summary
   if(timeCache < timeNative && timeCache > 0)
     {
      double speedup = (double)timeNative / timeCache;
      Print("Result: CSymbolCache is ~", DoubleToString(speedup, 1), "x faster than native calls in tight loops/OnTick!");
     }
   else if (timeCache == 0)
     {
      Print("Result: CSymbolCache time was < 1ms, too fast to measure speedup accurately.");
     }
  }
//+------------------------------------------------------------------+
