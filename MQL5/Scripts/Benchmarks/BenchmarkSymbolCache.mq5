//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5 |
//|                                   Copyright 2025, Top Secret     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Top Secret"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Include the performance utility
#include "../../Include/Performance/SymbolCache.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   // Number of iterations for benchmark
   int iterations = 1000000;

   // Variable to hold the results so they are not optimized away
   double dummy_result = 0;

   // 1. Benchmark standard approach (calling SymbolInfoDouble directly)
   ulong start_time = GetMicrosecondCount();

   for(int i = 0; i < iterations; i++)
     {
      double point_val = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      dummy_result += point_val;
     }

   ulong native_time = GetMicrosecondCount() - start_time;

   // 2. Benchmark optimized approach (using CSymbolCache)
   CSymbolCache cache;
   cache.Init(_Symbol);

   start_time = GetMicrosecondCount();

   for(int i = 0; i < iterations; i++)
     {
      double point_val = cache.Point();
      dummy_result += point_val;
     }

   ulong cache_time = GetMicrosecondCount() - start_time;

   // Avoid optimizing dummy result away
   if(dummy_result < 0) Print("Dummy result is negative: ", dummy_result);

   // 3. Output results
   Print("---------------------------------------------------------");
   Print("Benchmark Results: CSymbolCache vs SymbolInfoDouble");
   Print("Iterations: ", iterations);
   Print("Native time (microseconds): ", native_time);
   Print("Cache time (microseconds): ", cache_time);
   Print("---------------------------------------------------------");

   if(cache_time > 0 && native_time > 0)
     {
      double speedup = (double)native_time / cache_time;
      Print("Speedup: ", DoubleToString(speedup, 2), "x faster");

      // Calculate microseconds saved per 1000 calls
      double saved_per_1k = (double)(native_time - cache_time) / (iterations / 1000);
      Print("Microseconds saved per 1,000 calls: ", DoubleToString(saved_per_1k, 2), " us");
     }

   Print("---------------------------------------------------------");
  }
//+------------------------------------------------------------------+
