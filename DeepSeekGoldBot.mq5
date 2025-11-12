//+------------------------------------------------------------------+
//|                                           DeepSeekGoldBot.mq5    |
//|                                    Built from DeepSeek Conversation |
//|                                               Mr. CapFree        |
//+------------------------------------------------------------------+
#property copyright "Mr. CapFree"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

// Enums for user selections
enum ENUM_RESTRICTION_REASON
{
   NO_RESTRICTION,
   TIME_RESTRICTION,
   DAY_RESTRICTION,
   TIME_DAY_RESTRICTION,
   TIME_NEWS_RESTRICTION,
   DAY_NEWS_RESTRICTION,
   ALL_RESTRICTIONS
};

enum ENUM_TIME_SELECTION
{
   GMT_TIME,
   BROKER_TIME
};

enum ENUM_NEWS_SEPARATOR
{
   COMMA,
   SEMICOLON
};

enum ENUM_LOT_SIZE_MODE
{
   FIXED_LOTS,
   ACCOUNT_BALANCE_PERCENT,
   EQUITY_PERCENT,
   FREE_MARGIN_PERCENT,
   FIXED_RISK_AMOUNT
};

// Global variables
ENUM_RESTRICTION_REASON last_restriction_reason = NO_RESTRICTION;

// Time Settings
input group "=== Time Settings ==="
input ENUM_TIMEFRAMES timeframe = PERIOD_M5;
input bool trading_time = true;
input ENUM_TIME_SELECTION time_selection = BROKER_TIME;
input int start_hour = 7;
input int end_hour = 21;

bool enable_trading_time = trading_time;

// Lot Size Management
input group "=== Lot Size Management ==="
input ENUM_LOT_SIZE_MODE lot_size_mode = FIXED_LOTS;
input double risk_percentage = 1.0;
input double fixed_risk_amount = 100.0;
input double fixed_lots = 0.01;

// SAR Settings
input group "=== SAR Settings ==="
input double sar_period = 0.02;
input int sar_buffer = 25; // points
input int minimum_time_lapse = 9; // seconds
input int price_movement_threshold = 70; // points
input int stop_activation_point = 60; // points
input int stop_activation_buffer = 25; // points
input int magic_number = 123456;

double total_stop_loss = (stop_activation_point + stop_activation_buffer) * 2;

// News Filter Settings
input group "=== News Filter ==="
input bool enable_news_filter = false;
input string news_currencies = "USD,EUR,GBP,JPY,CHF,CAD,AUD,NZD";
input ENUM_NEWS_SEPARATOR news_separator = COMMA;
input int news_minutes_before = 30;
input int news_minutes_after = 30;
input string high_impact_news = "NFP,FOMC,CPI,PPI,GDP,PMI";

// Day Trading Settings
input group "=== Day Trading ==="
input bool enable_day_filter = false;
input bool trade_monday = true;
input bool trade_tuesday = true;
input bool trade_wednesday = true;
input bool trade_thursday = true;
input bool trade_friday = true;
input bool trade_saturday = false;
input bool trade_sunday = false;

// Global runtime variables
double current_spread = 0;
double average_spread = 0;
double minimum_profit_lock = 33;
int spread_array_size = 100;
int max_concurrent_orders = 1;
int max_slippage = 3;

double spread_history_array[];
double price_history_array[];
datetime time_history_array[];

int sar_handle;
datetime buy_order_time = 0;
datetime sell_order_time = 0;

CTrade trade;
COrderInfo order_info;
CPositionInfo position_info;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set trade parameters
   trade.SetExpertMagicNumber(magic_number);

   // Remove grid from chart
   ChartSetInteger(0, CHART_SHOW_GRID, false);

   // Create SAR handle
   sar_handle = iSAR(_Symbol, timeframe, sar_period, 0.2);
   if(sar_handle == INVALID_HANDLE)
   {
      Print("Failed to create SAR indicator");
      return INIT_FAILED;
   }

   // Validate time settings
   if(enable_trading_time)
   {
      if(start_hour < 0 || start_hour > 23 || end_hour < 0 || end_hour > 23)
      {
         Alert("Invalid hours! Must be between 0 and 23. Trading time disabled.");
         enable_trading_time = false;
      }

      if(start_hour == end_hour)
      {
         Alert("Start hour equals end hour! Trading time disabled.");
         enable_trading_time = false;
      }
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(sar_handle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if trading is allowed (FIXED: Added this check)
   if(!IsTradingAllowed())
      return;

   // Local variables
   int buy_stop_count = 0;
   int sell_stop_count = 0;
   int total_order_count = 0;
   int loop_index = 0;
   double total_current_profit = 0;
   double highest_open_price = 0;
   double lowest_open_price = 100000;

   // Get current prices
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   current_spread = NormalizeDouble(ask - bid, _Digits);
   average_spread = current_spread;

   // Initialize arrays
   ArrayResize(spread_history_array, spread_array_size);
   if(ArraySize(spread_history_array) != 0)
   {
      ArrayFill(spread_history_array, 0, spread_array_size, average_spread);
   }

   // Update price movement data
   UpdatePriceMovementData(ask, bid);

   // Loop through pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!order_info.SelectByIndex(i)) continue;

      if(order_info.Symbol() != _Symbol || order_info.Magic() != magic_number) continue;

      total_order_count++;
      datetime current_time = TimeCurrent();

      if(order_info.Type() == ORDER_TYPE_BUY_STOP)
      {
         long time_diff = current_time - buy_order_time;

         if(time_diff > minimum_time_lapse && GetPriceMovement() < price_movement_threshold)
         {
            trade.OrderDelete(order_info.Ticket());
            return;
         }
         buy_stop_count++;
      }
      else if(order_info.Type() == ORDER_TYPE_SELL_STOP)
      {
         long time_diff = current_time - sell_order_time;

         if(time_diff > minimum_time_lapse && GetPriceMovement() > -price_movement_threshold)
         {
            trade.OrderDelete(order_info.Ticket());
            return;
         }
         sell_stop_count++;
      }
   }

   // Loop through positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!position_info.SelectByIndex(i)) continue;

      if(position_info.Symbol() != _Symbol || position_info.Magic() != magic_number) continue;

      total_order_count++;

      // Handle buy positions
      if(position_info.PositionType() == POSITION_TYPE_BUY)
      {
         if(GetPriceMovement() < -price_movement_threshold &&
            bid < (position_info.PriceOpen() - stop_activation_point * _Point))
         {
            if(position_info.StopLoss() == 0)
            {
               double stop_points = stop_activation_buffer * _Point;
               trade.PositionModify(position_info.Ticket(), bid - stop_points, position_info.TakeProfit());
            }
         }
      }
      // Handle sell positions
      else if(position_info.PositionType() == POSITION_TYPE_SELL)
      {
         if(ask > (position_info.PriceOpen() + stop_activation_point * _Point))
         {
            if(position_info.StopLoss() == 0)
            {
               double stop_points = stop_activation_buffer * _Point;
               trade.PositionModify(position_info.Ticket(), ask + stop_points, position_info.TakeProfit());
            }
         }
      }

      total_current_profit += position_info.Profit();

      if(position_info.PriceOpen() < lowest_open_price)
         lowest_open_price = position_info.PriceOpen();

      if(position_info.PriceOpen() > highest_open_price)
         highest_open_price = position_info.PriceOpen();
   }

   // Close positions if profit threshold reached
   if(total_current_profit > minimum_profit_lock)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!position_info.SelectByIndex(i)) continue;

         if(position_info.Symbol() == _Symbol && position_info.Magic() == magic_number)
         {
            trade.PositionClose(position_info.Ticket());
         }
      }
   }

   // Place new orders
   if(total_order_count < max_concurrent_orders)
   {
      double price_movement = GetPriceMovement();

      if(MathAbs(price_movement) > stop_activation_point)
      {
         double sar_array[];
         ArrayResize(sar_array, 1);

         if(CopyBuffer(sar_handle, 0, 0, 1, sar_array) > 0)
         {
            double sar_value = sar_array[0];

            // Buy stop condition
            if(price_movement > stop_activation_point)
            {
               double sar_buy_level = sar_value - sar_buffer * _Point;

               if(sar_buy_level > ask && sar_buy_level < lowest_open_price)
               {
                  double lot_size = CalculateLotSize();
                  double entry_price = ask + sar_buffer * _Point;

                  if(trade.BuyStop(lot_size, entry_price, _Symbol, 0, 0, 0, "Mr CapFree"))
                  {
                     buy_order_time = TimeCurrent();
                  }
               }
            }

            // Sell stop condition
            else if(price_movement < -stop_activation_point)
            {
               double sar_sell_level = sar_value + sar_buffer * _Point;

               if(bid - sar_sell_level > highest_open_price)
               {
                  double lot_size = CalculateLotSize();
                  double entry_price = bid - sar_buffer * _Point;

                  if(trade.SellStop(lot_size, entry_price, _Symbol, 0, 0, 0, "Mr CapFree"))
                  {
                     sell_order_time = TimeCurrent();
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update price movement data                                       |
//+------------------------------------------------------------------+
void UpdatePriceMovementData(double ask, double bid)
{
   datetime newest_timestamp = 0;
   double current_bid_price = bid;
   double historical_bid_price = 0;
   int history_index = 0;

   // Shift spread history array
   for(int i = spread_array_size - 1; i > 0; i--)
   {
      spread_history_array[i] = spread_history_array[i-1];
   }
   spread_history_array[0] = ask - bid;

   // Calculate average spread
   double sum = 0;
   for(int i = 0; i < spread_array_size; i++)
   {
      sum += spread_history_array[i];
   }
   average_spread = sum / spread_array_size;

   // Update price and time arrays
   double temp_price_array[];
   datetime temp_time_array[];

   ArrayResize(temp_price_array, spread_array_size - 1);
   ArrayResize(temp_time_array, spread_array_size - 1);

   // Shift arrays
   for(int i = spread_array_size - 2; i > 0; i--)
   {
      temp_price_array[i] = price_history_array[i-1];
      temp_time_array[i] = time_history_array[i-1];
   }

   ArrayResize(temp_price_array, spread_array_size);
   ArrayResize(temp_time_array, spread_array_size);

   temp_price_array[0] = bid;
   temp_time_array[0] = TimeCurrent(); // FIXED: Changed from temp_time_array = TimeCurrent()

   ArrayCopy(price_history_array, temp_price_array);
   ArrayCopy(time_history_array, temp_time_array);

   ArrayFree(temp_price_array);
   ArrayFree(temp_time_array);
}

//+------------------------------------------------------------------+
//| Get price movement                                               |
//+------------------------------------------------------------------+
double GetPriceMovement()
{
   if(ArraySize(price_history_array) < minimum_time_lapse) return 0;

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double historical_price = 0;
   datetime current_time = TimeCurrent();

   for(int i = 0; i < ArraySize(time_history_array); i++)
   {
      if(current_time - time_history_array[i] >= minimum_time_lapse)
      {
         historical_price = price_history_array[i];
         break;
      }
   }

   double price_movement = current_price - historical_price;

   if(MathAbs(price_movement / _Point) > 10000)
      price_movement = 0;

   return price_movement;
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double lot_size = fixed_lots;

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(total_stop_loss <= 0)
   {
      Alert("Invalid stop loss! Using fixed lots.");
      return fixed_lots;
   }

   if(tick_value == 0 || tick_size == 0)
   {
      Alert("Broker data error! Using fixed lots.");
      return fixed_lots;
   }

   if(lot_step == 0)
   {
      Alert("Invalid lot step! Using fixed lots.");
      return fixed_lots;
   }

   switch(lot_size_mode)
   {
      case FIXED_LOTS:
         lot_size = fixed_lots;
         Alert("Lot size = " + DoubleToString(lot_size, 2));
         break;

      case ACCOUNT_BALANCE_PERCENT:
         lot_size = (AccountInfoDouble(ACCOUNT_BALANCE) * risk_percentage / 100) /
                   (total_stop_loss / lot_step * tick_value * tick_size);
         Alert("Lot size = " + DoubleToString(risk_percentage, 1) + "% of account balance");
         break;

      case EQUITY_PERCENT:
         lot_size = (AccountInfoDouble(ACCOUNT_EQUITY) * risk_percentage / 100) /
                   (total_stop_loss / lot_step * tick_value * tick_size);
         Alert("Lot size = " + DoubleToString(risk_percentage, 1) + "% of equity");
         break;

      case FREE_MARGIN_PERCENT:
         lot_size = (AccountInfoDouble(ACCOUNT_MARGIN_FREE) * risk_percentage / 100) /
                   (total_stop_loss / lot_step * tick_value * tick_size);
         Alert("Lot size = " + DoubleToString(risk_percentage, 1) + "% of free margin");
         break;

      case FIXED_RISK_AMOUNT:
         lot_size = fixed_risk_amount / (total_stop_loss / lot_step * tick_value * tick_size);
         Alert("Lot size = $" + DoubleToString(fixed_risk_amount, 2) + " fixed risk");
         break;
   }

   lot_size = NormalizeDouble(lot_size, 2);

   if(lot_size < min_lot)
   {
      Alert("Lot size too small! Using minimum lot.");
      lot_size = min_lot;
   }

   if(lot_size > max_lot)
   {
      Alert("Lot size too big! Using maximum lot.");
      lot_size = max_lot;
   }

   // Margin check
   double margin_required = 0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot_size, ask, margin_required))
   {
      Alert("Margin calculation failed! Using fixed lots.");
      return fixed_lots;
   }

   if(margin_required > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   {
      Alert("Insufficient margin! Using smaller lot size.");
      lot_size = (AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.9) /
                 (margin_required / lot_size);
      lot_size = NormalizeDouble(lot_size, 2);

      if(lot_size < min_lot)
         lot_size = min_lot;
   }

   return lot_size;
}

//+------------------------------------------------------------------+
//| Check trading restrictions                                       |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   // Time restrictions
   if(enable_trading_time)
   {
      datetime current_time = TimeCurrent();
      MqlDateTime time_struct;

      if(time_selection == GMT_TIME)
         TimeToStruct(current_time, time_struct);
      else
         TimeToStruct(TimeLocal(), time_struct);

      int current_hour = time_struct.hour;

      if(start_hour < end_hour)
      {
         if(current_hour < start_hour || current_hour >= end_hour)
            return false;
      }
      else
      {
         if(current_hour < start_hour && current_hour >= end_hour)
            return false;
      }
   }

   // Day restrictions
   if(enable_day_filter)
   {
      datetime current_time = TimeCurrent();
      MqlDateTime time_struct;
      TimeToStruct(current_time, time_struct);

      int day_of_week = time_struct.day_of_week;

      switch(day_of_week)
      {
         case 1: return trade_monday;
         case 2: return trade_tuesday;
         case 3: return trade_wednesday;
         case 4: return trade_thursday;
         case 5: return trade_friday;
         case 6: return trade_saturday;
         case 0: return trade_sunday;
      }
   }

   return true;
}
