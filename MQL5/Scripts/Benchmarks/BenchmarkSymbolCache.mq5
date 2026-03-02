//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5  |
//|                                   tweny_fo_seven_trees_ixty_five |
//|                                        Apache License 2.0        |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      ""
#property version   "1.00"
#property script_show_inputs

#include "../../Include/Performance/SymbolCache.mqh"

input int InpIterations = 10000000; // Benchmark Iterations

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("Starting Benchmark: Native SymbolInfoDouble vs CSymbolCache");
   Print("Iterations: ", InpIterations);

   // Initialize Cache
   CSymbolCache cache;
   if(!cache.Init(_Symbol))
     {
      Print("Failed to initialize cache.");
      return;
     }

   // Prepare mock tick data for update
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   cache.Update(tick);

   // 1. Benchmark Native SymbolInfoDouble
   ulong start_native = GetMicrosecondCount();
   double native_sum = 0;

   for(int i = 0; i < InpIterations; i++)
     {
      native_sum += SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      native_sum += SymbolInfoDouble(_Symbol, SYMBOL_BID);
     }

   ulong time_native = GetMicrosecondCount() - start_native;
   PrintFormat("Native SymbolInfoDouble time: %llu microseconds", time_native);

   // 2. Benchmark CSymbolCache
   ulong start_cache = GetMicrosecondCount();
   double cache_sum = 0;

   for(int i = 0; i < InpIterations; i++)
     {
      // In a real EA, Update(tick) is called once per OnTick
      // and Ask()/Bid() are accessed many times.
      cache_sum += cache.Ask();
      cache_sum += cache.Bid();
     }

   ulong time_cache = GetMicrosecondCount() - start_cache;
   PrintFormat("CSymbolCache time: %llu microseconds", time_cache);

   // Calculate Improvement
   if(time_cache > 0)
     {
      double speedup = (double)time_native / time_cache;
      PrintFormat("Performance Gain: %.2fx faster with CSymbolCache", speedup);
     }

   // Prevent compiler optimization from removing the loops
   if(native_sum == 0.0 || cache_sum == 0.0)
     {
        Print("Sum zero.");
     }

   Print("Benchmark Complete.");
  }
