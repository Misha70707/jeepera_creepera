//+------------------------------------------------------------------+
//|                                        BenchmarkSymbolCache.mq5 |
//|                                  Copyright 2025, Bolt Performance|
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Bolt Performance"
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
      Print("Failed to get current tick");
      return;
     }

   // Pre-warm the cache
   cache.Update(tick);

   // Benchmark 1: Standard MQL5 calls (SymbolInfoInteger)
   ulong start1 = GetMicrosecondCount();
   double spread1 = 0;
   for(int i=0; i<InpIterations; i++)
     {
      // Simulate real-world usage where we call API
      spread1 += (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
     }
   ulong time1 = GetMicrosecondCount() - start1;

   // Benchmark 2: Cached access (Manual calculation)
   ulong start2 = GetMicrosecondCount();
   double spread2 = 0;
   for(int i=0; i<InpIterations; i++)
     {
      // Simulate access to cached property
      // In a real EA, Update() is called once per tick, and Spread() is called multiple times per tick.
      // This measures the read access speed.
      spread2 += cache.Spread();
     }
   ulong time2 = GetMicrosecondCount() - start2;

   PrintFormat("Benchmark Results (%d iterations):", InpIterations);
   PrintFormat("Standard SymbolInfoInteger: %llu microsec", time1);
   PrintFormat("Cached Access: %llu microsec", time2);

   if(time1 > 0)
      PrintFormat("Improvement: %.2f%%", (double)(time1 - time2) / time1 * 100.0);
   else
      Print("Improvement: Infinite (Standard took 0us?)");

   // Also benchmark point access
   ulong start3 = GetMicrosecondCount();
   double point1 = 0;
   for(int i=0; i<InpIterations; i++)
     {
      point1 += SymbolInfoDouble(_Symbol, SYMBOL_POINT);
     }
   ulong time3 = GetMicrosecondCount() - start3;

   ulong start4 = GetMicrosecondCount();
   double point2 = 0;
   for(int i=0; i<InpIterations; i++)
     {
      point2 += cache.Point();
     }
   ulong time4 = GetMicrosecondCount() - start4;

   PrintFormat("Standard SymbolInfoDouble(POINT): %llu microsec", time3);
   PrintFormat("Cached Point(): %llu microsec", time4);

   if(time3 > 0)
      PrintFormat("Improvement (Point): %.2f%%", (double)(time3 - time4) / time3 * 100.0);
  }
//+------------------------------------------------------------------+
