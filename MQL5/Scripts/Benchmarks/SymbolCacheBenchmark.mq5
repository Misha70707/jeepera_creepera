//+------------------------------------------------------------------+
//|                                       SymbolCacheBenchmark.mq5   |
//|                                  tweny_fo_seven_trees_ixty_five  |
//|                                            Apache License 2.0    |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      "https://github.com/tweny_fo_seven_trees_ixty_five"
#property version   "1.00"
#property script_show_inputs

#include "../../Include/Performance/SymbolCache.mqh"

input int iterations = 1000000;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Print("--- Starting Symbol Cache Benchmark ---");

   string symbol = Symbol();
   CSymbolCache cache;
   if(!cache.Init(symbol))
     {
      Print("Failed to initialize cache.");
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(symbol, tick))
     {
      Print("Failed to get tick.");
      return;
     }

   // 1. Benchmark standard MT5 API calls
   ulong start_time_api = GetMicrosecondCount();
   double sum_ask_api = 0;

   for(int i=0; i<iterations; i++)
     {
      // Native API calls in loop
      sum_ask_api += SymbolInfoDouble(symbol, SYMBOL_ASK);
     }

   ulong end_time_api = GetMicrosecondCount();
   ulong duration_api = end_time_api - start_time_api;

   // 2. Benchmark CSymbolCache
   ulong start_time_cache = GetMicrosecondCount();
   double sum_ask_cache = 0;

   for(int i=0; i<iterations; i++)
     {
      // In a real OnTick, this would be updated once per event
      cache.Update(tick);
      sum_ask_cache += cache.Ask();
     }

   ulong end_time_cache = GetMicrosecondCount();
   ulong duration_cache = end_time_cache - start_time_cache;

   PrintFormat("Standard API calls duration: %llu microseconds", duration_api);
   PrintFormat("CSymbolCache duration: %llu microseconds", duration_cache);
   PrintFormat("Performance gain: %.2fx faster", (double)duration_api / MathMax((double)duration_cache, 1.0));
  }
//+------------------------------------------------------------------+
