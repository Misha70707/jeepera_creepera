//+------------------------------------------------------------------+
//|                                                  EA_Template.mq5 |
//|                        Production-Ready Expert Advisor Template |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict

//--- Include custom libraries
#include <Common/TradeManager.mqh>
#include <Common/RiskManager.mqh>
#include <Common/ErrorHandling.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Strategy Parameters ==="
input int      InpMagicNumber    = 12345;        // Magic Number
input string   InpTradeComment   = "EA_Template"; // Trade Comment

input group "=== Risk Management ==="
input double   InpRiskPercent    = 1.0;          // Risk Per Trade (%)
input double   InpMaxLotSize     = 10.0;         // Maximum Lot Size
input double   InpMinLotSize     = 0.01;         // Minimum Lot Size
input int      InpStopLoss       = 100;          // Stop Loss (points)
input int      InpTakeProfit     = 200;          // Take Profit (points)

input group "=== Trade Management ==="
input bool     InpUseBreakeven   = true;         // Use Breakeven
input int      InpBreakevenPoints = 50;          // Breakeven Activation (points)
input bool     InpUseTrailing    = true;         // Use Trailing Stop
input int      InpTrailingStart  = 100;          // Trailing Start (points)
input int      InpTrailingStep   = 50;           // Trailing Step (points)

input group "=== Time Filter ==="
input bool     InpUseTimeFilter  = false;        // Use Time Filter
input int      InpStartHour      = 0;            // Start Hour
input int      InpEndHour        = 23;           // End Hour

input group "=== Strategy Specific ==="
input int      InpMAPeriod       = 20;           // MA Period (example)
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT; // Timeframe

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTradeManager  g_trade;
CRiskManager   g_risk;
CErrorHandler  g_error;

datetime       g_lastBarTime = 0;
int            g_maHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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

    //--- Validate inputs
    if(InpStopLoss <= 0 || InpTakeProfit <= 0)
    {
        Print("ERROR: Stop Loss and Take Profit must be positive");
        return INIT_PARAMETERS_INCORRECT;
    }

    if(InpRiskPercent <= 0 || InpRiskPercent > 100)
    {
        Print("ERROR: Risk percent must be between 0 and 100");
        return INIT_PARAMETERS_INCORRECT;
    }

    //--- Initialize indicators
    g_maHandle = iMA(_Symbol, InpTimeframe, InpMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    if(g_maHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create MA indicator");
        return INIT_FAILED;
    }

    //--- Check for sufficient historical data
    int bars = Bars(_Symbol, InpTimeframe);
    if(bars < InpMAPeriod + 10)
    {
        Print("WARNING: Insufficient historical data. Need at least ", InpMAPeriod + 10, " bars");
        return INIT_FAILED;
    }

    Print("EA initialized successfully on ", _Symbol, " ", EnumToString(InpTimeframe));
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicator handles
    if(g_maHandle != INVALID_HANDLE)
    {
        IndicatorRelease(g_maHandle);
        g_maHandle = INVALID_HANDLE;
    }

    //--- Cleanup
    g_trade.Deinit();

    Print("EA deinitialized. Reason: ", g_error.GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check if new bar formed (OnBar logic)
    if(!IsNewBar())
        return;

    //--- Apply time filter
    if(InpUseTimeFilter && !IsTradeTimeAllowed())
        return;

    //--- Update trailing stops and breakeven for existing positions
    ManageOpenPositions();

    //--- Check trade conditions
    int signal = GetTradeSignal();

    if(signal == 0)
        return; // No signal

    //--- Check if we already have a position
    if(g_trade.HasPosition(_Symbol))
        return;

    //--- Calculate lot size
    double lotSize = g_risk.CalculateLotSize(_Symbol, InpStopLoss);
    if(lotSize <= 0)
    {
        Print("ERROR: Invalid lot size calculated");
        return;
    }

    //--- Execute trade
    if(signal > 0) // BUY signal
    {
        double sl = g_trade.CalculateSL(_Symbol, ORDER_TYPE_BUY, InpStopLoss);
        double tp = g_trade.CalculateTP(_Symbol, ORDER_TYPE_BUY, InpTakeProfit);

        if(!g_trade.Buy(_Symbol, lotSize, sl, tp))
        {
            Print("ERROR: Buy order failed - ", g_error.GetLastErrorText());
        }
    }
    else if(signal < 0) // SELL signal
    {
        double sl = g_trade.CalculateSL(_Symbol, ORDER_TYPE_SELL, InpStopLoss);
        double tp = g_trade.CalculateTP(_Symbol, ORDER_TYPE_SELL, InpTakeProfit);

        if(!g_trade.Sell(_Symbol, lotSize, sl, tp))
        {
            Print("ERROR: Sell order failed - ", g_error.GetLastErrorText());
        }
    }
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);

    if(currentBarTime == g_lastBarTime)
        return false;

    g_lastBarTime = currentBarTime;
    return true;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on time filter                |
//+------------------------------------------------------------------+
bool IsTradeTimeAllowed()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);

    if(InpStartHour < InpEndHour)
    {
        // Normal range (e.g., 9:00 - 17:00)
        return (time.hour >= InpStartHour && time.hour < InpEndHour);
    }
    else if(InpStartHour > InpEndHour)
    {
        // Overnight range (e.g., 22:00 - 06:00)
        return (time.hour >= InpStartHour || time.hour < InpEndHour);
    }

    return true; // If start == end, allow all times
}

//+------------------------------------------------------------------+
//| Get trade signal                                                 |
//| Returns: 1 = BUY, -1 = SELL, 0 = NO SIGNAL                     |
//+------------------------------------------------------------------+
int GetTradeSignal()
{
    //--- Get indicator values
    double ma[];
    ArraySetAsSeries(ma, true);

    if(CopyBuffer(g_maHandle, 0, 0, 3, ma) != 3)
    {
        Print("ERROR: Failed to copy MA buffer");
        return 0;
    }

    //--- Get price data
    double close[];
    ArraySetAsSeries(close, true);

    if(CopyClose(_Symbol, InpTimeframe, 0, 3, close) != 3)
    {
        Print("ERROR: Failed to copy price data");
        return 0;
    }

    //--- Example strategy logic: Simple MA crossover
    // BUY: Price crosses above MA
    if(close[2] <= ma[2] && close[1] > ma[1])
        return 1;

    // SELL: Price crosses below MA
    if(close[2] >= ma[2] && close[1] < ma[1])
        return -1;

    return 0; // No signal
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, breakeven, etc.)          |
//+------------------------------------------------------------------+
void ManageOpenPositions()
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
    double currentPrice = (posType == POSITION_TYPE_BUY) ?
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    //--- Apply breakeven
    if(InpUseBreakeven)
    {
        double profitPoints = (posType == POSITION_TYPE_BUY) ?
                              (currentPrice - openPrice) / point :
                              (openPrice - currentPrice) / point;

        if(profitPoints >= InpBreakevenPoints)
        {
            double newSL = openPrice;

            // Only move SL if it's better than current
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            {
                g_trade.ModifyPosition(ticket, newSL, 0);
            }
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            {
                g_trade.ModifyPosition(ticket, newSL, 0);
            }
        }
    }

    //--- Apply trailing stop
    if(InpUseTrailing)
    {
        double profitPoints = (posType == POSITION_TYPE_BUY) ?
                              (currentPrice - openPrice) / point :
                              (openPrice - currentPrice) / point;

        if(profitPoints >= InpTrailingStart)
        {
            double newSL = (posType == POSITION_TYPE_BUY) ?
                           currentPrice - InpTrailingStep * point :
                           currentPrice + InpTrailingStep * point;

            // Only move SL if it's better than current
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            {
                g_trade.ModifyPosition(ticket, newSL, 0);
            }
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            {
                g_trade.ModifyPosition(ticket, newSL, 0);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| OnTrade event handler                                            |
//+------------------------------------------------------------------+
void OnTrade()
{
    // Handle trade events if needed
    // Useful for logging, notifications, etc.
}

//+------------------------------------------------------------------+
//| OnTimer event handler (if needed)                                |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Periodic tasks can be implemented here
    // EventSetTimer() must be called in OnInit() to enable this
}
//+------------------------------------------------------------------+
