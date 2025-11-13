//+------------------------------------------------------------------+
//|                                    Professional SAR Scalper v2.0 |
//|                         Advanced Parabolic SAR Trading System    |
//+------------------------------------------------------------------+
#property copyright "Professional SAR Scalper v2.0"
#property link      ""
#property version   "2.00"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Time Settings ==="
input ENUM_TIMEFRAMES Timeframe = PERIOD_M5;     // Chart timeframe
input bool EnableTimeFilter = true;              // Enable time filter
input int StartHour = 7;                         // Trading start hour
input int EndHour = 21;                          // Trading end hour

input group "=== Day Filter ==="
input bool EnableDayFilter = false;              // Enable day filter
input bool TradeMonday = true;                   // Trade Monday
input bool TradeTuesday = true;                  // Trade Tuesday
input bool TradeWednesday = true;                // Trade Wednesday
input bool TradeThursday = true;                 // Trade Thursday
input bool TradeFriday = true;                   // Trade Friday

input group "=== Lot Size Management ==="
input double FixedLots = 0.01;                   // Fixed lot size
input double RiskPercent = 1.0;                  // Risk percentage

input group "=== SAR Strategy Settings ==="
input double SARStep = 0.02;                     // SAR step
input double SARMaximum = 0.2;                   // SAR maximum
input int SARBuffer = 25;                        // SAR buffer (points)
input int MinimumLapse = 9;                      // Minimum time lapse (seconds)
input int PriceThreshold = 70;                   // Price movement threshold (points)
input int StopActivation = 60;                   // Stop activation (points)
input int StopBuffer = 25;                       // Stop buffer (points)

input group "=== Advanced Settings ==="
input int MaxPositions = 1;                      // Maximum concurrent positions
input double MinimumProfit = 33;                 // Minimum profit to close all
input int MagicNumber = 123456;                  // Magic number
input bool EnableLogging = true;                 // Enable detailed logging

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int sar_handle;
datetime buy_order_time = 0;
datetime sell_order_time = 0;

// Simplified price tracking
struct PricePoint
{
   double price;
   datetime time;
};
PricePoint price_history[];
int history_size = 100;

CTrade trade;
COrderInfo order_info;
CPositionInfo position_info;

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   if(EnableLogging) Print("Initializing Professional SAR Scalper v2.0");

   trade.SetExpertMagicNumber(MagicNumber);
   ChartSetInteger(0, CHART_SHOW_GRID, false);

   sar_handle = iSAR(_Symbol, Timeframe, SARStep, SARMaximum);
   if(sar_handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create SAR indicator");
      return INIT_FAILED;
   }

   if(!ValidateInputs())
   {
      Print("ERROR: Invalid input parameters");
      return INIT_PARAMETERS_INCORRECT;
   }

   ArrayResize(price_history, history_size);
   ArrayInitialize(price_history, 0);

   if(EnableLogging) Print("Initialization successful");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(sar_handle);
   if(EnableLogging) Print("EA shutdown complete");
}

//+------------------------------------------------------------------+
//| Main Tick Handler                                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsTradingAllowed()) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   UpdatePriceHistory(bid);

   ManagePendingOrders();
   ManagePositions();

   int total_count = CountOurOrders();
   if(total_count >= MaxPositions) return;

   double price_movement = GetPriceMovement();

   if(MathAbs(price_movement / _Point) > StopActivation)
   {
      PlaceNewOrders(ask, bid, price_movement);
   }
}

//+------------------------------------------------------------------+
//| Input Validation                                                  |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   if(EnableTimeFilter)
   {
      if(StartHour < 0 || StartHour > 23 || EndHour < 0 || EndHour > 23)
      {
         Print("WARNING: Invalid hours (0-23). Time filter disabled.");
         EnableTimeFilter = false;
         return true;
      }

      if(StartHour == EndHour)
      {
         Print("WARNING: Start equals end hour. Time filter disabled.");
         EnableTimeFilter = false;
      }
   }

   if(FixedLots < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("WARNING: Lot size below minimum");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Trading Time Check                                                |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   if(EnableTimeFilter)
   {
      MqlDateTime time_struct;
      TimeToStruct(TimeCurrent(), time_struct);
      int current_hour = time_struct.hour;

      if(StartHour < EndHour)
      {
         if(current_hour < StartHour || current_hour >= EndHour)
            return false;
      }
      else
      {
         if(current_hour < StartHour && current_hour >= EndHour)
            return false;
      }
   }

   if(EnableDayFilter)
   {
      MqlDateTime time_struct;
      TimeToStruct(TimeCurrent(), time_struct);

      switch(time_struct.day_of_week)
      {
         case 1: return TradeMonday;
         case 2: return TradeTuesday;
         case 3: return TradeWednesday;
         case 4: return TradeThursday;
         case 5: return TradeFriday;
         case 6: return false; // Saturday
         case 0: return false; // Sunday
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Simplified Price History Update                                  |
//+------------------------------------------------------------------+
void UpdatePriceHistory(double current_price)
{
   // Shift array
   for(int i = history_size - 1; i > 0; i--)
   {
      price_history[i] = price_history[i-1];
   }

   // Add new data
   price_history[0].price = current_price;
   price_history[0].time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Get Price Movement                                                |
//+------------------------------------------------------------------+
double GetPriceMovement()
{
   if(ArraySize(price_history) < MinimumLapse) return 0;

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   datetime current_time = TimeCurrent();

   for(int i = 0; i < ArraySize(price_history); i++)
   {
      if(current_time - price_history[i].time >= MinimumLapse)
      {
         double movement = current_price - price_history[i].price;

         // Sanity check
         if(MathAbs(movement / _Point) > 10000)
            return 0;

         return movement;
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Manage Pending Orders                                             |
//+------------------------------------------------------------------+
void ManagePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!order_info.SelectByIndex(i)) continue;
      if(order_info.Symbol() != _Symbol || order_info.Magic() != MagicNumber) continue;

      datetime current_time = TimeCurrent();
      double movement = GetPriceMovement();

      if(order_info.Type() == ORDER_TYPE_BUY_STOP)
      {
         long time_diff = current_time - buy_order_time;

         if(time_diff > MinimumLapse && movement < PriceThreshold)
         {
            trade.OrderDelete(order_info.Ticket());
            if(EnableLogging) Print("Buy stop order deleted due to insufficient momentum");
         }
      }
      else if(order_info.Type() == ORDER_TYPE_SELL_STOP)
      {
         long time_diff = current_time - sell_order_time;

         if(time_diff > MinimumLapse && movement > -PriceThreshold)
         {
            trade.OrderDelete(order_info.Ticket());
            if(EnableLogging) Print("Sell stop order deleted due to insufficient momentum");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Positions with Trailing Stop                              |
//+------------------------------------------------------------------+
void ManagePositions()
{
   double total_profit = 0;
   int position_count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!position_info.SelectByIndex(i)) continue;
      if(position_info.Symbol() != _Symbol || position_info.Magic() != MagicNumber) continue;

      position_count++;
      total_profit += position_info.Profit();

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double open_price = position_info.PriceOpen();
      double current_sl = position_info.StopLoss();
      double movement = GetPriceMovement();

      // Buy position management
      if(position_info.PositionType() == POSITION_TYPE_BUY)
      {
         if(movement < -PriceThreshold && bid < (open_price - StopActivation * _Point))
         {
            if(current_sl == 0)
            {
               double new_sl = NormalizeDouble(bid - StopBuffer * _Point, _Digits);
               if(trade.PositionModify(position_info.Ticket(), new_sl, position_info.TakeProfit()))
               {
                  if(EnableLogging) Print("Trailing stop activated for BUY position");
               }
            }
         }
      }
      // Sell position management
      else if(position_info.PositionType() == POSITION_TYPE_SELL)
      {
         if(ask > (open_price + StopActivation * _Point))
         {
            if(current_sl == 0)
            {
               double new_sl = NormalizeDouble(ask + StopBuffer * _Point, _Digits);
               if(trade.PositionModify(position_info.Ticket(), new_sl, position_info.TakeProfit()))
               {
                  if(EnableLogging) Print("Trailing stop activated for SELL position");
               }
            }
         }
      }
   }

   // Close all if profit target reached
   if(total_profit > MinimumProfit && position_count > 0)
   {
      if(EnableLogging) Print("Profit target reached: $", DoubleToString(total_profit, 2), " - closing all positions");

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!position_info.SelectByIndex(i)) continue;
         if(position_info.Symbol() == _Symbol && position_info.Magic() == MagicNumber)
         {
            trade.PositionClose(position_info.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Place New Orders                                                  |
//+------------------------------------------------------------------+
void PlaceNewOrders(double ask, double bid, double movement)
{
   double sar_array[1];
   if(CopyBuffer(sar_handle, 0, 0, 1, sar_array) <= 0) return;

   double sar_value = sar_array[0];

   // Get highest/lowest open prices
   double highest_open = 0;
   double lowest_open = DBL_MAX;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(position_info.SelectByIndex(i))
      {
         if(position_info.Symbol() == _Symbol && position_info.Magic() == MagicNumber)
         {
            double open_price = position_info.PriceOpen();
            if(open_price > highest_open) highest_open = open_price;
            if(open_price < lowest_open) lowest_open = open_price;
         }
      }
   }

   // Buy stop condition
   if(movement > StopActivation)
   {
      double sar_level = sar_value - SARBuffer * _Point;

      if(sar_level > ask && (lowest_open == DBL_MAX || sar_level < lowest_open))
      {
         double entry = NormalizeDouble(ask + SARBuffer * _Point, _Digits);

         if(trade.BuyStop(FixedLots, entry, _Symbol, 0, 0, 0, "SAR Buy"))
         {
            buy_order_time = TimeCurrent();
            if(EnableLogging) Print("BUY STOP placed at ", DoubleToString(entry, _Digits));
         }
      }
   }
   // Sell stop condition
   else if(movement < -StopActivation)
   {
      double sar_level = sar_value + SARBuffer * _Point;

      if((highest_open == 0 || bid - sar_level < highest_open) && sar_level < bid)
      {
         double entry = NormalizeDouble(bid - SARBuffer * _Point, _Digits);

         if(trade.SellStop(FixedLots, entry, _Symbol, 0, 0, 0, "SAR Sell"))
         {
            sell_order_time = TimeCurrent();
            if(EnableLogging) Print("SELL STOP placed at ", DoubleToString(entry, _Digits));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Count Our Orders and Positions                                    |
//+------------------------------------------------------------------+
int CountOurOrders()
{
   int count = 0;

   // Count pending orders
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(order_info.SelectByIndex(i))
      {
         if(order_info.Symbol() == _Symbol && order_info.Magic() == MagicNumber)
            count++;
      }
   }

   // Count positions
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(position_info.SelectByIndex(i))
      {
         if(position_info.Symbol() == _Symbol && position_info.Magic() == MagicNumber)
            count++;
      }
   }

   return count;
}
