# MQL5 Common Patterns

Frequently used code patterns for MQL5 development. Copy and adapt these patterns for your EAs.

## Table of Contents
- [Initialization Patterns](#initialization-patterns)
- [New Bar Detection](#new-bar-detection)
- [Indicator Usage](#indicator-usage)
- [Trading Patterns](#trading-patterns)
- [Position Management](#position-management)
- [Data Access Patterns](#data-access-patterns)
- [Time Management](#time-management)

---

## Initialization Patterns

### Basic EA Initialization

```mql5
int OnInit()
{
    // 1. Validate inputs
    if(InpStopLoss <= 0 || InpTakeProfit <= 0)
    {
        Print("ERROR: Invalid SL/TP parameters");
        return INIT_PARAMETERS_INCORRECT;
    }

    // 2. Initialize indicators
    g_maHandle = iMA(_Symbol, PERIOD_CURRENT, InpMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    if(g_maHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create MA indicator");
        return INIT_FAILED;
    }

    // 3. Check for sufficient historical data
    if(Bars(_Symbol, PERIOD_CURRENT) < InpMAPeriod + 10)
    {
        Print("ERROR: Insufficient historical data");
        return INIT_FAILED;
    }

    // 4. Initialize custom classes
    if(!g_trade.Init(InpMagicNumber, "MyEA"))
    {
        Print("ERROR: Failed to initialize trade manager");
        return INIT_FAILED;
    }

    Print("EA initialized successfully");
    return INIT_SUCCEEDED;
}
```

### Proper Deinitialization

```mql5
void OnDeinit(const int reason)
{
    // 1. Release indicator handles
    if(g_maHandle != INVALID_HANDLE)
    {
        IndicatorRelease(g_maHandle);
        g_maHandle = INVALID_HANDLE;
    }

    // 2. Clean up objects
    if(g_neuralNet != NULL)
    {
        delete g_neuralNet;
        g_neuralNet = NULL;
    }

    // 3. Save state if needed
    SaveEAState();

    // 4. Log deinit reason
    Print("EA stopped. Reason: ", GetDeinitReasonText(reason));
}
```

---

## New Bar Detection

### Method 1: Simple Time Comparison

```mql5
bool IsNewBar()
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

    if(currentBarTime == lastBarTime)
        return false;

    lastBarTime = currentBarTime;
    return true;
}

void OnTick()
{
    if(!IsNewBar())
        return;

    // Execute only on new bar
    ProcessStrategy();
}
```

### Method 2: Multi-Timeframe

```mql5
class CBarTimer
{
private:
    datetime m_lastBarTime[];

public:
    CBarTimer()
    {
        ArrayResize(m_lastBarTime, 21);  // ENUM_TIMEFRAMES count
        ArrayInitialize(m_lastBarTime, 0);
    }

    bool IsNewBar(ENUM_TIMEFRAMES timeframe)
    {
        datetime currentTime = iTime(_Symbol, timeframe, 0);
        int idx = (int)timeframe;

        if(currentTime == m_lastBarTime[idx])
            return false;

        m_lastBarTime[idx] = currentTime;
        return true;
    }
};

CBarTimer g_barTimer;

void OnTick()
{
    if(g_barTimer.IsNewBar(PERIOD_H1))
    {
        // H1 strategy logic
    }

    if(g_barTimer.IsNewBar(PERIOD_M15))
    {
        // M15 strategy logic
    }
}
```

---

## Indicator Usage

### Single Indicator Value

```mql5
double GetMAValue(int shift)
{
    double buffer[];
    ArraySetAsSeries(buffer, true);

    if(CopyBuffer(g_maHandle, 0, shift, 1, buffer) != 1)
    {
        Print("ERROR: Failed to copy MA buffer");
        return 0;
    }

    return buffer[0];
}
```

### Multiple Values with Validation

```mql5
bool GetIndicatorValues(double &ma[], double &rsi[], int count)
{
    ArraySetAsSeries(ma, true);
    ArraySetAsSeries(rsi, true);

    // Copy MA
    if(CopyBuffer(g_maHandle, 0, 0, count, ma) != count)
    {
        Print("ERROR: Failed to copy MA buffer");
        return false;
    }

    // Copy RSI
    if(CopyBuffer(g_rsiHandle, 0, 0, count, rsi) != count)
    {
        Print("ERROR: Failed to copy RSI buffer");
        return false;
    }

    return true;
}

void OnTick()
{
    double ma[3], rsi[3];

    if(!GetIndicatorValues(ma, rsi, 3))
        return;

    // Use values
    if(rsi[1] < 30 && ma[1] > ma[2])
    {
        // Buy signal
    }
}
```

### Custom Indicator

```mql5
// Initialize custom indicator
int g_customHandle = INVALID_HANDLE;

int OnInit()
{
    g_customHandle = iCustom(_Symbol, PERIOD_CURRENT,
                             "MyIndicator",      // Indicator name
                             14,                 // Parameter 1
                             30, 70);           // Parameter 2, 3

    if(g_customHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to load custom indicator");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}
```

---

## Trading Patterns

### Opening Position with Validation

```mql5
bool OpenBuyPosition()
{
    // 1. Check if trading is allowed
    if(!IsTradeAllowed())
        return false;

    // 2. Check if position already exists
    if(PositionSelect(_Symbol))
    {
        Print("Position already open for ", _Symbol);
        return false;
    }

    // 3. Calculate lot size
    double lot = g_risk.CalculateLotSize(_Symbol, InpStopLoss);
    if(lot <= 0)
    {
        Print("ERROR: Invalid lot size");
        return false;
    }

    // 4. Calculate SL/TP
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double sl = ask - InpStopLoss * point;
    double tp = ask + InpTakeProfit * point;

    // 5. Execute trade
    if(!g_trade.Buy(_Symbol, lot, sl, tp))
    {
        Print("ERROR: Buy order failed - ", g_error.GetLastErrorText());
        return false;
    }

    Print("BUY order opened: Lot=", lot, " SL=", sl, " TP=", tp);
    return true;
}
```

### Closing Positions

```mql5
// Close specific position
bool ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return false;

    if(!g_trade.PositionClose(ticket))
    {
        Print("ERROR: Failed to close position ", ticket);
        return false;
    }

    Print("Position ", ticket, " closed successfully");
    return true;
}

// Close all positions for symbol
void CloseAllPositions(string symbol)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != symbol) continue;

        ClosePosition(ticket);
    }
}
```

---

## Position Management

### Breakeven Implementation

```mql5
void MoveToBreakeven(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return;

    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    // Calculate current profit in points
    double currentPrice = (type == POSITION_TYPE_BUY) ?
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double profitPoints = MathAbs(currentPrice - openPrice) / point;

    // Check if profit reached breakeven threshold
    if(profitPoints >= InpBreakevenPoints)
    {
        double newSL = openPrice;

        // Only move SL if it's better than current
        bool shouldModify = false;

        if(type == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            shouldModify = true;
        else if(type == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            shouldModify = true;

        if(shouldModify)
        {
            double tp = PositionGetDouble(POSITION_TP);
            if(g_trade.PositionModify(ticket, newSL, tp))
            {
                Print("Breakeven set for position ", ticket);
            }
        }
    }
}
```

### Trailing Stop

```mql5
void TrailPosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return;

    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    double currentPrice = (type == POSITION_TYPE_BUY) ?
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // Calculate profit in points
    double profitPoints = (type == POSITION_TYPE_BUY) ?
                          (currentPrice - openPrice) / point :
                          (openPrice - currentPrice) / point;

    // Only trail if minimum profit reached
    if(profitPoints >= InpTrailingStart)
    {
        double newSL = (type == POSITION_TYPE_BUY) ?
                       currentPrice - InpTrailingDistance * point :
                       currentPrice + InpTrailingDistance * point;

        bool shouldModify = false;

        if(type == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL))
            shouldModify = true;
        else if(type == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL))
            shouldModify = true;

        if(shouldModify)
        {
            double tp = PositionGetDouble(POSITION_TP);
            g_trade.PositionModify(ticket, newSL, tp);
        }
    }
}
```

---

## Data Access Patterns

### Getting Price Data

```mql5
bool GetPriceData(MqlRates &rates[], int count)
{
    ArraySetAsSeries(rates, true);

    int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, count, rates);
    if(copied != count)
    {
        Print("ERROR: Failed to copy price data. Requested=", count, " Copied=", copied);
        return false;
    }

    return true;
}

void OnTick()
{
    MqlRates rates[10];

    if(!GetPriceData(rates, 10))
        return;

    // Access data
    double currentClose = rates[0].close;
    double previousClose = rates[1].close;
    double highestHigh = rates[ArrayMaximum(rates, 0, 10)].high;
}
```

### Getting Tick Data

```mql5
bool GetLastTicks(MqlTick &ticks[], int count)
{
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, count);
    if(copied != count)
    {
        Print("ERROR: Failed to copy ticks");
        return false;
    }

    return true;
}

void OnTick()
{
    MqlTick ticks[100];

    if(!GetLastTicks(ticks, 100))
        return;

    // Analyze tick data
    for(int i = 0; i < 100; i++)
    {
        double spread = (ticks[i].ask - ticks[i].bid) / _Point;
        // Process tick
    }
}
```

---

## Time Management

### Time Filter

```mql5
bool IsWithinTradingHours()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);

    // Example: Trade only between 9:00 and 17:00
    if(time.hour < 9 || time.hour >= 17)
        return false;

    // Avoid weekends
    if(time.day_of_week == 0 || time.day_of_week == 6)
        return false;

    return true;
}

void OnTick()
{
    if(!IsWithinTradingHours())
        return;

    ProcessStrategy();
}
```

### Time Range Check

```mql5
bool IsInTimeRange(int startHour, int startMin, int endHour, int endMin)
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);

    int currentMinutes = time.hour * 60 + time.min;
    int startMinutes = startHour * 60 + startMin;
    int endMinutes = endHour * 60 + endMin;

    if(startMinutes < endMinutes)
    {
        // Normal range (e.g., 09:00 - 17:00)
        return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
    }
    else
    {
        // Overnight range (e.g., 22:00 - 06:00)
        return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
    }
}
```

### Day of Week Filter

```mql5
bool IsTradingDay()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);

    // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    switch(time.day_of_week)
    {
        case 0:  // Sunday
        case 6:  // Saturday
            return false;

        case 1:  // Monday - avoid early hours
            if(time.hour < 2)
                return false;
            break;

        case 5:  // Friday - avoid late hours
            if(time.hour >= 21)
                return false;
            break;
    }

    return true;
}
```

---

## Error Handling Patterns

### Retry Pattern

```mql5
bool ExecuteWithRetry(int maxRetries = 3)
{
    for(int attempt = 0; attempt < maxRetries; attempt++)
    {
        if(g_trade.Buy(_Symbol, lot, sl, tp))
            return true;

        int error = GetLastError();

        // Check if error is retriable
        if(!IsRetriableError(error))
        {
            Print("Non-retriable error: ", error);
            return false;
        }

        // Wait before retry (exponential backoff)
        int delayMs = (int)MathPow(2, attempt) * 100;
        Sleep(delayMs);

        Print("Retry attempt ", attempt + 1, " after ", delayMs, "ms");
    }

    Print("ERROR: All retry attempts failed");
    return false;
}
```

### Safe Division

```mql5
double SafeDivide(double numerator, double denominator, double defaultValue = 0)
{
    if(MathAbs(denominator) < 0.0000001)  // Avoid division by zero
        return defaultValue;

    return numerator / denominator;
}
```

---

## Utility Patterns

### Symbol Information

```mql5
void PrintSymbolInfo(string symbol)
{
    Print("=== Symbol Info: ", symbol, " ===");
    Print("Digits: ", SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    Print("Point: ", SymbolInfoDouble(symbol, SYMBOL_POINT));
    Print("Spread: ", SymbolInfoInteger(symbol, SYMBOL_SPREAD));
    Print("Min Lot: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
    Print("Max Lot: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
    Print("Lot Step: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
    Print("Tick Value: ", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE));
    Print("Tick Size: ", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));
}
```

### Account Information

```mql5
void PrintAccountInfo()
{
    Print("=== Account Info ===");
    Print("Balance: ", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("Equity: ", AccountInfoDouble(ACCOUNT_EQUITY));
    Print("Margin: ", AccountInfoDouble(ACCOUNT_MARGIN));
    Print("Free Margin: ", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
    Print("Margin Level: ", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), "%");
    Print("Profit: ", AccountInfoDouble(ACCOUNT_PROFIT));
}
```

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
