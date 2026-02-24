//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <Performance/SymbolCache.mqh>

input int InpIterations = 1000000; // Number of iterations for benchmark

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("Starting benchmark with ", InpIterations, " iterations...");

   // Get a tick for simulation
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
     {
      Print("Error getting tick!");
      return;
     }

   // --- Benchmark Native Calls ---
   ulong start_native = GetMicrosecondCount();

   double native_sum = 0;
   for(int i = 0; i < InpIterations; i++)
     {
      // Simulate getting ask, bid, spread
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

      // Use values to prevent optimization
      native_sum += ask + bid + spread;
     }

   ulong time_native = GetMicrosecondCount() - start_native;
   Print("Native API time: ", time_native, " us");


   // --- Benchmark CSymbolCache ---
   CSymbolCache cache;
   if(!cache.Init(_Symbol))
     {
      Print("Error initializing cache!");
      return;
     }

   ulong start_cache = GetMicrosecondCount();

   double cache_sum = 0;
   for(int i = 0; i < InpIterations; i++)
     {
      // Update cache (simulating tick update)
      cache.Update(tick);

      // Access values
      double ask = cache.Ask();
      double bid = cache.Bid();
      int spread = cache.Spread();

      // Use values
      cache_sum += ask + bid + spread;
     }

   ulong time_cache = GetMicrosecondCount() - start_cache;
   Print("CSymbolCache time: ", time_cache, " us");

   // --- Results ---
   if(time_cache > 0)
     {
      double speedup = (double)time_native / time_cache;
      PrintFormat("Speedup: %.2fx", speedup);
     }
  }
//+------------------------------------------------------------------+
