//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5  |
//|                                     Copyright 2024, Bolt Agency. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Bolt Agency."
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
   CSymbolCache symbolCache;
   if(!symbolCache.Init(_Symbol))
     {
      Print("Failed to initialize SymbolCache");
      return;
     }

   // Prepare dummy tick
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
     {
      Print("Failed to get current tick");
      return;
     }
   symbolCache.Update(tick);

   Print("Starting benchmark with ", InpIterations, " iterations...");

   // --- Benchmark 1: Direct API calls ---
   ulong start1 = GetMicrosecondCount();
   double sum1 = 0.0;

   for(int i=0; i<InpIterations; i++)
     {
      // Mimic typical usage: getting Ask, Bid, Point
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      sum1 += ask + bid + point;
     }

   ulong time1 = GetMicrosecondCount() - start1;
   Print("Direct API calls time: ", time1, " us");

   // --- Benchmark 2: CSymbolCache ---
   ulong start2 = GetMicrosecondCount();
   double sum2 = 0.0;

   for(int i=0; i<InpIterations; i++)
     {
      // Mimic typical usage: getting Ask, Bid, Point from cache
      double ask = symbolCache.Ask();
      double bid = symbolCache.Bid();
      double point = symbolCache.Point();

      sum2 += ask + bid + point;
     }

   ulong time2 = GetMicrosecondCount() - start2;
   Print("CSymbolCache time: ", time2, " us");

   // --- Results ---
   if(time2 > 0)
     {
      double speedup = (double)time1 / (double)time2;
      PrintFormat("Speedup: %.2fx faster", speedup);
     }
   else
     {
      Print("CSymbolCache was too fast to measure!");
     }

   // Prevent compiler optimization of loops
   if(sum1 != sum2)
      Print("Warning: Sums differ! ", sum1, " != ", sum2);
  }
//+------------------------------------------------------------------+
