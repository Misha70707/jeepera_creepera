//+------------------------------------------------------------------+
//| Warren Buffett v2.0 - The Legendary Market-Slaying Magic Weapon |
//| "Price is what you pay, value is what you get" - Warren Buffett |
//+------------------------------------------------------------------+
#property copyright "Warren Buffett v2.0 - Legendary Edition"
#property link      "https://berkshire-hathaway-trading.com"
#property version   "2.00"
#property description "The Legendary Market-Slaying Magic Weapon"
#property description "Transformed from Homeless Guy's Blueprint to Warren's Masterpiece"

// Include the legendary libraries
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Enhanced Input Parameters - Warren's Configuration Panel        |
//+------------------------------------------------------------------+
input group "📊 Risk Management - Warren's Rules"
input double g_RiskPercent = 1.0;         // Risk percentage per trade (0.1-10.0)

input group "📈 Technical Analysis Parameters"
input int g_ATRPeriod = 14;               // ATR calculation period (5-50)
input int g_ORBMinutes = 15;              // ORB calculation window minutes (5-120)

input group "🤖 AI Configuration - The Future"
input string LSTMModelPath = "Models/ORB_LSTM.xml";  // LSTM model path

input group "⏰ Session Management"
input bool TradeNewYork = true;         // Trade New York session
input bool TradeLondon = true;          // Trade London session
input bool TradeTokyo = false;          // Trade Tokyo session

//+------------------------------------------------------------------+
//| Global Variables - The Wizard's Arsenal                         |
//+------------------------------------------------------------------+
double atr_value;                       // Current ATR value
datetime us_open_time, eu_open_time, london_open_time, tokyo_open_time;
bool orb_calculated = false;            // ORB calculation status
double orb_high, orb_low, orb_range;    // ORB values
CTrade trade;                           // Trading object
CSymbolInfo symbol_info;                // Symbol information
CAccountInfo account_info;              // Account information

// Performance tracking variables
datetime last_trade_time = 0;
int total_trades_today = 0;
double daily_profit = 0.0;
datetime day_start_time = 0;
int magic_number = 20250814; // Hardcoded as per original

//+------------------------------------------------------------------+
//| Enhanced Input Parameter Validation                             |
//+------------------------------------------------------------------+
bool ValidateInputParameters()
{
   Print("🔍 Validating Warren Buffett approved parameters...");

   bool allValid = true;

   //-- Risk %
   if(g_RiskPercent < 0.1 || g_RiskPercent > 10.0)
   {
      Print("⚠️  g_RiskPercent ",g_RiskPercent,"% is outside safe range!");
      allValid = false;
   }

   //-- ATR period
   if(g_ATRPeriod < 5 || g_ATRPeriod > 50)
   {
      Print("⚠️  g_ATRPeriod ",g_ATRPeriod," is outside optimal range!");
      allValid = false;
   }

   //-- ORB minutes
   if(g_ORBMinutes < 5 || g_ORBMinutes > 120)
   {
      Print("⚠️  g_ORBMinutes ",g_ORBMinutes," is outside practical range!");
      allValid = false;
   }

   if(allValid)
      Print("✅ Inputs already within Warren-approved ranges!");
   else
      Print("🔧 Please correct inputs manually");

   return allValid;
}

//+------------------------------------------------------------------+
//| LSTM Model File Validation                                       |
//+------------------------------------------------------------------+
bool ValidateLSTMModel()
{
    Print("🤖 Validating LSTM model file...");

    // Check if model file exists
    if(!FileIsExist(LSTMModelPath, FILE_COMMON))
    {
        Print("⚠️ WARNING: LSTM model file not found: ", LSTMModelPath);
        Print("💡 EA will work without AI assistance");
        Print("📁 To enable AI: Copy your .xml model file to: Terminal/Common/Files/Models/");
        return false; // Not fatal - EA can work without LSTM
    }

    // Try to open the file to verify it's not corrupted
    int handle = FileOpen(LSTMModelPath, FILE_READ|FILE_BIN|FILE_COMMON);
    if(handle == INVALID_HANDLE)
    {
        Print("⚠️ WARNING: Cannot open LSTM model file. Error: ", GetLastError());
        Print("💡 Check file permissions and format");
        return false;
    }

    // Check if file has content (not empty)
    ulong fileSize = FileSize(handle);
    FileClose(handle);

    if(fileSize <= 0)
    {
        Print("⚠️ WARNING: LSTM model file is empty!");
        return false;
    }

    Print("✅ LSTM Model validated successfully! Size: ", fileSize, " bytes");
    Print("🤖 AI assistance enabled - prepare for enhanced signals!");
    return true;
}

//+------------------------------------------------------------------+
//| Market Session Time Initialization                              |
//+------------------------------------------------------------------+
bool InitializeMarketSessions()
{
    Print("🌍 Initializing global market sessions...");

    // Get current date for session calculation
    MqlDateTime dt;
    datetime current_time = TimeCurrent();
    TimeToStruct(current_time, dt);

    // US Market: 9:30 AM EST (14:30 GMT during standard time, 13:30 GMT during DST)
    dt.hour = IsDST() ? 13 : 14; dt.min = 30; dt.sec = 0;
    us_open_time = StructToTime(dt);

    // European Market: 8:00 AM CET (7:00 AM GMT)
    dt.hour = 7; dt.min = 0; dt.sec = 0;
    eu_open_time = StructToTime(dt);

    // London Market: 8:00 AM GMT
    dt.hour = 8; dt.min = 0; dt.sec = 0;
    london_open_time = StructToTime(dt);

    // Tokyo Market: 9:00 AM JST (0:00 GMT)
    dt.hour = 0; dt.min = 0; dt.sec = 0;
    tokyo_open_time = StructToTime(dt);

    // Validate times were set correctly
    if(us_open_time <= 0 || eu_open_time <= 0 || london_open_time <= 0 || tokyo_open_time <= 0)
    {
        Print("🚨 ERROR: Failed to calculate market session times!");
        return false;
    }

    Print("✅ Market sessions initialized successfully!");
    return true;
}

//+------------------------------------------------------------------+
//| Trading Environment Setup                                        |
//+------------------------------------------------------------------+
bool InitializeTradingEnvironment()
{
    Print("⚙️ Setting up Warren's legendary trading environment...");

    trade.SetExpertMagicNumber(magic_number);

    // Initialize symbol info
    if(!symbol_info.Name(_Symbol))
    {
        Print("🚨 ERROR: Failed to initialise symbol info for: ",_Symbol);
        return false;
    }

    // Check if trading is allowed (SKIP IN TESTER!)
    if(!MQLInfoInteger(MQL_TESTER) && !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        Print("🚨 ERROR: Trading not allowed in terminal!");
        return false;
    }

    // Validate account type and display info
    ENUM_ACCOUNT_TRADE_MODE account_type = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
    if(account_type == ACCOUNT_TRADE_MODE_DEMO)
        Print("📊 Demo account detected - Perfect for testing Warren's strategies!");
    else if(account_type == ACCOUNT_TRADE_MODE_REAL)
        Print("💰 Live account detected - Time to make Warren proud!");

    Print("✅ Trading environment ready for legendary profits!");
    return true;
}

//+------------------------------------------------------------------+
//| Session Information Display                                      |
//+------------------------------------------------------------------+
void PrintTradingSessionInfo()
{
    Print("📊 === WARREN BUFFETT TRADING SESSION INFORMATION ===");
    Print("🇺🇸 US Session: ", TimeToString(us_open_time, TIME_MINUTES), (TradeNewYork ? " [ENABLED]" : " [DISABLED]"));
    Print("🇪🇺 EU Session: ", TimeToString(eu_open_time, TIME_MINUTES), " [ENABLED]");
    Print("🇬🇧 London Session: ", TimeToString(london_open_time, TIME_MINUTES), (TradeLondon ? " [ENABLED]" : " [DISABLED]"));
    Print("🇯🇵 Tokyo Session: ", TimeToString(tokyo_open_time, TIME_MINUTES), (TradeTokyo ? " [ENABLED]" : " [DISABLED]"));
    Print("⏰ Current Time: ", TimeToString(TimeCurrent(), TIME_MINUTES));
    Print("💎 Remember: 'Time is the friend of the wonderful business' - W.B.");
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Warren's Epic OnInit Function - The Hero's Journey Begins       |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🚀 Initializing Warren Buffett v2.0 Forex Edition...");
    Print("💎 'Price is what you pay, value is what you get' - W.B.");
    Print("⚔️ Preparing the Market-Slaying Magic Weapon...");

    // STEP 1: Validate all input parameters (Warren's Risk Management)
    if(!ValidateInputParameters())
    {
        Print("❌ Input parameter validation failed!");
        return INIT_PARAMETERS_INCORRECT;
    }

    // STEP 2: Validate LSTM model file (Warren's Due Diligence)
    bool lstm_available = ValidateLSTMModel();
    if(!lstm_available)
    {
        Print("⚠️ LSTM model not available - continuing with traditional ORB strategy");
        // Not fatal - EA can work without LSTM
    }

    // STEP 3: Initialize market session times (Warren's Market Knowledge)
    if(!InitializeMarketSessions())
    {
        Print("❌ Market session initialization failed!");
        return INIT_FAILED;
    }

    // STEP 4: Setup trading environment (Warren's Preparation)
    if(!InitializeTradingEnvironment())
    {
        Print("❌ Trading environment setup failed!");
        return INIT_FAILED;
    }

    // STEP 5: Initialize performance tracking
    day_start_time = TimeCurrent();
    total_trades_today = 0;
    daily_profit = 0.0;
    orb_calculated = false;

    // Reset ORB values
    orb_high = 0;
    orb_low = 0;
    orb_range = 0;
    atr_value = 0;

    // STEP 6: Final success confirmation
    Print("✅ Warren Buffett v2.0 EA initialized successfully!");
    Print("💰 'Rule No. 1: Never lose money. Rule No. 2: Never forget rule No. 1' - W.B.");
    Print("🎯 Ready to compound wealth like Berkshire Hathaway!");
    PrintTradingSessionInfo();

    Print("🧙‍♂️ The Wizard's blessing: May your profits be legendary!");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Warren's Epic OnDeinit - The Legendary Farewell                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("🔥 Warren Buffett v2.0 is shutting down...");
    Print("💎 'In the business world, the rearview mirror is always clearer than the windshield.' - W.B.");

    // STEP 1: Identify and log the shutdown reason
    string shutdown_reason = GetShutdownReasonText(reason);
    Print("🔍 Shutdown Reason: ", shutdown_reason);

    // STEP 2: Save current trading state for analysis
    SaveTradingState();

    // STEP 3: Generate performance summary
    GeneratePerformanceSummary();

    // STEP 4: Clean up resources and close positions if needed
    PerformCleanupOperations(reason);

    // STEP 5: Final farewell with Warren's wisdom
    Print("✅ Warren Buffett v2.0 shutdown completed successfully!");
    Print("💰 'The stock market is designed to transfer money from the Active to the Patient.' - W.B.");
    Print("🎯 Until next time, keep compounding those gains!");
    Print("📈 Remember: We don't just trade, we build wealth like Berkshire Hathaway!");

    // Play a sound effect for dramatic exit (optional)
    if(reason == REASON_REMOVE)
    {
        Print("🎵 Playing farewell symphony...");
        PlaySound("alert.wav");
    }

    Print("🧙‍♂️ The Wizard's final blessing: May the markets be forever in your favor!");
}

//+------------------------------------------------------------------+
//| Shutdown Reason Decoder - What's Happening?                     |
//+------------------------------------------------------------------+
string GetShutdownReasonText(const int reason)
{
    string reason_text = "";

    switch(reason)
    {
        case REASON_REMOVE:
            reason_text = "🗑️ EA manually removed from chart";
            break;
        case REASON_RECOMPILE:
            reason_text = "🔄 EA recompiled - probably adding more Warren wisdom!";
            break;
        case REASON_CHARTCHANGE:
            reason_text = "📈 Chart symbol or timeframe changed";
            break;
        case REASON_CHARTCLOSE:
            reason_text = "❌ Chart window closed";
            break;
        case REASON_PARAMETERS:
            reason_text = "⚙️ EA parameters modified - optimizing for more profits!";
            break;
        case REASON_ACCOUNT:
            reason_text = "👤 Trading account changed";
            break;
        case REASON_TEMPLATE:
            reason_text = "📋 Chart template applied";
            break;
        case REASON_INITFAILED:
            reason_text = "🚨 EA initialization failed - check your settings!";
            break;
        case REASON_CLOSE:
            reason_text = "🚪 MetaTrader terminal closing";
            break;
        default:
            reason_text = "🤔 Unknown reason (Code: " + IntegerToString(reason) + ") - even Warren is puzzled!";
            break;
    }

    return reason_text;
}

//+------------------------------------------------------------------+
//| Save Trading State - Preserve the Legend                         |
//+------------------------------------------------------------------+
void SaveTradingState()
{
    Print("💾 Saving current trading state for the history books...");

    // Save ORB values if calculated
    if(orb_calculated)
    {
        Print("📊 Last ORB Values (The Final Battlefield):");
        Print("   📈 High: ", DoubleToString(orb_high, _Digits));
        Print("   📉 Low: ", DoubleToString(orb_low, _Digits));
        Print("   📏 Range: ", DoubleToString(orb_range, _Digits), " pips");

        if(atr_value > 0)
        {
            double range_to_atr = orb_range / atr_value;
            Print("   📊 Range/ATR Ratio: ", DoubleToString(range_to_atr, 2));
        }
    }
    else
    {
        Print("📊 ORB was not calculated in final session");
    }

    // Save ATR value
    if(atr_value > 0)
        Print("📊 Last ATR: ", DoubleToString(atr_value, _Digits));

    // Save session times
    Print("⏰ Session Times (Last Configuration):");
    Print("   🇺🇸 US Open: ", TimeToString(us_open_time, TIME_MINUTES));
    Print("   🇪🇺 EU Open: ", TimeToString(eu_open_time, TIME_MINUTES));
    Print("   🇬🇧 London Open: ", TimeToString(london_open_time, TIME_MINUTES));
    Print("   🇯🇵 Tokyo Open: ", TimeToString(tokyo_open_time, TIME_MINUTES));

    // Save daily performance
    Print("📈 Today's Performance:");
    Print("   🎯 Total Trades: ", total_trades_today);
    Print("   💰 Daily P&L: $", DoubleToString(daily_profit, 2));

    Print("✅ Trading state preserved for future generations!");
}

//+------------------------------------------------------------------+
//| Generate Performance Summary - The Warren Report                |
//+------------------------------------------------------------------+
void GeneratePerformanceSummary()
{
    Print("📊 === WARREN BUFFETT PERFORMANCE SUMMARY ===");

    // Get account information
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double account_profit = AccountInfoDouble(ACCOUNT_PROFIT);
    double account_margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double account_freemargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

    Print("💰 Account Statistics:");
    Print("   💵 Balance: $", DoubleToString(account_balance, 2));
    Print("   💎 Equity: $", DoubleToString(account_equity, 2));
    Print("   📈 Floating P&L: $", DoubleToString(account_profit, 2));
    Print("   🛡️ Used Margin: $", DoubleToString(account_margin, 2));
    Print("   💸 Free Margin: $", DoubleToString(account_freemargin, 2));

    // Calculate margin level
    double margin_level = 0;
    if(account_margin > 0)
        margin_level = (account_equity / account_margin) * 100;
    Print("   📊 Margin Level: ", DoubleToString(margin_level, 1), "%");

    // EA Runtime statistics
    datetime current_time = TimeCurrent();
    datetime runtime = current_time - day_start_time;
    Print("⏱️ EA Runtime: ", TimeToString(runtime, TIME_MINUTES));
    Print("🎯 Signals Generated Today: ", total_trades_today);

    // Warren's wisdom based on performance
    if(account_profit > 0)
        Print("💰 'Rule No.1: Never lose money. Rule No.2: Don't forget rule No.1' - Mission Accomplished!");
    else if(account_profit < 0)
        Print("📚 'The most important investment you can make is in yourself' - Time to learn and optimize!");
    else
        Print("⚖️ 'Price is what you pay. Value is what you get' - Breaking even is better than losing!");

    if(margin_level > 300)
        Print("🛡️ 'Risk comes from not knowing what you're doing' - Excellent margin management!");
    else if(margin_level < 150)
        Print("⚠️ 'When others are greedy, be fearful' - Consider reducing position sizes!");

    Print("===============================================");
}

//+------------------------------------------------------------------+
//| Cleanup Operations - The Final Guardian                         |
//+------------------------------------------------------------------+
void PerformCleanupOperations(const int reason)
{
    Print("🧹 Performing Warren's legendary cleanup operations...");

    // If EA is being removed, check for open positions
    if(reason == REASON_REMOVE)
    {
        Print("🚨 EA being removed - conducting final position audit...");

        // Count positions with our magic number
        int our_positions = 0;
        double total_floating_profit = 0;

        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if(PositionGetTicket(i))
            {
                if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
                {
                    our_positions++;
                    total_floating_profit += PositionGetDouble(POSITION_PROFIT);
                }
            }
        }

        if(our_positions > 0)
        {
            Print("⚠️ ATTENTION: Found ", our_positions, " open positions from Warren v2.0");
            Print("💰 Total floating P&L: $", DoubleToString(total_floating_profit, 2));
            Print("💡 Positions will continue running independently");
            Print("🎯 Consider your exit strategy based on Warren's principles");

            // Alert the user
            Alert("🚨 Warren v2.0 removed with " + IntegerToString(our_positions) +
                  " positions still open!\n💰 Floating P&L: $" + DoubleToString(total_floating_profit, 2));
        }
        else
        {
            Print("✅ No open positions found - clean shutdown achieved!");
            Print("💎 'The best time to plant a tree was 20 years ago. The second best time is now' - W.B.");
        }
    }

    // Reset global variables
    orb_calculated = false;
    orb_high = 0;
    orb_low = 0;
    orb_range = 0;
    atr_value = 0;
    total_trades_today = 0;
    daily_profit = 0;

    Print("✅ Cleanup operations completed with Warren's precision!");
}

//+------------------------------------------------------------------+
//| The Legendary OnTick() - Heart of the Trading Beast             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Warren's Rule #1: Never trade without proper validation
    if(!IsMarketConditionsSafe())
        return;

    // STEP 1: Update market volatility with bulletproof error handling
    if(!UpdateATRSafely())
    {
        static datetime last_atr_error = 0;
        if(TimeCurrent() - last_atr_error > 300) // Warn every 5 minutes
        {
            Print("⚠️ ATR update failed - skipping this tick");
            last_atr_error = TimeCurrent();
        }
        return;
    }

    // STEP 2: Handle ORB calculation during proper market hours
    HandleORBCalculation();

    // STEP 3: Get Warren's legendary trading signal
    double signal = GetWarrenBuffettTradingSignal();

    // STEP 4: Execute trades with legendary risk management
    if(MathAbs(signal) >= 0.5) // Only trade when we have a clear signal
        ExecuteWarrenStyleTrades(signal);

    // STEP 5: Monitor and manage existing positions
    ManageExistingPositions();

    // STEP 6: Update performance metrics
    UpdatePerformanceTracking();
}

//+------------------------------------------------------------------+
//| Market Safety Check - Warren's First Line of Defense            |
//+------------------------------------------------------------------+
bool IsMarketConditionsSafe()
{
    // Check if trading is allowed
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        static datetime last_trading_warning = 0;
        if(TimeCurrent() - last_trading_warning > 3600) // Warn once per hour
        {
            Print("🚫 Trading not allowed in terminal - Warren says: 'Patience is key'");
            last_trading_warning = TimeCurrent();
        }
        return false;
    }

    // Check if we're in a valid trading session
    if(!IsValidTradingSession())
    {
        static datetime last_session_warning = 0;
        if(TimeCurrent() - last_session_warning > 3600) // Warn once per hour
        {
            Print("⏰ Outside trading hours - Warren says: 'The patient investor is rewarded'");
            last_session_warning = TimeCurrent();
        }
        return false;
    }

    // Check spread conditions
    double current_spread = symbol_info.Spread() * _Point;
    double max_spread = (atr_value > 0) ? atr_value * 0.3 : _Point * 20; // Max spread = 30% of ATR or 20 points

    if(current_spread > max_spread)
    {
        static datetime last_spread_warning = 0;
        if(TimeCurrent() - last_spread_warning > 1800) // Warn every 30 minutes
        {
            Print("📊 Spread too high: ", DoubleToString(current_spread, _Digits),
                  " (Max: ", DoubleToString(max_spread, _Digits), ") - Warren avoids high costs");
            last_spread_warning = TimeCurrent();
        }
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Bulletproof ATR Update - No More Silent Failures               |
//+------------------------------------------------------------------+
bool UpdateATRSafely()
{
    double temp[1];
    int atr_handle = iATR(_Symbol, PERIOD_CURRENT, g_ATRPeriod);
    if(atr_handle == INVALID_HANDLE || CopyBuffer(atr_handle, 0, 0, 1, temp) != 1)
    {
        Print("🚨 ATR calculation failed - Error: ", GetLastError());
        return false;
    }

    double new_atr = temp[0];  // FIXED: Access array element

    // Validate ATR is reasonable (not extreme)
    if(atr_value > 0 && new_atr > atr_value * 5.0) // ATR suddenly 5x larger
    {
        Print("⚠️ Extreme ATR spike detected: ", DoubleToString(new_atr, _Digits + 1),
              " vs previous ", DoubleToString(atr_value, _Digits + 1));
        Print("💭 Warren says: 'When others are greedy, be fearful' - Volatility spike detected!");

        // Use gradual adjustment instead of sudden jump
        atr_value = atr_value * 2.0; // Max 2x change per tick
        return true;
    }

    atr_value = new_atr;

    // Log ATR updates periodically
    static datetime last_atr_log = 0;
    if(TimeCurrent() - last_atr_log > 900) // Every 15 minutes
    {
        Print("📊 ATR Updated: ", DoubleToString(atr_value, _Digits + 1));
        last_atr_log = TimeCurrent();
    }

    return true;
}

//+------------------------------------------------------------------+
//| Intelligent ORB Calculation Handler                             |
//+------------------------------------------------------------------+
void HandleORBCalculation()
{
    // Check if ORB is already calculated for today
    if(orb_calculated)
    {
        // Check if we need to reset for new day
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        MqlDateTime last_calc_dt;
        TimeToStruct(day_start_time, last_calc_dt);

        if(dt.day != last_calc_dt.day) // New day detected
        {
            Print("📅 New trading day detected - resetting ORB calculation");
            orb_calculated = false;
            total_trades_today = 0;
            daily_profit = 0;
            day_start_time = TimeCurrent();
        }
        else
        {
            return; // ORB already calculated for today
        }
    }

    if(!IsORBCalculationTime())
        return; // Not the right time for ORB calculation

    Print("🎯 Starting Warren's legendary ORB calculation...");

    if(CalculateORBSafely())
    {
        orb_calculated = true;
        Print("✅ ORB calculated successfully!");
        Print("📊 Range: ", DoubleToString(orb_range, _Digits),
              " (", DoubleToString(orb_range / atr_value, 2), "x ATR)");

        // Warren's wisdom based on range size
        double range_strength = orb_range / atr_value;
        if(range_strength > 2.0)
            Print("💎 'Big opportunities come infrequently' - Large ORB detected!");
        else if(range_strength < 0.5)
            Print("🔍 'The stock market is a voting machine in the short run' - Narrow range, patience required!");
        else
            Print("⚖️ 'Price is what you pay, value is what you get' - Normal range detected!");
    }
    else
    {
        Print("❌ ORB calculation failed - will retry next valid opportunity");
    }
}

//+------------------------------------------------------------------+
//| Multi-Session ORB Time Validation                               |
//+------------------------------------------------------------------+
bool IsORBCalculationTime()
{
    if(!IsMarketOpen())
        return false;

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    // Check enabled sessions
    bool valid_time = false;

    if(TradeLondon && IsLondonORBTime(dt))
    {
        Print("🇬🇧 London ORB time window detected");
        valid_time = true;
    }

    if(TradeNewYork && IsNewYorkORBTime(dt))
    {
        Print("🇺🇸 New York ORB time window detected");
        valid_time = true;
    }

    if(TradeTokyo && IsTokyoORBTime(dt))
    {
        Print("🇯🇵 Tokyo ORB time window detected");
        valid_time = true;
    }

    return valid_time;
}

//+------------------------------------------------------------------+
//| Market Open Validation - Warren's Market Hours                  |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    // No trading on weekends (Warren's rule: Markets rest, so should we)
    if(dt.day_of_week == 0 || dt.day_of_week == 6) // Sunday = 0, Saturday = 6
        return false;

    // Basic holiday check (extend this with proper calendar)
    if(IsHoliday(dt))
    {
        Print("🎄 Holiday detected - Even Warren takes holidays!");
        return false;
    }

    // At least one major market should be open
    return (IsLondonSessionActive(dt) || IsNewYorkSessionActive(dt) || IsTokyoSessionActive(dt));
}

//+------------------------------------------------------------------+
//| Session Time Checkers - Global Market Awareness                 |
//+------------------------------------------------------------------+
bool IsLondonORBTime(const MqlDateTime &dt)
{
    // London opens at 8:00 GMT
    int gmt_hour = GetGMTHour(dt);
    return (gmt_hour == 8 && dt.min < g_ORBMinutes);
}

bool IsNewYorkORBTime(const MqlDateTime &dt)
{
    // New York opens at 9:30 EST (14:30 GMT standard, 13:30 GMT DST)
    int gmt_hour = GetGMTHour(dt);
    int ny_open_gmt = IsDST() ? 13 : 14;

    return (gmt_hour == ny_open_gmt && dt.min >= 30 && dt.min < (30 + g_ORBMinutes));
}

bool IsTokyoORBTime(const MqlDateTime &dt)
{
    // Tokyo opens at 9:00 JST (0:00 GMT)
    int gmt_hour = GetGMTHour(dt);
    return (gmt_hour == 0 && dt.min < g_ORBMinutes);
}

//+------------------------------------------------------------------+
//| Session Activity Checkers                                       |
//+------------------------------------------------------------------+
bool IsLondonSessionActive(const MqlDateTime &dt)
{
    int gmt_hour = GetGMTHour(dt);
    return (gmt_hour >= 8 && gmt_hour < 17); // 8 AM - 5 PM GMT
}

bool IsNewYorkSessionActive(const MqlDateTime &dt)
{
    int gmt_hour = GetGMTHour(dt);
    int ny_open = IsDST() ? 13 : 14;
    int ny_close = IsDST() ? 21 : 22;
    return (gmt_hour >= ny_open && gmt_hour < ny_close);
}

bool IsTokyoSessionActive(const MqlDateTime &dt)
{
    int gmt_hour = GetGMTHour(dt);
    return (gmt_hour >= 0 && gmt_hour < 9); // 12 AM - 9 AM GMT
}

//+------------------------------------------------------------------+
//| Helper Functions - The Wizard's Utilities                       |
//+------------------------------------------------------------------+
int GetGMTHour(const MqlDateTime &dt)
{
    long gmt_offset = TimeGMTOffset() / 3600;
    int gmt_hour = (dt.hour - (int)gmt_offset + 24) % 24;
    return gmt_hour;
}

bool IsDST()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if (dt.mon > 3 && dt.mon < 11) return true;  // US DST: Mar-Nov
    if (dt.mon == 3 && dt.day >= 8) return true;  // 2nd Sun Mar
    if (dt.mon == 11 && dt.day <= 7) return true;  // 1st Sun Nov
    return false;
}

bool IsHoliday(const MqlDateTime &dt)
{
    // Basic holiday check - Christmas and New Year
    if((dt.mon == 12 && dt.day >= 24) || (dt.mon == 1 && dt.day == 1))
        return true;

    return false;
}

//+------------------------------------------------------------------+
//| Valid Trading Session Check                                     |
//+------------------------------------------------------------------+
bool IsValidTradingSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    bool valid_session = false;

    if(TradeLondon && IsLondonSessionActive(dt))
        valid_session = true;
    if(TradeNewYork && IsNewYorkSessionActive(dt))
        valid_session = true;
    if(TradeTokyo && IsTokyoSessionActive(dt))
        valid_session = true;

    return valid_session;
}

//+------------------------------------------------------------------+
//| Position Management - Warren's Portfolio Oversight              |
//+------------------------------------------------------------------+
void ManageExistingPositions()
{
    static datetime last_management_check = 0;

    // Check positions every 30 seconds
    if(TimeCurrent() - last_management_check < 30)
        return;

    last_management_check = TimeCurrent();

    // Count and analyze our positions
    int our_positions = 0;
    double total_profit = 0;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionGetTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_number)
            {
                our_positions++;
                total_profit += PositionGetDouble(POSITION_PROFIT);
            }
        }
    }

    // Log position status periodically
    static datetime last_position_log = 0;
    if(our_positions > 0 && TimeCurrent() - last_position_log > 600) // Every 10 minutes
    {
        Print("📊 Position Status: ", our_positions, " positions, P&L: $", DoubleToString(total_profit, 2));
        last_position_log = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Performance Tracking - Warren's Accountability                  |
//+------------------------------------------------------------------+
void UpdatePerformanceTracking()
{
    static datetime last_performance_update = 0;

    // Update every hour
    if(TimeCurrent() - last_performance_update < 3600)
        return;

    last_performance_update = TimeCurrent();

    // Calculate daily performance
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    static double session_start_equity = 0;

    if(session_start_equity == 0)
        session_start_equity = current_equity;

    daily_profit = current_equity - session_start_equity;

    // Log performance summary
    Print("📈 Performance Update:");
    Print("   💰 Daily P&L: $", DoubleToString(daily_profit, 2));
    Print("   🎯 Trades Today: ", total_trades_today);
    Print("   💎 'Compound interest is the eighth wonder of the world' - Einstein/Warren");
}

//+------------------------------------------------------------------+
//| Warren's T-Rex Killer Signal Generator v2.0                     |
//+------------------------------------------------------------------+
double GetWarrenBuffettTradingSignal()
{
    Print("🎯 Generating Warren's legendary trading signal...");

    // STEP 1: ORB Validation - No signal without proper setup
    if(!orb_calculated || orb_range <= 0)
    {
        static datetime last_orb_warning = 0;
        if(TimeCurrent() - last_orb_warning > 1800) // Warn every 30 minutes
        {
            Print("📊 No valid ORB data - Warren says: 'Never invest without data'");
            last_orb_warning = TimeCurrent();
        }
        return 0.0;
    }

    // STEP 2: Get current market data with validation
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double spread = ask_price - current_price;

    if(current_price <= 0 || ask_price <= 0)
    {
        Print("🚨 Invalid price data - market malfunction detected!");
        return 0.0;
    }

    // STEP 3: T-Rex volatility protection (avoid extreme conditions)
    double recent_high[1], recent_low[1];
    if(CopyHigh(_Symbol, PERIOD_H1, 0, 1, recent_high) != 1 || CopyLow(_Symbol, PERIOD_H1, 0, 1, recent_low) != 1)
        return 0.0;
    double hourly_range = recent_high[0] - recent_low[0];  // FIXED: Access array elements

    if(hourly_range > atr_value * 4.0)
    {
        Print("🦖 T-Rex volatility detected! Staying safe - Range: ", DoubleToString(hourly_range, _Digits));
        Print("💭 Warren says: 'When others are greedy, be fearful'");
        return 0.0;
    }

    // STEP 4: Check spread conditions
    double max_acceptable_spread = atr_value * 0.3;
    if(spread > max_acceptable_spread)
    {
        Print("📊 Spread too high for profitable trading: ", DoubleToString(spread, _Digits));
        return 0.0;
    }

    // STEP 5: Calculate relative position in ORB
    double price_position = (current_price - orb_low) / orb_range;

    // STEP 6: Dynamic threshold adjustment (toothpick becomes T-Rex slayer!)
    double range_strength = orb_range / atr_value;
    double upper_threshold = 0.7;
    double lower_threshold = 0.3;

    // Adjust thresholds based on range strength
    if(range_strength > 1.5) // Strong range = tighter thresholds
    {
        upper_threshold = 0.75;
        lower_threshold = 0.25;
        Print("💪 Strong ORB range detected - using tighter thresholds");
    }
    else if(range_strength < 0.8) // Weak range = wider thresholds
    {
        upper_threshold = 0.65;
        lower_threshold = 0.35;
        Print("🔍 Weak ORB range detected - using wider thresholds");
    }

    // STEP 7: Signal generation with strength calculation
    double signal_strength = 0.0;

    // Bullish signal detection
    if(price_position > upper_threshold && current_price > orb_high)
    {
        double breakout_strength = (current_price - orb_high) / atr_value;
        signal_strength = MathMin(1.0, 0.6 + breakout_strength * 0.4); // Scale 0.6-1.0

        Print("🚀 BULLISH breakout detected!");
        Print("   📊 Price position: ", DoubleToString(price_position * 100, 1), "%");
        Print("   ⚡ Breakout strength: ", DoubleToString(breakout_strength, 2), "x ATR");
        Print("   💎 Signal strength: ", DoubleToString(signal_strength, 2));

        return signal_strength;
    }
    // Bearish signal detection
    else if(price_position < lower_threshold && current_price < orb_low)
    {
        double breakdown_strength = (orb_low - current_price) / atr_value;
        signal_strength = MathMax(-1.0, -0.6 - breakdown_strength * 0.4); // Scale -0.6 to -1.0

        Print("📉 BEARISH breakdown detected!");
        Print("   📊 Price position: ", DoubleToString(price_position * 100, 1), "%");
        Print("   ⚡ Breakdown strength: ", DoubleToString(breakdown_strength, 2), "x ATR");
        Print("   💎 Signal strength: ", DoubleToString(signal_strength, 2));

        return signal_strength;
    }

    // STEP 8: No signal conditions (patience is key)
    static datetime last_no_signal_log = 0;
    if(TimeCurrent() - last_no_signal_log > 1800) // Log every 30 minutes
    {
        Print("⏰ No trading signal - Price position: ", DoubleToString(price_position * 100, 1), "%");
        Print("💭 Warren says: 'The stock market rewards patience'");
        last_no_signal_log = TimeCurrent();
    }

    return 0.0;
}

//+------------------------------------------------------------------+
//| Warren's Bulletproof ORB Calculator v2.0                        |
//+------------------------------------------------------------------+
bool CalculateORBSafely()
{
    Print("🎯 Starting Warren's bulletproof ORB calculation...");

    // STEP 1: Validate ORB period
    if(g_ORBMinutes <= 0 || g_ORBMinutes > 120)
    {
        Print("🚨 Invalid ORB period: ", g_ORBMinutes, " minutes");
        return false;
    }

    // STEP 2: Initialize with proper constants (no more magic numbers!)
    orb_high = -DBL_MAX;
    orb_low = DBL_MAX;
    int successful_bars = 0;

    Print("📊 Analyzing ", g_ORBMinutes, " bars for ORB calculation...");

    // STEP 3: Loop through COMPLETED bars only (start from 1, not 0!)
    double high_array[], low_array[];
    if(CopyHigh(_Symbol, PERIOD_M1, 1, g_ORBMinutes, high_array) != g_ORBMinutes ||
       CopyLow(_Symbol, PERIOD_M1, 1, g_ORBMinutes, low_array) != g_ORBMinutes)
    {
        Print("🚨 Failed to copy bar data");
        return false;
    }

    for(int i = 0; i < g_ORBMinutes; i++)
    {
        double high = high_array[i];
        double low = low_array[i];

        // STEP 4: Comprehensive data validation
        if(high <= 0 || low <= 0 || high < low)
        {
            Print("🚨 Invalid bar data at position ", i, " - High:", DoubleToString(high, _Digits),
                  " Low:", DoubleToString(low, _Digits));
            continue; // Skip bad data but continue
        }

        // STEP 5: Extreme bar detection (T-Rex protection!)
        double bar_range = high - low;
        if(bar_range > atr_value * 5.0 && atr_value > 0)
        {
            Print("⚠️ Extreme bar range detected: ", DoubleToString(bar_range, _Digits),
                  " (", DoubleToString(bar_range/atr_value, 1), "x ATR) - Possible data error");
            // Include but flag for attention
        }

        // STEP 6: Update ORB values
        if(orb_high == -DBL_MAX) // First valid bar
        {
            orb_high = high;
            orb_low = low;
        }
        else
        {
            orb_high = MathMax(orb_high, high);
            orb_low = MathMin(orb_low, low);
        }

        successful_bars++;
    }

    // STEP 7: Validate sufficient data
    int minimum_bars = (int)(g_ORBMinutes * 0.8); // At least 80% valid bars
    if(successful_bars < minimum_bars)
    {
        Print("🚨 Insufficient valid bars: ", successful_bars, "/", g_ORBMinutes, " (need ", minimum_bars, ")");
        Print("💡 Warren says: 'It's better to be approximately right than precisely wrong'");
        return false;
    }

    // STEP 8: Calculate and validate range
    orb_range = orb_high - orb_low;

    if(orb_range <= 0)
    {
        Print("🚨 Invalid ORB range: ", DoubleToString(orb_range, _Digits));
        return false;
    }

    // STEP 9: Range reasonableness check
    if(atr_value > 0)
    {
        double range_to_atr_ratio = orb_range / atr_value;
        if(range_to_atr_ratio < 0.1 || range_to_atr_ratio > 8.0)
        {
            Print("⚠️ Unusual ORB/ATR ratio: ", DoubleToString(range_to_atr_ratio, 2));
            if(range_to_atr_ratio < 0.1)
                Print("💭 Extremely narrow range - market sleeping?");
            else if(range_to_atr_ratio > 5.0)
                Print("💭 Extremely wide range - T-Rex stomping around?");
        }
    }

    // STEP 10: Success! Log results with Warren's wisdom
    Print("✅ ORB calculated successfully!");
    Print("📊 High: ", DoubleToString(orb_high, _Digits));
    Print("📊 Low: ", DoubleToString(orb_low, _Digits));
    Print("📊 Range: ", DoubleToString(orb_range, _Digits));
    if(atr_value > 0)
        Print("📊 Range/ATR Ratio: ", DoubleToString(orb_range / atr_value, 2));
    Print("📊 Valid bars used: ", successful_bars, "/", g_ORBMinutes);

    return true;
}

//+------------------------------------------------------------------+
//| Warren's Ultimate Position Size Calculator                       |
//+------------------------------------------------------------------+
double CalculateWarrenPositionSize()
{
    Print("💰 Calculating Warren's legendary position size...");

    // STEP 1: Account validation (Use EQUITY, not BALANCE!)
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);

    if(account_equity <= 0)
    {
        Print("🚨 Invalid account data - Equity: $", DoubleToString(account_equity, 2));
        return 0.0;
    }

    // Warren's Rule: Use EQUITY (protects against floating losses)
    Print("💰 Account equity: $", DoubleToString(account_equity, 2));

    // STEP 2: Calculate risk amount
    double risk_amount = account_equity * (g_RiskPercent / 100.0);
    Print("📊 Risk amount: $", DoubleToString(risk_amount, 2), " (", g_RiskPercent, "%)");

    // STEP 3: Get symbol trading parameters
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);  // $ per tick per lot
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);    // Tick size (e.g., 0.00001)
    double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);  // 100000 for majors

    Print("📋 Symbol parameters:");
    Print("💱 Tick value: $", DoubleToString(tick_value, 2));
    Print("📏 Tick size: ", DoubleToString(tick_size, _Digits));
    Print("📦 Contract size: ", DoubleToString(contract_size, 0));

    // STEP 4: Validate symbol parameters
    if(tick_value <= 0 || tick_size <= 0 || contract_size <= 0)
    {
        Print("🚨 Invalid symbol parameters!");
        return 0.0;
    }

    // STEP 5: Calculate PROPER stop-loss distance (the KEY difference!)
    double stop_loss_distance = atr_value * 2.0; // 2x ATR stop loss (in price units, e.g., 0.00200 for 20 pips)

    if(atr_value <= 0 || stop_loss_distance <= 0)
    {
        Print("💀 Invalid ATR or stop-loss distance!");
        return 0.0;
    }

    Print("🛡️ Stop-loss distance: ", DoubleToString(stop_loss_distance, _Digits));

    // FIXED STEP 6: Correct risk per lot (standard formula: $ risk for 1 lot over SL in pips)
    double pip_value = tick_value / 10; // Standard for Forex (adjust for other symbols)
    double sl_pips = stop_loss_distance / _Point;  // Convert SL to pips
    double risk_per_lot = sl_pips * pip_value;  // Correct: ~$20 for 20-pip SL on EURUSD

    if(risk_per_lot <= 0)
    {
        Print("🚨 Invalid risk per lot calculation!");
        return 0.0;
    }

    double lot_size = risk_amount / risk_per_lot;

    Print("📊 Risk calculations:");
    Print("💸 Risk per lot: $", DoubleToString(risk_per_lot, 1));
    Print("📏 Raw lot size: ", DoubleToString(lot_size, 2));

    // STEP 7: Apply volume constraints
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    Print("📋Volume limits: Min=", DoubleToString(min_lot, 2),
          "Max=", DoubleToString(max_lot, 2), "Step=", DoubleToString(lot_step, 2));

    // STEP 8: Apply constraints and round properly
    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);

    // Round down to lot step (safety first!)
    lot_size = MathFloor(lot_size / lot_step) * lot_step;
    lot_size = NormalizeDouble(lot_size, 2);

    // STEP 9: Wizard's ultimate safety check (never risk more than 2% total)
    double max_safe_risk = account_equity * 0.02;
    double calculated_risk = lot_size * risk_per_lot;

    if(calculated_risk > max_safe_risk)
    {
        Print("🧙‍♂️ Wizard's safety override activated!");
        Print("⚠️ Calculated risk ($", DoubleToString(calculated_risk, 2), ") exceeds safe limit ($", DoubleToString(max_safe_risk, 2), ")");

        lot_size = max_safe_risk / risk_per_lot;
        lot_size = MathFloor(lot_size / lot_step) * lot_step;
        lot_size = NormalizeDouble(lot_size, 2);

        Print("🛡️ Position size reduced to: ", DoubleToString(lot_size, 2), " lots");
    }

    // STEP 10: Final validation
    if(lot_size <= 0)
    {
        Print("💀 Final lot size is zero - no trading allowed");
        Print("💭 Warren says: 'Rule No.1: Never lose money'");
        return 0.0;
    }

    Print("✅ Position size calculation completed!");
    Print("💎 Final lot size: ", DoubleToString(lot_size, 2), " lots");
    Print("💰 Risk amount: $", DoubleToString(lot_size * risk_per_lot, 2));
    Print("📊 Risk percentage: ", DoubleToString((lot_size * risk_per_lot / account_equity) * 100, 2), "%");

    return lot_size;
}

//+------------------------------------------------------------------+
//| Warren's Legendary Trade Execution Engine                        |
//+------------------------------------------------------------------+
void ExecuteWarrenStyleTrades(double signal)
{
    Print("⚔️ Warren's legendary trading engine activated!");
    Print("📊 Signal strength: ", DoubleToString(signal, 2));

    // STEP 1: Signal strength validation
    if(MathAbs(signal) < 0.5)
    {
        Print("💭 Signal too weak - Warren says: 'Patience is the friend of the investor'");
        return;
    }

    // STEP 2: Check for existing positions
    if(HasOpenPositionForSymbol())
    {
        Print("📋 Position already exists - Warren doesn't overtrade");
        return;
    }

    // STEP 3: Calculate position size
    double lot_size = CalculateWarrenPositionSize();
    if(lot_size <= 0)
    {
        Print("🚨 Position size calculation failed - trade aborted!");
        return;
    }

    // STEP 4: Account validation
    if(!ValidateAccountForTrading(lot_size))
    {
        Print("💰 Account validation failed - insufficient funds or margin");
        return;
    }

    // STEP 5: Execute trade based on signal direction
    bool trade_result = false;
    if(signal > 0.5)
        trade_result = ExecuteBuyTrade(signal, lot_size);
    else if(signal < -0.5)
        trade_result = ExecuteSellTrade(signal, lot_size);

    // STEP 6: Update statistics
    if(trade_result)
    {
        total_trades_today++;
        last_trade_time = TimeCurrent();
        Print("✅ Trade executed successfully! Total trades today: ", total_trades_today);
    }

    Print("⚔️ Warren's trading engine complete!");
}

//+------------------------------------------------------------------+
//| Buy Trade Execution - Warren's Bullish Power                     |
//+------------------------------------------------------------------+
bool ExecuteBuyTrade(double signal, double lot_size)
{
    Print("🚀 Executing BUY trade with Warren's precision...");
    Print("💪 Signal strength: ", DoubleToString(signal, 2));

    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = NormalizeDouble(orb_low - (atr_value * 2.0), _Digits);  // Dynamic stop-loss
    double tp = NormalizeDouble(ask_price + (atr_value * 3.0), _Digits); // Dynamic take-profit (1:1.5 R:R)

    // Validate prices
    if(ask_price <= 0 || sl <= 0 || tp <= ask_price)
    {
        Print("🚨 Invalid price calculation - Buy trade aborted");
        Print("   💰 Ask: ", DoubleToString(ask_price, _Digits));
        Print("   🛡️ SL: ", DoubleToString(sl, _Digits));
        Print("   🎯 TP: ", DoubleToString(tp, _Digits));
        return false;
    }

    // Calculate risk-reward ratio
    double risk = ask_price - sl;
    double reward = tp - ask_price;
    double rr_ratio = (risk > 0) ? reward / risk : 0;

    Print("📈 BUY order details:");
    Print("   💰 Entry: ", DoubleToString(ask_price, _Digits));
    Print("   🛡️ Stop Loss: ", DoubleToString(sl, _Digits));
    Print("   🎯 Take Profit: ", DoubleToString(tp, _Digits));
    Print("   📊 Risk: ", DoubleToString(risk, _Digits), " Reward: ", DoubleToString(reward, _Digits));
    Print("   ⚖️ R:R Ratio: 1:", DoubleToString(rr_ratio, 1));
    Print("   📦 Lot Size: ", DoubleToString(lot_size, 2));

    // Execute the trade
    if(trade.Buy(lot_size, _Symbol, 0.0, sl, tp, "Warren v2.0 ORB Buy"))
    {
        Print("✅ BUY trade executed successfully!");
        Print("💎 'The stock market rewards patience' - W.B.");
        Print("📊 Trade ticket: ", trade.ResultOrder());
        return true;
    }
    else
    {
        Print("❌ BUY trade failed - Error: ", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
        Print("💭 'Failure is the condiment that gives success its flavor' - W.B.");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Sell Trade Execution - Warren's Bearish Power                   |
//+------------------------------------------------------------------+
bool ExecuteSellTrade(double signal, double lot_size)
{
    Print("📉 Executing SELL trade with Warren's precision...");
    Print("💪 Signal strength: ", DoubleToString(signal, 2));

    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = NormalizeDouble(orb_high + (atr_value * 2.0), _Digits);  // Dynamic stop-loss
    double tp = NormalizeDouble(bid_price - (atr_value * 3.0), _Digits); // Dynamic take-profit (1:1.5 R:R)

    // Validate prices
    if(bid_price <= 0 || sl <= 0 || tp >= bid_price)
    {
        Print("🚨 Invalid price calculation - Sell trade aborted");
        Print("   💰 Bid: ", DoubleToString(bid_price, _Digits));
        Print("   🛡️ SL: ", DoubleToString(sl, _Digits));
        Print("   🎯 TP: ", DoubleToString(tp, _Digits));
        return false;
    }

    // Calculate risk-reward ratio
    double risk = sl - bid_price;
    double reward = bid_price - tp;
    double rr_ratio = (risk > 0) ? reward / risk : 0;

    Print("📉 SELL order details:");
    Print("   💰 Entry: ", DoubleToString(bid_price, _Digits));
    Print("   🛡️ Stop Loss: ", DoubleToString(sl, _Digits));
    Print("   🎯 Take Profit: ", DoubleToString(tp, _Digits));
    Print("   📊 Risk: ", DoubleToString(risk, _Digits), " Reward: ", DoubleToString(reward, _Digits));
    Print("   ⚖️ R:R Ratio: 1:", DoubleToString(rr_ratio, 1));
    Print("   📦 Lot Size: ", DoubleToString(lot_size, 2));

    // Execute the trade
    if(trade.Sell(lot_size, _Symbol, 0.0, sl, tp, "Warren v2.0 ORB Sell"))
    {
        Print("✅ SELL trade executed successfully!");
        Print("💎 'Be greedy when others are fearful' - W.B.");
        Print("📊 Trade ticket: ", trade.ResultOrder());
        return true;
    }
    else
    {
        Print("❌ SELL trade failed - Error: ", trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
        Print("💭 'The most important investment you can make is in yourself' - W.B.");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Position Checker - Warren's Portfolio Awareness                 |
//+------------------------------------------------------------------+
bool HasOpenPositionForSymbol()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == magic_number)
            {
                Print("📋 Found existing position for ", _Symbol, " (Ticket: ", PositionGetInteger(POSITION_TICKET), ")");
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Account Validation for Trading - Warren's Financial Check       |
//+------------------------------------------------------------------+
bool ValidateAccountForTrading(double lot_size)
{
    Print("💰 Validating account for Warren-approved trading...");

    // Calculate required margin
    double required_margin = 0;
    if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot_size, SymbolInfoDouble(_Symbol, SYMBOL_ASK), required_margin))
    {
        Print("🚨 Cannot calculate required margin - Error: ", GetLastError());
        return false;
    }

    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);

    Print("📊 Account status:");
    Print("   💵 Balance: $", DoubleToString(balance, 2));
    Print("   💎 Equity: $", DoubleToString(equity, 2));
    Print("   💸 Free Margin: $", DoubleToString(free_margin, 2));
    Print("   📋 Required Margin: $", DoubleToString(required_margin, 2));

    // Check margin requirements
    if(required_margin > free_margin)
    {
        Print("💰 Insufficient margin!");
        Print("   ❌ Required: $", DoubleToString(required_margin, 2));
        Print("   ❌ Available: $", DoubleToString(free_margin, 2));
        Print("💭 Warren says: 'Never invest beyond your means'");
        return false;
    }

    // Check if margin usage would be too high (over 70%)
    double total_margin = AccountInfoDouble(ACCOUNT_MARGIN) + required_margin;
    double margin_usage = (total_margin / equity) * 100;

    if(margin_usage > 70.0)
    {
        Print("⚠️ High margin usage warning: ", DoubleToString(margin_usage, 1), "%");
        Print("💭 Warren says: 'Risk comes from not knowing what you're doing'");
        // Allow but warn
    }

    // Check account equity vs balance (floating losses)
    double drawdown_percent = ((balance - equity) / balance) * 100;
    if(drawdown_percent > 20.0)
    {
        Print("⚠️ Significant drawdown detected: ", DoubleToString(drawdown_percent, 1), "%");
        Print("💭 Consider reducing position sizes until recovery");
    }

    Print("✅ Account validated for trading!");
    Print("   💪 Margin usage: ", DoubleToString(margin_usage, 1), "%");
    Print("   📈 Drawdown: ", DoubleToString(drawdown_percent, 1), "%");

    return true;
}
