//+------------------------------------------------------------------+
//|                                      Professional ORB Trader v3.0|
//|                              Advanced Opening Range Breakout EA |
//+------------------------------------------------------------------+
#property copyright "Professional ORB Trader v3.0"
#property link      ""
#property version   "3.00"
#property description "Professional Opening Range Breakout Strategy"
#property description "Multi-session support with advanced risk management"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "Risk Management"
input double RiskPercent = 1.0;              // Risk per trade (%)
input bool UseBreakEven = true;              // Enable break-even
input double BreakEvenPips = 20;             // Break-even trigger (pips)
input bool UseTrailingStop = true;           // Enable trailing stop
input double TrailingStopPips = 15;          // Trailing stop distance (pips)
input double TrailingStartPips = 25;         // Start trailing after (pips)

input group "Technical Analysis"
input int ATRPeriod = 14;                    // ATR period
input int ORBMinutes = 15;                   // ORB window (minutes)
input double ATRMultiplier = 2.0;            // ATR multiplier for SL

input group "Session Management"
input bool TradeNewYork = true;              // Trade NY session
input bool TradeLondon = true;               // Trade London session
input bool TradeTokyo = false;               // Trade Tokyo session

input group "Filters"
input double MaxSpreadATR = 0.3;             // Max spread (ATR multiplier)
input double MaxVolatilityATR = 4.0;         // Max hourly range (ATR multiplier)
input bool EnableLogging = true;             // Enable detailed logging

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double atr_value = 0;
bool orb_calculated = false;
double orb_high = 0, orb_low = 0, orb_range = 0;
datetime day_start_time = 0;
int trades_today = 0;
int magic_number = 20250814;

CTrade trade;
CSymbolInfo symbol_info;
CAccountInfo account_info;

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   if(EnableLogging) Print("Initializing Professional ORB Trader v3.0");

   trade.SetExpertMagicNumber(magic_number);

   if(!symbol_info.Name(_Symbol))
   {
      Print("ERROR: Failed to initialize symbol info");
      return INIT_FAILED;
   }

   if(!ValidateInputs())
   {
      Print("ERROR: Invalid input parameters");
      return INIT_PARAMETERS_INCORRECT;
   }

   day_start_time = TimeCurrent();
   trades_today = 0;
   orb_calculated = false;

   if(EnableLogging)
   {
      Print("Initialization successful");
      PrintSessionInfo();
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(EnableLogging)
   {
      Print("Shutting down - Reason: ", GetShutdownReason(reason));
      PrintPerformanceSummary();
   }
}

//+------------------------------------------------------------------+
//| Main Tick Handler                                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsMarketSafe()) return;

   if(!UpdateATR()) return;

   HandleORBCalculation();

   ManagePositions();

   double signal = GenerateTradingSignal();

   if(MathAbs(signal) >= 0.5)
      ExecuteTrade(signal);
}

//+------------------------------------------------------------------+
//| Input Validation                                                  |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   if(RiskPercent < 0.1 || RiskPercent > 10.0)
   {
      Print("WARNING: Risk % outside safe range (0.1-10.0)");
      return false;
   }

   if(ATRPeriod < 5 || ATRPeriod > 50)
   {
      Print("WARNING: ATR period outside optimal range (5-50)");
      return false;
   }

   if(ORBMinutes < 5 || ORBMinutes > 120)
   {
      Print("WARNING: ORB minutes outside practical range (5-120)");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Market Safety Check                                              |
//+------------------------------------------------------------------+
bool IsMarketSafe()
{
   static datetime last_warning = 0;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && !MQLInfoInteger(MQL_TESTER))
   {
      if(TimeCurrent() - last_warning > 3600)
      {
         Print("WARNING: Trading not allowed");
         last_warning = TimeCurrent();
      }
      return false;
   }

   if(!IsValidSession())
   {
      return false;
   }

   double spread = symbol_info.Spread() * _Point;
   double max_spread = (atr_value > 0) ? atr_value * MaxSpreadATR : _Point * 20;

   if(spread > max_spread)
   {
      if(TimeCurrent() - last_warning > 1800)
      {
         if(EnableLogging) Print("WARNING: Spread too high: ", DoubleToString(spread, _Digits));
         last_warning = TimeCurrent();
      }
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| ATR Update                                                        |
//+------------------------------------------------------------------+
bool UpdateATR()
{
   double temp[1];
   int atr_handle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);

   if(atr_handle == INVALID_HANDLE || CopyBuffer(atr_handle, 0, 0, 1, temp) != 1)
   {
      static datetime last_error = 0;
      if(TimeCurrent() - last_error > 300)
      {
         Print("ERROR: ATR calculation failed");
         last_error = TimeCurrent();
      }
      return false;
   }

   double new_atr = temp[0];

   // Spike protection
   if(atr_value > 0 && new_atr > atr_value * 5.0)
   {
      if(EnableLogging) Print("WARNING: Extreme ATR spike detected, limiting change");
      atr_value = atr_value * 2.0;
      return true;
   }

   atr_value = new_atr;
   return true;
}

//+------------------------------------------------------------------+
//| ORB Calculation Handler                                          |
//+------------------------------------------------------------------+
void HandleORBCalculation()
{
   if(orb_calculated)
   {
      MqlDateTime dt, last_dt;
      TimeToStruct(TimeCurrent(), dt);
      TimeToStruct(day_start_time, last_dt);

      if(dt.day != last_dt.day)
      {
         if(EnableLogging) Print("New trading day - resetting ORB");
         orb_calculated = false;
         trades_today = 0;
         day_start_time = TimeCurrent();
      }
      else
      {
         return;
      }
   }

   if(!IsORBCalculationTime()) return;

   if(CalculateORB())
   {
      orb_calculated = true;
      if(EnableLogging)
      {
         Print("ORB calculated: High=", DoubleToString(orb_high, _Digits),
               " Low=", DoubleToString(orb_low, _Digits),
               " Range=", DoubleToString(orb_range, _Digits));
      }
   }
}

//+------------------------------------------------------------------+
//| ORB Calculation                                                   |
//+------------------------------------------------------------------+
bool CalculateORB()
{
   if(ORBMinutes <= 0 || ORBMinutes > 120) return false;

   orb_high = -DBL_MAX;
   orb_low = DBL_MAX;
   int valid_bars = 0;

   double high_array[], low_array[];
   if(CopyHigh(_Symbol, PERIOD_M1, 1, ORBMinutes, high_array) != ORBMinutes ||
      CopyLow(_Symbol, PERIOD_M1, 1, ORBMinutes, low_array) != ORBMinutes)
   {
      Print("ERROR: Failed to copy bar data for ORB");
      return false;
   }

   for(int i = 0; i < ORBMinutes; i++)
   {
      if(high_array[i] <= 0 || low_array[i] <= 0 || high_array[i] < low_array[i])
         continue;

      if(orb_high == -DBL_MAX)
      {
         orb_high = high_array[i];
         orb_low = low_array[i];
      }
      else
      {
         orb_high = MathMax(orb_high, high_array[i]);
         orb_low = MathMin(orb_low, low_array[i]);
      }
      valid_bars++;
   }

   if(valid_bars < (int)(ORBMinutes * 0.8))
   {
      Print("ERROR: Insufficient valid bars: ", valid_bars, "/", ORBMinutes);
      return false;
   }

   orb_range = orb_high - orb_low;

   if(orb_range <= 0)
   {
      Print("ERROR: Invalid ORB range");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Trading Signal Generation                                         |
//+------------------------------------------------------------------+
double GenerateTradingSignal()
{
   if(!orb_calculated || orb_range <= 0) return 0.0;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(bid <= 0 || ask <= 0) return 0.0;

   // Volatility filter
   double recent_high[1], recent_low[1];
   if(CopyHigh(_Symbol, PERIOD_H1, 0, 1, recent_high) != 1 ||
      CopyLow(_Symbol, PERIOD_H1, 0, 1, recent_low) != 1)
      return 0.0;

   double hourly_range = recent_high[0] - recent_low[0];
   if(hourly_range > atr_value * MaxVolatilityATR)
   {
      if(EnableLogging) Print("INFO: Excessive volatility detected, skipping signal");
      return 0.0;
   }

   double price_position = (bid - orb_low) / orb_range;
   double range_strength = orb_range / atr_value;

   // Dynamic thresholds
   double upper = (range_strength > 1.5) ? 0.75 : 0.70;
   double lower = (range_strength > 1.5) ? 0.25 : 0.30;

   // Bullish breakout
   if(price_position > upper && bid > orb_high)
   {
      double strength = (bid - orb_high) / atr_value;
      return MathMin(1.0, 0.6 + strength * 0.4);
   }

   // Bearish breakdown
   if(price_position < lower && bid < orb_low)
   {
      double strength = (orb_low - bid) / atr_value;
      return MathMax(-1.0, -0.6 - strength * 0.4);
   }

   return 0.0;
}

//+------------------------------------------------------------------+
//| Position Management with Trailing Stop & Break-even             |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i))) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         PositionGetInteger(POSITION_MAGIC) != magic_number) continue;

      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(type == POSITION_TYPE_BUY)
      {
         double profit_pips = (bid - open_price) / _Point;

         // Break-even move
         if(UseBreakEven && current_sl < open_price && profit_pips >= BreakEvenPips)
         {
            double new_sl = NormalizeDouble(open_price + _Point, _Digits);
            if(trade.PositionModify(ticket, new_sl, current_tp))
            {
               if(EnableLogging) Print("Break-even activated for BUY #", ticket);
            }
         }

         // Trailing stop
         if(UseTrailingStop && profit_pips >= TrailingStartPips)
         {
            double trail_sl = NormalizeDouble(bid - TrailingStopPips * _Point, _Digits);
            if(trail_sl > current_sl && trail_sl < bid)
            {
               if(trade.PositionModify(ticket, trail_sl, current_tp))
               {
                  if(EnableLogging) Print("Trailing stop updated for BUY #", ticket, " to ", DoubleToString(trail_sl, _Digits));
               }
            }
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double profit_pips = (open_price - ask) / _Point;

         // Break-even move
         if(UseBreakEven && (current_sl > open_price || current_sl == 0) && profit_pips >= BreakEvenPips)
         {
            double new_sl = NormalizeDouble(open_price - _Point, _Digits);
            if(trade.PositionModify(ticket, new_sl, current_tp))
            {
               if(EnableLogging) Print("Break-even activated for SELL #", ticket);
            }
         }

         // Trailing stop
         if(UseTrailingStop && profit_pips >= TrailingStartPips)
         {
            double trail_sl = NormalizeDouble(ask + TrailingStopPips * _Point, _Digits);
            if((trail_sl < current_sl || current_sl == 0) && trail_sl > ask)
            {
               if(trade.PositionModify(ticket, trail_sl, current_tp))
               {
                  if(EnableLogging) Print("Trailing stop updated for SELL #", ticket, " to ", DoubleToString(trail_sl, _Digits));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trade Execution                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(double signal)
{
   if(MathAbs(signal) < 0.5) return;

   if(HasOpenPosition()) return;

   double lot_size = CalculatePositionSize();
   if(lot_size <= 0) return;

   if(!ValidateAccount(lot_size)) return;

   bool result = false;
   if(signal > 0.5)
      result = ExecuteBuy(lot_size);
   else if(signal < -0.5)
      result = ExecuteSell(lot_size);

   if(result)
   {
      trades_today++;
      if(EnableLogging) Print("Trade executed successfully. Total today: ", trades_today);
   }
}

//+------------------------------------------------------------------+
//| Buy Order Execution                                               |
//+------------------------------------------------------------------+
bool ExecuteBuy(double lot_size)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = NormalizeDouble(orb_low - (atr_value * ATRMultiplier), _Digits);
   double tp = NormalizeDouble(ask + (atr_value * ATRMultiplier * 1.5), _Digits);

   if(ask <= 0 || sl <= 0 || tp <= ask)
   {
      Print("ERROR: Invalid BUY price calculation");
      return false;
   }

   if(EnableLogging)
   {
      double risk_pips = (ask - sl) / _Point;
      double reward_pips = (tp - ask) / _Point;
      Print("BUY: Entry=", ask, " SL=", sl, " TP=", tp,
            " Risk=", (int)risk_pips, " Reward=", (int)reward_pips, " pips");
   }

   if(trade.Buy(lot_size, _Symbol, 0.0, sl, tp, "ORB Buy"))
   {
      if(EnableLogging) Print("BUY order executed. Ticket: ", trade.ResultOrder());
      return true;
   }
   else
   {
      Print("ERROR: BUY failed - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Sell Order Execution                                              |
//+------------------------------------------------------------------+
bool ExecuteSell(double lot_size)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = NormalizeDouble(orb_high + (atr_value * ATRMultiplier), _Digits);
   double tp = NormalizeDouble(bid - (atr_value * ATRMultiplier * 1.5), _Digits);

   if(bid <= 0 || sl <= 0 || tp >= bid)
   {
      Print("ERROR: Invalid SELL price calculation");
      return false;
   }

   if(EnableLogging)
   {
      double risk_pips = (sl - bid) / _Point;
      double reward_pips = (bid - tp) / _Point;
      Print("SELL: Entry=", bid, " SL=", sl, " TP=", tp,
            " Risk=", (int)risk_pips, " Reward=", (int)reward_pips, " pips");
   }

   if(trade.Sell(lot_size, _Symbol, 0.0, sl, tp, "ORB Sell"))
   {
      if(EnableLogging) Print("SELL order executed. Ticket: ", trade.ResultOrder());
      return true;
   }
   else
   {
      Print("ERROR: SELL failed - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Position Size Calculator                                          |
//+------------------------------------------------------------------+
double CalculatePositionSize()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0) return 0.0;

   double risk_amount = equity * (RiskPercent / 100.0);
   double sl_distance = atr_value * ATRMultiplier;

   if(sl_distance <= 0) return 0.0;

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0) return 0.0;

   double pip_value = tick_value / 10;
   double sl_pips = sl_distance / _Point;
   double risk_per_lot = sl_pips * pip_value;

   if(risk_per_lot <= 0) return 0.0;

   double lot_size = risk_amount / risk_per_lot;

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot);
   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   lot_size = NormalizeDouble(lot_size, 2);

   // Safety cap at 2% max risk
   double max_safe_risk = equity * 0.02;
   double calculated_risk = lot_size * risk_per_lot;

   if(calculated_risk > max_safe_risk)
   {
      lot_size = max_safe_risk / risk_per_lot;
      lot_size = MathFloor(lot_size / lot_step) * lot_step;
      lot_size = NormalizeDouble(lot_size, 2);
   }

   if(lot_size < min_lot) lot_size = 0;

   return lot_size;
}

//+------------------------------------------------------------------+
//| Check for Open Position                                           |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == magic_number)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Account Validation                                                |
//+------------------------------------------------------------------+
bool ValidateAccount(double lot_size)
{
   double required_margin = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot_size,
       SymbolInfoDouble(_Symbol, SYMBOL_ASK), required_margin))
   {
      Print("ERROR: Cannot calculate margin");
      return false;
   }

   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   if(required_margin > free_margin)
   {
      Print("ERROR: Insufficient margin. Required: ", required_margin, " Available: ", free_margin);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Session Management Functions                                      |
//+------------------------------------------------------------------+
bool IsValidSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;

   int gmt_hour = GetGMTHour(dt);

   if(TradeLondon && gmt_hour >= 8 && gmt_hour < 17) return true;
   if(TradeNewYork && gmt_hour >= 13 && gmt_hour < 22) return true;
   if(TradeTokyo && gmt_hour >= 0 && gmt_hour < 9) return true;

   return false;
}

bool IsORBCalculationTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int gmt_hour = GetGMTHour(dt);

   if(TradeLondon && gmt_hour == 8 && dt.min < ORBMinutes) return true;
   if(TradeNewYork && gmt_hour == 13 && dt.min >= 30 && dt.min < (30 + ORBMinutes)) return true;
   if(TradeTokyo && gmt_hour == 0 && dt.min < ORBMinutes) return true;

   return false;
}

int GetGMTHour(const MqlDateTime &dt)
{
   long gmt_offset = TimeGMTOffset() / 3600;
   return (dt.hour - (int)gmt_offset + 24) % 24;
}

//+------------------------------------------------------------------+
//| Helper Functions                                                  |
//+------------------------------------------------------------------+
void PrintSessionInfo()
{
   Print("=== Session Configuration ===");
   Print("London: ", (TradeLondon ? "Enabled" : "Disabled"));
   Print("New York: ", (TradeNewYork ? "Enabled" : "Disabled"));
   Print("Tokyo: ", (TradeTokyo ? "Enabled" : "Disabled"));
   Print("============================");
}

void PrintPerformanceSummary()
{
   Print("=== Performance Summary ===");
   Print("Trades Today: ", trades_today);
   Print("Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("Equity: $", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   Print("===========================");
}

string GetShutdownReason(const int reason)
{
   switch(reason)
   {
      case REASON_REMOVE: return "EA removed";
      case REASON_RECOMPILE: return "EA recompiled";
      case REASON_CHARTCHANGE: return "Chart changed";
      case REASON_CHARTCLOSE: return "Chart closed";
      case REASON_PARAMETERS: return "Parameters changed";
      case REASON_ACCOUNT: return "Account changed";
      case REASON_CLOSE: return "Terminal closing";
      default: return "Unknown (" + IntegerToString(reason) + ")";
   }
}
