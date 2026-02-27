//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5 |
//|                                                             Bolt |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Bolt"
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
   Print("⚡ Bolt: Starting CSymbolCache Benchmark...");
   Print("Iterations: ", InpIterations);

   CSymbolCache symbolCache;
   if(!symbolCache.Init(_Symbol))
     {
      Print("Failed to initialize CSymbolCache");
      return;
     }

   // Need a tick to update cache
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
     {
      Print("Failed to get current tick");
      return;
     }
   symbolCache.Update(tick);

   // --- Benchmark 1: Standard API Calls ---
   ulong start1 = GetMicrosecondCount();
   double sum1 = 0.0;

   for(int i=0; i<InpIterations; i++)
     {
      // Simulate typical symbol property access in a strategy
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      // Do something with values to prevent compiler optimization
      sum1 += (ask - bid) / point;
     }

   ulong time1 = GetMicrosecondCount() - start1;

   // --- Benchmark 2: CSymbolCache ---
   ulong start2 = GetMicrosecondCount();
   double sum2 = 0.0;

   for(int i=0; i<InpIterations; i++)
     {
      // Fast cached access
      double ask = symbolCache.Ask();
      double bid = symbolCache.Bid();
      double point = symbolCache.Point();

      sum2 += (ask - bid) / point;
     }

   ulong time2 = GetMicrosecondCount() - start2;

   // --- Results ---
   PrintFormat("Standard API Time: %I64u microseconds", time1);
   PrintFormat("CSymbolCache Time: %I64u microseconds", time2);

   if(time2 > 0)
     {
      double speedup = (double)time1 / (double)time2;
      PrintFormat("⚡ Speedup: %.2fx faster", speedup);
     }

   Print("Benchmark Complete.");
  }
//+------------------------------------------------------------------+
