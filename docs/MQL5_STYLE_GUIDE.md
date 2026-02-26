# MQL5 Coding Style Guide

This guide establishes coding standards and best practices for MQL5 development in this project.

## Table of Contents
- [Naming Conventions](#naming-conventions)
- [File Organization](#file-organization)
- [Code Structure](#code-structure)
- [Comments and Documentation](#comments-and-documentation)
- [Best Practices](#best-practices)

---

## Naming Conventions

### Variables

**Global Variables:**
```mql5
int g_magicNumber = 12345;        // Prefix with g_
string g_tradeComment = "MyEA";   // camelCase after prefix
```

**Input Parameters:**
```mql5
input int      InpStopLoss = 100;      // Prefix with Inp
input double   InpRiskPercent = 1.0;   // PascalCase after prefix
input bool     InpUseTrailing = true;
```

**Local Variables:**
```mql5
int bars = Bars(_Symbol, PERIOD_CURRENT);     // camelCase
double lotSize = 0.01;
datetime currentTime = TimeCurrent();
```

**Member Variables (class private):**
```mql5
class CTradeManager {
private:
    int    m_magicNumber;      // Prefix with m_
    string m_comment;          // camelCase after prefix
    double m_slippage;
};
```

### Functions and Methods

```mql5
// PascalCase for functions
int CalculateLotSize(string symbol, int stopLoss)
{
    // ...
}

// Clear, descriptive names
bool IsNewBarFormed()
{
    // ...
}

// Getters
double GetPositionProfit() { return m_profit; }

// Setters
void SetRiskPercent(double percent) { m_riskPercent = percent; }
```

### Classes

```mql5
// Prefix with C, then PascalCase
class CTradeManager { };
class CRiskCalculator { };
class CNeuralNetwork { };
```

### Constants and Enums

```mql5
// UPPER_CASE with underscores
#define MAX_RETRIES 3
#define DEFAULT_SLIPPAGE 10

// Enum names: PascalCase
// Enum values: UPPER_CASE with prefix
enum MARKET_REGIME {
    REGIME_TRENDING_UP,
    REGIME_TRENDING_DOWN,
    REGIME_RANGING
};
```

---

## File Organization

### File Headers

Every file must start with a standard header:

```mql5
//+------------------------------------------------------------------+
//|                                                    MyExpert.mq5 |
//|                                 Brief description of the file   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YourName"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict
```

### Include Order

```mql5
// 1. Standard MT5 libraries
#include <Trade/Trade.mqh>
#include <Arrays/ArrayObj.mqh>

// 2. Custom common libraries
#include <Common/TradeManager.mqh>
#include <Common/RiskManager.mqh>

// 3. Specific libraries
#include <NeuralNetwork/NNBase.mqh>
```

### Section Organization

Organize code into clear sections:

```mql5
//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input int InpMagicNumber = 12345;

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTradeManager g_trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // ...
}
```

---

## Code Structure

### Indentation and Spacing

- **Indentation:** 4 spaces (no tabs)
- **Line length:** Max 120 characters
- **Blank lines:** One blank line between functions

```mql5
// GOOD
if(condition)
{
    DoSomething();
    DoSomethingElse();
}

// BAD - no braces for single line (always use braces)
if(condition)
    DoSomething();
```

### Braces

Always use braces, even for single statements:

```mql5
// GOOD
if(IsNewBar())
{
    CheckSignal();
}

// BAD
if(IsNewBar())
    CheckSignal();
```

Brace placement - opening brace on same line for short statements, new line for functions:

```mql5
// Functions - new line
int OnInit()
{
    // ...
}

// Control structures - same line is acceptable
if(condition) {
    // ...
}

// But prefer new line for consistency
if(condition)
{
    // ...
}
```

### Function Length

- Keep functions under 50 lines
- If longer, break into smaller functions
- Each function should do ONE thing

```mql5
// GOOD - Single responsibility
bool IsNewBarFormed()
{
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBar == g_lastBarTime)
        return false;

    g_lastBarTime = currentBar;
    return true;
}

// Then use it
void OnTick()
{
    if(!IsNewBarFormed())
        return;

    ProcessSignal();
}
```

---

## Comments and Documentation

### File-Level Comments

```mql5
//+------------------------------------------------------------------+
//| TradeManager.mqh                                                 |
//| Handles all trade execution with error handling and retries     |
//|                                                                  |
//| Key Features:                                                    |
//| - Automatic retry on retriable errors                           |
//| - Position and order management                                 |
//| - SL/TP calculation helpers                                     |
//+------------------------------------------------------------------+
```

### Function Documentation

```mql5
//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//|                                                                   |
//| Parameters:                                                       |
//|   symbol         - Trading symbol                                |
//|   stopLossPoints - Stop loss distance in points                  |
//|                                                                   |
//| Returns:                                                          |
//|   Normalized lot size, or 0 on error                             |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, int stopLossPoints)
{
    // ...
}
```

### Inline Comments

```mql5
// GOOD - Explain WHY, not WHAT
// Use EMA instead of SMA for faster response to price changes
double ema = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);

// BAD - Obvious comment
// Get the moving average
double ma = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
```

### TODO Comments

```mql5
// TODO: Implement partial position close
// FIXME: Handle requote errors properly
// NOTE: This assumes positive correlation between symbols
```

---

## Best Practices

### Error Handling

**Always check return values:**

```mql5
// GOOD
int handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
if(handle == INVALID_HANDLE)
{
    Print("ERROR: Failed to create MA indicator");
    return INIT_FAILED;
}

// GOOD - Check trade results
if(!trade.Buy(symbol, lot, sl, tp))
{
    int error = GetLastError();
    Print("Buy failed: ", ErrorDescription(error));
    return;
}
```

### Array Handling

**Always use ArraySetAsSeries for time series:**

```mql5
// GOOD
double close[];
ArraySetAsSeries(close, true);  // Most recent at index 0
CopyClose(_Symbol, PERIOD_CURRENT, 0, 100, close);

// Access: close[0] = most recent, close[1] = previous bar
```

**Pre-allocate arrays when size is known:**

```mql5
// GOOD
double buffer[];
ArrayResize(buffer, 1000);      // Pre-allocate
ArrayInitialize(buffer, 0.0);   // Initialize

// BAD - repeated resizing
for(int i = 0; i < 1000; i++)
{
    ArrayResize(buffer, i + 1);  // Slow!
}
```

### Resource Management

**Always release resources:**

```mql5
int maHandle = INVALID_HANDLE;

int OnInit()
{
    maHandle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    // CRITICAL: Release indicator handle
    if(maHandle != INVALID_HANDLE)
    {
        IndicatorRelease(maHandle);
        maHandle = INVALID_HANDLE;
    }
}
```

### Performance Optimization

**Cache repeated calculations:**

```mql5
// GOOD
void OnTick()
{
    static double lastAsk = 0;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    if(ask == lastAsk)
        return;  // Price hasn't changed

    lastAsk = ask;
    ProcessTick();
}

// BAD - recalculating every tick
void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    // ... same calculation every tick
}
```

**Process only on new bar:**

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

    // Heavy calculations only on new bar
    CalculateStrategy();
}
```

### Input Validation

**Validate all inputs in OnInit():**

```mql5
int OnInit()
{
    // Validate numeric ranges
    if(InpRiskPercent <= 0 || InpRiskPercent > 10)
    {
        Print("ERROR: Risk percent must be between 0 and 10");
        return INIT_PARAMETERS_INCORRECT;
    }

    // Validate symbol
    if(!SymbolInfoInteger(InpTradingSymbol, SYMBOL_SELECT))
    {
        Print("ERROR: Symbol ", InpTradingSymbol, " not found");
        return INIT_FAILED;
    }

    // Validate dependencies
    if(InpUseTrailing && InpStopLoss <= 0)
    {
        Print("ERROR: Trailing stop requires valid stop loss");
        return INIT_PARAMETERS_INCORRECT;
    }

    return INIT_SUCCEEDED;
}
```

### Magic Number Usage

**Use unique magic numbers:**

```mql5
// GOOD - Unique magic per strategy/symbol/timeframe
#define MAGIC_BASE 10000
input int InpMagicNumber = MAGIC_BASE + 1;  // 10001

// Or generate programmatically
int GenerateMagicNumber()
{
    int magic = MAGIC_BASE;
    magic += PeriodSeconds(PERIOD_CURRENT) / 60;  // Add timeframe
    magic += StringToInteger(_Symbol);             // Add symbol hash
    return magic;
}
```

### Avoid Common Pitfalls

**1. Don't use index 0 for confirmed signals:**

```mql5
// BAD - Current forming bar (repaints!)
if(iClose(_Symbol, PERIOD_CURRENT, 0) > iMA(..., 0))
    OpenTrade();

// GOOD - Use confirmed closed bar
if(iClose(_Symbol, PERIOD_CURRENT, 1) > iMA(..., 1))
    OpenTrade();
```

**2. Normalize prices and lots:**

```mql5
// GOOD
double NormalizeLot(string symbol, double lot)
{
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    return NormalizeDouble(MathFloor(lot / lotStep) * lotStep, 2);
}

double NormalizePrice(string symbol, double price)
{
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    return NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
}
```

**3. Check for sufficient bars:**

```mql5
int OnInit()
{
    int requiredBars = InpMAPeriod + 10;
    int availableBars = Bars(_Symbol, PERIOD_CURRENT);

    if(availableBars < requiredBars)
    {
        Print("WARNING: Insufficient bars. Need ", requiredBars, ", have ", availableBars);
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}
```

---

## Security Considerations

1. **Never hardcode credentials**
2. **Validate all external inputs**
3. **Use appropriate file permissions**
4. **Log security-relevant events**
5. **Implement rate limiting for external calls**

---

## Version Control

- Commit messages should be clear and descriptive
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Update `#property version` in code when releasing

---

## Additional Resources

- [MQL5 Documentation](https://www.mql5.com/en/docs)
- [MQL5 Code Base](https://www.mql5.com/en/code)
- See COMMON_PATTERNS.md for frequently used code patterns

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
