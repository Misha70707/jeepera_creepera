//+------------------------------------------------------------------+
//|                                           ORB_Professional.mq5 |
//|                   Production-Ready Opening Range Breakout EA    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict

//--- Include libraries
#include <Common/TradeManager.mqh>
#include <Common/RiskManager.mqh>
#include <Common/ErrorHandling.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Strategy Parameters ==="
input int      InpMagicNumber      = 20241115;     // Magic Number
input string   InpTradeComment     = "ORB_Pro";    // Trade Comment
input int      InpORBMinutes       = 30;           // ORB Period (minutes)
input double   InpBreakoutBuffer   = 5;            // Breakout Buffer (points)

input group "=== Risk Management ==="
input double   InpRiskPercent      = 1.0;          // Risk Per Trade (%)
input double   InpMaxLotSize       = 10.0;         // Maximum Lot Size
input double   InpMinLotSize       = 0.01;         // Minimum Lot Size
input double   InpMaxDailyLoss     = 3.0;          // Max Daily Loss (%)
input double   InpMaxDrawdown      = 10.0;         // Max Drawdown (%)

input group "=== Position Management ==="
input int      InpStopLossATR      = 2;            // Stop Loss (ATR multiplier)
input int      InpTakeProfitATR    = 3;            // Take Profit (ATR multiplier)
input bool     InpUseBreakeven     = true;         // Use Breakeven
input int      InpBreakevenATR     = 1;            // Breakeven at (ATR multiplier)
input bool     InpUseTrailing      = true;         // Use Trailing Stop
input int      InpTrailingATR      = 1;            // Trailing Distance (ATR multiplier)

input group "=== Session Times (Server Time) ==="
input bool     InpTradeLondon      = true;         // Trade London Session
input int      InpLondonOpen       = 8;            // London Open Hour
input bool     InpTradeNewYork     = true;         // Trade New York Session
input int      InpNewYorkOpen      = 14;           // New York Open Hour (14 = 9 AM EST if server is GMT+5)
input bool     InpTradeAsia        = false;        // Trade Asia Session
input int      InpAsiaOpen         = 0;            // Asia Open Hour

input group "=== Filters ==="
input int      InpATRPeriod        = 14;           // ATR Period
input double   InpMinATR           = 0;            // Minimum ATR (0 = disabled)
input int      InpMaxSpread        = 50;           // Maximum Spread (points, 0 = disabled)
input bool     InpOnlyTrending     = false;        // Only Trade Trending Markets
input int      InpADXPeriod        = 14;           // ADX Period
input double   InpMinADX           = 20;           // Minimum ADX for trending

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTradeManager  g_trade;
CRiskManager   g_risk;
CErrorHandler  g_error;

// Indicator handles
int            g_atrHandle = INVALID_HANDLE;
int            g_adxHandle = INVALID_HANDLE;

// ORB data structure
struct SORBSession
{
    bool        active;
    bool        calculated;
    bool        traded;
    datetime    start_time;
    datetime    end_time;
    double      high;
    double      low;
    double      range;
    string      name;
};

SORBSession g_londonORB;
SORBSession g_newyorkORB;
SORBSession g_asiaORB;

datetime    g_lastDayChecked = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Validate inputs
    if(InpRiskPercent <= 0 || InpRiskPercent > 10)
    {
        Print("ERROR: Risk percent must be between 0 and 10");
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpORBMinutes <= 0 || InpORBMinutes > 240)
    {
        Print("ERROR: ORB period must be between 1 and 240 minutes");
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpStopLossATR <= 0 || InpTakeProfitATR <= 0)
    {
        Print("ERROR: SL and TP ATR multipliers must be positive");
        return INIT_PARAMETERS_INCORRECT;
    }

    if(!InpTradeLondon && !InpTradeNewYork && !InpTradeAsia)
    {
        Print("ERROR: At least one session must be enabled");
        return INIT_PARAMETERS_INCORRECT;
    }

    //--- Initialize trade manager
    if(!g_trade.Init(InpMagicNumber, InpTradeComment))
    {
        Print("ERROR: Failed to initialize Trade Manager");
        return INIT_FAILED;
    }

    //--- Initialize risk manager
    g_risk.SetRiskPercent(InpRiskPercent);
    g_risk.SetMaxLot(InpMaxLotSize);
    g_risk.SetMinLot(InpMinLotSize);
    g_risk.SetMaxDailyLoss(InpMaxDailyLoss);
    g_risk.SetMaxDrawdown(InpMaxDrawdown);

    //--- Create ATR indicator
    g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    if(g_atrHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR indicator");
        return INIT_FAILED;
    }

    //--- Create ADX indicator if needed
    if(InpOnlyTrending)
    {
        g_adxHandle = iADX(_Symbol, PERIOD_CURRENT, InpADXPeriod);
        if(g_adxHandle == INVALID_HANDLE)
        {
            Print("ERROR: Failed to create ADX indicator");
            return INIT_FAILED;
        }
    }

    //--- Initialize ORB sessions
    g_londonORB.name = "London";
    g_newyorkORB.name = "NewYork";
    g_asiaORB.name = "Asia";

    ResetAllSessions();

    //--- Check for sufficient bars
    int bars = Bars(_Symbol, PERIOD_M1);
    if(bars < InpORBMinutes + 100)
    {
        Print("WARNING: Insufficient M1 bars. Need at least ", InpORBMinutes + 100);
    }

    Print("ORB Professional EA initialized successfully");
    Print("Sessions enabled: ",
          InpTradeLondon ? "London " : "",
          InpTradeNewYork ? "NewYork " : "",
          InpTradeAsia ? "Asia" : "");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicator handles
    if(g_atrHandle != INVALID_HANDLE)
    {
        IndicatorRelease(g_atrHandle);
        g_atrHandle = INVALID_HANDLE;
    }

    if(g_adxHandle != INVALID_HANDLE)
    {
        IndicatorRelease(g_adxHandle);
        g_adxHandle = INVALID_HANDLE;
    }

    //--- Cleanup
    g_trade.Deinit();

    Print("ORB EA stopped. Reason: ", g_error.GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check for new day and reset sessions
    CheckNewDay();

    //--- Check risk limits
    if(!g_risk.IsTradeAllowed())
    {
        return;
    }

    //--- Update ORB sessions
    UpdateORBSessions();

    //--- Manage existing positions
    ManagePositions();

    //--- Check for trade signals
    CheckTradeSignals();
}

//+------------------------------------------------------------------+
//| Check for new day and reset sessions                             |
//+------------------------------------------------------------------+
void CheckNewDay()
{
    MqlDateTime currentTime, lastTime;
    TimeToStruct(TimeCurrent(), currentTime);
    TimeToStruct(g_lastDayChecked, lastTime);

    if(currentTime.day != lastTime.day)
    {
        Print("New trading day detected. Resetting ORB sessions.");
        ResetAllSessions();
        g_lastDayChecked = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Reset all ORB sessions                                           |
//+------------------------------------------------------------------+
void ResetAllSessions()
{
    ResetSession(g_londonORB);
    ResetSession(g_newyorkORB);
    ResetSession(g_asiaORB);
}

//+------------------------------------------------------------------+
//| Reset single ORB session                                         |
//+------------------------------------------------------------------+
void ResetSession(SORBSession &session)
{
    session.active = false;
    session.calculated = false;
    session.traded = false;
    session.start_time = 0;
    session.end_time = 0;
    session.high = 0;
    session.low = 0;
    session.range = 0;
}

//+------------------------------------------------------------------+
//| Update all ORB sessions                                          |
//+------------------------------------------------------------------+
void UpdateORBSessions()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int currentHour = dt.hour;
    int currentMinute = dt.min;

    //--- Update London session
    if(InpTradeLondon)
    {
        UpdateSession(g_londonORB, InpLondonOpen, currentHour, currentMinute);
    }

    //--- Update New York session
    if(InpTradeNewYork)
    {
        UpdateSession(g_newyorkORB, InpNewYorkOpen, currentHour, currentMinute);
    }

    //--- Update Asia session
    if(InpTradeAsia)
    {
        UpdateSession(g_asiaORB, InpAsiaOpen, currentHour, currentMinute);
    }
}

//+------------------------------------------------------------------+
//| Update single ORB session                                        |
//+------------------------------------------------------------------+
void UpdateSession(SORBSession &session, int openHour, int currentHour, int currentMinute)
{
    //--- Check if we're in ORB calculation period
    bool inORBPeriod = false;

    if(currentHour == openHour && currentMinute < InpORBMinutes)
    {
        inORBPeriod = true;

        if(!session.active)
        {
            session.active = true;
            session.start_time = TimeCurrent();
            Print(session.name, " ORB period started at ", TimeToString(session.start_time));
        }
    }

    //--- Calculate ORB at end of period
    if(session.active && !session.calculated)
    {
        if(currentHour == openHour && currentMinute == InpORBMinutes)
        {
            CalculateORB(session);
        }
        else if(currentHour > openHour || (currentHour == openHour && currentMinute > InpORBMinutes))
        {
            // Missed the exact minute, calculate now
            CalculateORB(session);
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate ORB for session                                        |
//+------------------------------------------------------------------+
void CalculateORB(SORBSession &session)
{
    session.high = 0;
    session.low = DBL_MAX;

    //--- Get M1 bars for ORB period
    MqlRates rates[];
    ArraySetAsSeries(rates, true);

    int bars_to_copy = InpORBMinutes + 5; // Extra bars for safety
    int copied = CopyRates(_Symbol, PERIOD_M1, 0, bars_to_copy, rates);

    if(copied < InpORBMinutes)
    {
        Print("ERROR: Failed to copy M1 bars for ", session.name, " ORB calculation");
        return;
    }

    //--- Find high and low
    for(int i = 0; i < InpORBMinutes; i++)
    {
        session.high = MathMax(session.high, rates[i].high);
        session.low = MathMin(session.low, rates[i].low);
    }

    session.range = session.high - session.low;
    session.calculated = true;
    session.end_time = TimeCurrent();

    Print(session.name, " ORB calculated - High: ", DoubleToString(session.high, _Digits),
          " Low: ", DoubleToString(session.low, _Digits),
          " Range: ", DoubleToString(session.range / _Point, 1), " points");
}

//+------------------------------------------------------------------+
//| Check for trade signals                                          |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
    //--- Check each session
    if(InpTradeLondon && g_londonORB.calculated && !g_londonORB.traded)
    {
        CheckSessionSignal(g_londonORB);
    }

    if(InpTradeNewYork && g_newyorkORB.calculated && !g_newyorkORB.traded)
    {
        CheckSessionSignal(g_newyorkORB);
    }

    if(InpTradeAsia && g_asiaORB.calculated && !g_asiaORB.traded)
    {
        CheckSessionSignal(g_asiaORB);
    }
}

//+------------------------------------------------------------------+
//| Check signal for specific session                                |
//+------------------------------------------------------------------+
void CheckSessionSignal(SORBSession &session)
{
    //--- Check if we already have a position for this session
    if(g_trade.HasPosition(_Symbol))
        return;

    //--- Apply filters
    if(!PassesFilters())
        return;

    //--- Get current price
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    //--- Get ATR for stop loss calculation
    double atr = GetATR();
    if(atr <= 0)
        return;

    //--- Check for breakout above ORB high
    double breakout_level_high = session.high + InpBreakoutBuffer * point;
    if(ask > breakout_level_high)
    {
        ExecuteBuyOrder(session, atr);
        return;
    }

    //--- Check for breakout below ORB low
    double breakout_level_low = session.low - InpBreakoutBuffer * point;
    if(bid < breakout_level_low)
    {
        ExecuteSellOrder(session, atr);
        return;
    }
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder(SORBSession &session, double atr)
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    //--- Calculate SL/TP
    double sl = ask - (InpStopLossATR * atr);
    double tp = ask + (InpTakeProfitATR * atr);

    //--- Calculate lot size
    int slPoints = (int)((ask - sl) / point);
    double lot = g_risk.CalculateLotSize(_Symbol, slPoints);

    if(lot <= 0)
    {
        Print("ERROR: Invalid lot size calculated");
        return;
    }

    //--- Execute trade
    if(g_trade.Buy(_Symbol, lot, sl, tp))
    {
        session.traded = true;
        Print(session.name, " ORB: BUY executed at ", ask,
              " SL=", sl, " TP=", tp, " Lot=", lot);
    }
    else
    {
        Print("ERROR: ", session.name, " ORB: BUY failed - ", g_error.GetLastErrorText());
    }
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrder(SORBSession &session, double atr)
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    //--- Calculate SL/TP
    double sl = bid + (InpStopLossATR * atr);
    double tp = bid - (InpTakeProfitATR * atr);

    //--- Calculate lot size
    int slPoints = (int)((sl - bid) / point);
    double lot = g_risk.CalculateLotSize(_Symbol, slPoints);

    if(lot <= 0)
    {
        Print("ERROR: Invalid lot size calculated");
        return;
    }

    //--- Execute trade
    if(g_trade.Sell(_Symbol, lot, sl, tp))
    {
        session.traded = true;
        Print(session.name, " ORB: SELL executed at ", bid,
              " SL=", sl, " TP=", tp, " Lot=", lot);
    }
    else
    {
        Print("ERROR: ", session.name, " ORB: SELL failed - ", g_error.GetLastErrorText());
    }
}

//+------------------------------------------------------------------+
//| Check if price passes filters                                    |
//+------------------------------------------------------------------+
bool PassesFilters()
{
    //--- Check spread
    if(InpMaxSpread > 0)
    {
        long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        if(spread > InpMaxSpread)
        {
            //Print("Spread too high: ", spread, " points");
            return false;
        }
    }

    //--- Check minimum ATR
    if(InpMinATR > 0)
    {
        double atr = GetATR();
        if(atr < InpMinATR)
        {
            //Print("ATR too low: ", atr);
            return false;
        }
    }

    //--- Check trending market
    if(InpOnlyTrending)
    {
        double adx = GetADX();
        if(adx < InpMinADX)
        {
            //Print("Market not trending. ADX: ", adx);
            return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Get ATR value                                                     |
//+------------------------------------------------------------------+
double GetATR()
{
    double buffer[];
    ArraySetAsSeries(buffer, true);

    if(CopyBuffer(g_atrHandle, 0, 0, 1, buffer) != 1)
    {
        Print("ERROR: Failed to get ATR value");
        return 0;
    }

    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get ADX value                                                     |
//+------------------------------------------------------------------+
double GetADX()
{
    if(g_adxHandle == INVALID_HANDLE)
        return 0;

    double buffer[];
    ArraySetAsSeries(buffer, true);

    if(CopyBuffer(g_adxHandle, 0, 0, 1, buffer) != 1)
    {
        Print("ERROR: Failed to get ADX value");
        return 0;
    }

    return buffer[0];
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions()
{
    if(!g_trade.HasPosition(_Symbol))
        return;

    ulong ticket = g_trade.GetPositionTicket(_Symbol);
    if(ticket == 0)
        return;

    if(!PositionSelectByTicket(ticket))
        return;

    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);

    double currentPrice = (posType == POSITION_TYPE_BUY) ?
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double atr = GetATR();
    if(atr <= 0)
        return;

    //--- Apply breakeven
    if(InpUseBreakeven)
    {
        ApplyBreakeven(ticket, posType, openPrice, currentPrice, currentSL, atr);
    }

    //--- Apply trailing stop
    if(InpUseTrailing)
    {
        ApplyTrailingStop(ticket, posType, openPrice, currentPrice, currentSL, currentTP, atr);
    }
}

//+------------------------------------------------------------------+
//| Apply breakeven to position                                      |
//+------------------------------------------------------------------+
void ApplyBreakeven(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice,
                   double currentPrice, double currentSL, double atr)
{
    double profitATR = MathAbs(currentPrice - openPrice) / atr;

    if(profitATR >= InpBreakevenATR)
    {
        double newSL = openPrice;
        bool shouldModify = false;

        if(posType == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            shouldModify = true;
        else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            shouldModify = true;

        if(shouldModify)
        {
            double tp = PositionGetDouble(POSITION_TP);
            if(g_trade.ModifyPosition(ticket, newSL, tp))
            {
                Print("Breakeven set for position ", ticket, " at ", newSL);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop to position                                  |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice,
                      double currentPrice, double currentSL, double currentTP, double atr)
{
    double profitATR = (posType == POSITION_TYPE_BUY) ?
                       (currentPrice - openPrice) / atr :
                       (openPrice - currentPrice) / atr;

    if(profitATR >= InpBreakevenATR)  // Start trailing after breakeven level
    {
        double newSL = (posType == POSITION_TYPE_BUY) ?
                       currentPrice - (InpTrailingATR * atr) :
                       currentPrice + (InpTrailingATR * atr);

        bool shouldModify = false;

        if(posType == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            shouldModify = true;
        else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            shouldModify = true;

        if(shouldModify)
        {
            if(g_trade.ModifyPosition(ticket, newSL, currentTP))
            {
                Print("Trailing stop updated for position ", ticket, " to ", newSL);
            }
        }
    }
}
//+------------------------------------------------------------------+
