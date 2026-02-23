//+------------------------------------------------------------------+
//|                                              BenchmarkSpread.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <Performance/SymbolCache.mqh>

input int InpIterations = 1000000; // Number of iterations

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   CSymbolCache cache;
   if(!cache.Init(_Symbol))
     {
      Print("Failed to initialize cache");
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
     {
      Print("Failed to get tick");
      return;
     }

   cache.Update(tick);

   // Benchmark Standard Method
   ulong start = GetMicrosecondCount();
   long sum = 0;
   for(int i=0; i<InpIterations; i++)
     {
      sum += SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
     }
   ulong timeStandard = GetMicrosecondCount() - start;

   // Benchmark Optimized Method
   start = GetMicrosecondCount();
   long sumOpt = 0;
   for(int i=0; i<InpIterations; i++)
     {
      sumOpt += cache.GetSpread();
     }
   ulong timeOptimized = GetMicrosecondCount() - start;

   PrintFormat("Iterations: %d", InpIterations);
   PrintFormat("Standard Time: %llu microsec", timeStandard);
   PrintFormat("Optimized Time: %llu microsec", timeOptimized);

   if(timeOptimized > 0 && timeStandard > 0)
      PrintFormat("Improvement: %.2fx faster", (double)timeStandard/(double)timeOptimized);

   // Verify correctness
   long standardSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   long optimizedSpread = cache.GetSpread();

   PrintFormat("Standard Spread: %d, Optimized Spread: %d", standardSpread, optimizedSpread);
  }
//+------------------------------------------------------------------+
