# ORB Professional EA - Production-Ready Opening Range Breakout

A **properly implemented** Opening Range Breakout Expert Advisor with enterprise-grade risk management and position control.

## What This EA Does

The Opening Range Breakout (ORB) strategy:
1. Identifies the high/low range during the first N minutes of a trading session
2. Waits for price to break above/below this range
3. Enters a trade in the breakout direction
4. Uses ATR-based dynamic stop loss and take profit

## What Was Fixed from the Bad Version

### Critical Fixes ✓

**1. Correct MQL5 API Usage**
```mql5
// BAD (Old EA) - Won't work!
atr_value = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);

// GOOD (This EA) - Proper implementation
g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);  // Create handle in OnInit
double atr_buffer[];
CopyBuffer(g_atrHandle, 0, 0, 1, atr_buffer);  // Get value in OnTick
double atr = atr_buffer[0];
```

**2. Proper ORB Session Management**
```mql5
// BAD: ORB calculated once, never reset
orb_calculated = true;  // Stays true forever!

// GOOD: Daily reset with session tracking
CheckNewDay();  // Resets all ORB sessions each day
```

**3. Fixed Position Sizing**
```mql5
// BAD: Martingale-style (account killer)
lot_size increases with balance

// GOOD: Fixed risk percentage
lot = g_risk.CalculateLotSize(_Symbol, stopLossPoints);  // Always 1% risk
```

**4. Proper Resource Management**
```mql5
void OnDeinit(const int reason)
{
    if(g_atrHandle != INVALID_HANDLE)
    {
        IndicatorRelease(g_atrHandle);  // Release indicators
        g_atrHandle = INVALID_HANDLE;
    }
}
```

**5. Daily Risk Limits**
```mql5
if(!g_risk.IsTradeAllowed())  // Checks daily loss and drawdown
    return;
```

**6. Multi-Session Support**
- London session (8:00 server time)
- New York session (14:00 server time = 9:00 EST on GMT+5)
- Asia session (0:00 server time)
- Each session tracked independently

---

## Features

### Risk Management
- ✓ Fixed risk percentage per trade (default 1%)
- ✓ Daily loss limit (default 3%)
- ✓ Maximum drawdown limit (default 10%)
- ✓ Position sizing based on ATR and account balance
- ✓ Automatic lot size normalization

### Position Management
- ✓ ATR-based dynamic SL/TP (adapts to volatility)
- ✓ Breakeven mode (moves SL to entry after 1x ATR profit)
- ✓ Trailing stop (trails by 1x ATR distance)
- ✓ One position per session maximum

### Filters
- ✓ Spread filter (avoid high spread periods)
- ✓ Minimum ATR filter (avoid low volatility)
- ✓ Trend filter using ADX (optional)
- ✓ Breakout buffer (avoids false breakouts)

### Safety Features
- ✓ Input validation on startup
- ✓ Error handling with retry logic
- ✓ Resource cleanup on shutdown
- ✓ Detailed logging

---

## Input Parameters

### Strategy Parameters
- **InpMagicNumber:** Unique identifier (default: 20241115)
- **InpTradeComment:** Comment for trades (default: "ORB_Pro")
- **InpORBMinutes:** ORB calculation period in minutes (default: 30)
- **InpBreakoutBuffer:** Buffer in points to confirm breakout (default: 5)

### Risk Management
- **InpRiskPercent:** Risk per trade as % of balance (default: 1.0%)
- **InpMaxLotSize:** Maximum allowed lot size (default: 10.0)
- **InpMinLotSize:** Minimum allowed lot size (default: 0.01)
- **InpMaxDailyLoss:** Maximum daily loss in % (default: 3.0%)
- **InpMaxDrawdown:** Maximum drawdown in % (default: 10.0%)

### Position Management
- **InpStopLossATR:** Stop loss as ATR multiplier (default: 2)
- **InpTakeProfitATR:** Take profit as ATR multiplier (default: 3)
- **InpUseBreakeven:** Enable breakeven (default: true)
- **InpBreakevenATR:** Move to breakeven at N x ATR profit (default: 1)
- **InpUseTrailing:** Enable trailing stop (default: true)
- **InpTrailingATR:** Trailing distance as ATR multiplier (default: 1)

### Session Times
- **InpTradeLondon:** Trade London session (default: true)
- **InpLondonOpen:** London open hour in server time (default: 8)
- **InpTradeNewYork:** Trade New York session (default: true)
- **InpNewYorkOpen:** NY open hour in server time (default: 14)
- **InpTradeAsia:** Trade Asia session (default: false)
- **InpAsiaOpen:** Asia open hour in server time (default: 0)

### Filters
- **InpATRPeriod:** ATR calculation period (default: 14)
- **InpMinATR:** Minimum ATR to trade (0 = disabled)
- **InpMaxSpread:** Maximum spread in points (default: 50, 0 = disabled)
- **InpOnlyTrending:** Only trade when trending (default: false)
- **InpADXPeriod:** ADX period (default: 14)
- **InpMinADX:** Minimum ADX for trending (default: 20)

---

## How to Use

### 1. Configure Session Times

**IMPORTANT:** Session times are in **server time**, not your local time!

Check your broker's server time:
- Most US brokers: GMT-5 or GMT-4
- Most EU brokers: GMT+2 or GMT+3

**Example for GMT+2 broker:**
- London 9:00 AM GMT = 11:00 server time → Set `InpLondonOpen = 11`
- NY 9:30 AM EST (14:30 GMT) = 16:30 server time → Set `InpNewYorkOpen = 16`

**How to find your broker's offset:**
```mql5
// In MT5 Terminal:
MqlDateTime dt;
TimeToStruct(TimeCurrent(), dt);
Print("Current server time: ", TimeToString(TimeCurrent()));
Print("Current GMT time: ", TimeToString(TimeGMT()));
// Calculate the difference
```

### 2. Adjust Risk Settings

**Conservative (Recommended):**
```
InpRiskPercent = 0.5%
InpMaxDailyLoss = 2%
InpMaxDrawdown = 10%
```

**Moderate:**
```
InpRiskPercent = 1%
InpMaxDailyLoss = 3%
InpMaxDrawdown = 15%
```

**Aggressive (Not Recommended):**
```
InpRiskPercent = 2%
InpMaxDailyLoss = 5%
InpMaxDrawdown = 20%
```

### 3. Enable Appropriate Sessions

**For XAUUSD (Gold):**
- Enable London (high volatility)
- Enable New York (high volatility)
- Disable Asia (low liquidity)

**For EURUSD:**
- Enable London (high liquidity)
- Enable New York (high liquidity)
- Disable Asia

**For USDJPY:**
- Enable all sessions (24h market)

### 4. Set Filters

**High Spread Symbols (Gold, Exotic Pairs):**
```
InpMaxSpread = 100  // points
```

**Low Spread Symbols (EURUSD, GBPUSD):**
```
InpMaxSpread = 20  // points
```

**Trending Markets Only:**
```
InpOnlyTrending = true
InpMinADX = 25
```

---

## Backtest Settings

### Recommended Strategy Tester Settings

**Period:** Minimum 6 months (preferably 1+ year)
**Timeframe:** Any (EA works on tick data)
**Mode:** Every tick based on real ticks
**Spread:** Current or average (avoid "fixed")
**Optimization:** Use genetic algorithm with forward testing

### Realistic Expectations

**Good ORB EA Performance:**
- Win rate: 45-60% (NOT 96%!)
- Average R:R: 1:1.5 to 1:2
- Monthly return: 3-8%
- Maximum drawdown: 10-20%
- Trades per month: 10-40 (depending on sessions)

**Red Flags in Backtest:**
- Win rate > 80% → Overfitted
- Profit factor > 3.0 → Curve fitted
- Consistent win streaks > 10 trades → Not realistic
- Increasing lot sizes → Martingale (dangerous!)

---

## Comparison: Bad EA vs. This EA

| Feature | Bad EA | ORB Professional |
|---------|--------|------------------|
| **API Usage** | ❌ Broken | ✓ Correct |
| **ORB Reset** | ❌ Never resets | ✓ Daily reset |
| **Position Sizing** | ❌ Martingale | ✓ Fixed % risk |
| **Risk Controls** | ❌ None | ✓ Daily loss, drawdown limits |
| **Error Handling** | ❌ None | ✓ Comprehensive |
| **Resource Management** | ❌ Memory leaks | ✓ Proper cleanup |
| **Multi-Session** | ❌ Hardcoded | ✓ Configurable |
| **Position Management** | ❌ None | ✓ Breakeven, trailing |
| **Filters** | ❌ None | ✓ Spread, ATR, ADX |
| **Production Ready** | ❌ No | ✓ Yes |

---

## Known Limitations

1. **One Position Per Symbol:** Only one active position at a time
2. **M1 Data Required:** Needs M1 historical data for ORB calculation
3. **Server Time Dependent:** Session times must be adjusted for broker
4. **No ML Integration Yet:** LSTM mentioned in original but not implemented (can be added later)

---

## Future Enhancements (Optional)

### Phase 1: Statistics & Monitoring
- [ ] Trade journal export
- [ ] Performance dashboard
- [ ] Email/Telegram notifications

### Phase 2: Advanced Features
- [ ] Multiple timeframe ORB (15m, 30m, 1h)
- [ ] Volume profile integration
- [ ] Session volatility analysis

### Phase 3: ML Integration
- [ ] LSTM price prediction overlay
- [ ] Adaptive ORB period based on volatility
- [ ] Neural network entry timing optimization

---

## Troubleshooting

### "Failed to create ATR indicator"
- Check that symbol has sufficient historical data
- Restart MT5 terminal
- Verify symbol is in Market Watch

### "Spread too high"
- Increase `InpMaxSpread` parameter
- Trade during liquid hours only
- Check if broker spread is abnormal

### "Daily loss limit exceeded"
- Wait for next trading day
- Review risk settings
- Check if multiple EAs are running

### "No trades opening"
- Verify session times are correct for your broker
- Check filters (spread, ATR, ADX)
- Ensure ORB period has passed
- Check if risk limits are exceeded

---

## Installation

1. Copy `ORB_Professional.mq5` to `MT5_DATA_FOLDER/MQL5/Experts/`
2. Copy library files to `MT5_DATA_FOLDER/MQL5/Include/Common/`:
   - TradeManager.mqh
   - RiskManager.mqh
   - ErrorHandling.mqh
3. Compile the EA in MetaEditor (F7)
4. Attach to chart
5. Configure parameters
6. Enable AutoTrading

---

## License

Apache License 2.0 - See LICENSE file

---

## Disclaimer

**RISK WARNING:** Trading forex, gold, and CFDs involves significant risk of loss. This EA is provided for educational purposes. Always test thoroughly on demo accounts before live trading. Past performance does not guarantee future results.

The original "bad EA" would have likely blown your account. This version implements proper risk management, but trading is still risky. Never risk more than you can afford to lose.

---

**Created:** 2024-11-15
**Version:** 1.0.0
**Status:** Production Ready ✓
