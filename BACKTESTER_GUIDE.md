# 🚀 VECTORUM EA Backtesting Framework

Professional-grade backtesting software for testing Expert Advisors with mathematical rigor and detailed performance analysis.

## 📋 Features

### Core Functionality
- **Trade Simulation Engine**: Realistically simulates trade execution, stop losses, and take profits
- **Position Sizing**: Implements Kelly Criterion for optimal position sizing based on win rate
- **Dynamic Stops**: ATR-based stop losses that adapt to market volatility
- **Confluence Detection**: Pearson correlation matrix for multi-indicator agreement

### Performance Metrics
- **Win Rate & Trade Count**: Total trades, winners, losers
- **Profitability**: Profit factor, expectancy, average win/loss
- **Risk Metrics**: Max drawdown ($ and %), Sharpe ratio, Sortino ratio
- **Trade Analysis**: Best/worst trades, trade duration, consecutive wins/losses

### Output Formats
- 📊 Console HTML-style reports
- 📈 CSV file with individual trade details
- 📑 JSON file with complete statistics for programmatic access

---

## 🛠️ Installation

### Requirements
```bash
pip install numpy pandas
```

### Python Version
- Python 3.7+

---

## 🎯 Quick Start

### Basic Usage

```python
from ea_backtester import Backtester, VECTORUMSimulator, run_sample_backtest

# Run the sample backtest
backtester = run_sample_backtest()
```

### Custom Backtest

```python
from ea_backtester import Backtester

# Create backtester
backtester = Backtester(initial_balance=10000.0, risk_per_trade=2.0)

# Execute a trade
trade = backtester.execute_trade(
    entry_price=1.10500,
    entry_time=0,
    position_type='BUY',
    stop_loss=1.09900,
    take_profit=1.11700
)

# Close the trade
if trade:
    backtester.close_trade(trade, 1.11700, 25, 'TP')

# Get results
results = backtester.get_results()
backtester.print_report()
backtester.export_csv('trades.csv')
backtester.export_json('results.json')
```

---

## 📊 Understanding the Report

### Account Statistics
```
Initial Balance:          $10,000.00    # Starting capital
Final Balance:            $9,549.30     # Ending capital
Total Return:             $-450.70      # P&L in dollars
Total Return %:           -4.51%        # P&L percentage
```

### Trade Statistics
```
Total Trades:             19            # Number of completed trades
Winning Trades:           6             # Profitable trades
Losing Trades:            13            # Losing trades
Win Rate:                 31.58%        # % of profitable trades
Profit Factor:            0.81          # Gross profit / Gross loss (>1.0 is good)
Expectancy:               $-23.72       # Average P&L per trade
```

### Trade Analysis
```
Average Winner:           $319.66       # Mean profit on winners
Average Loser:            $182.20       # Mean loss on losers
Best Trade:               $383.94       # Biggest profit
Worst Trade:              $-202.99      # Biggest loss
Avg Trade Duration:       23 bars       # Average bars in trade
```

### Risk Metrics
```
Max Drawdown:             $1,183.44     # Largest loss from peak
Max Drawdown %:           11.83%        # Drawdown as % of balance
Sharpe Ratio:             -1.32         # Risk-adjusted returns (higher is better)
Sortino Ratio:            -8.35         # Downside risk ratio (higher is better)
```

### Streaks
```
Max Consecutive Wins:     4             # Longest win streak
Max Consecutive Losses:   7             # Longest loss streak
```

---

## 📈 Interpreting Key Metrics

### Profit Factor
- **> 2.0**: Excellent (2x more profit than losses)
- **1.5 - 2.0**: Good
- **1.0 - 1.5**: Acceptable
- **< 1.0**: Unprofitable (losses exceed profits)

### Win Rate
- **> 60%**: Excellent system
- **50% - 60%**: Good system
- **< 40%**: Requires good R:R ratio to be profitable

### Sharpe Ratio
- **> 1.0**: Good risk-adjusted returns
- **> 2.0**: Excellent
- **< 0.0**: Negative returns

### Max Drawdown
- **< 10%**: Excellent
- **10% - 20%**: Good
- **> 30%**: High risk

---

## 🔧 Customizing the Backtester

### Change Risk Parameters

```python
# More conservative
backtester = Backtester(initial_balance=50000, risk_per_trade=1.0)

# More aggressive
backtester = Backtester(initial_balance=5000, risk_per_trade=5.0)
```

### Adjust Signal Thresholds

Edit the `get_signal()` method in `VECTORUMSimulator`:

```python
# Make it more strict (fewer trades)
if vector_mag < 0.65 or correlation < 0.70:
    return 0

# Make it more lenient (more trades)
if vector_mag < 0.30 or correlation < 0.40:
    return 0
```

### Modify Position Sizing

Edit `_calculate_position_size()`:

```python
# Current: Based on Kelly Criterion
# Can change to fixed lot size:
def _calculate_position_size(self, entry_price, stop_loss):
    return 0.5  # Fixed 0.5 lots
```

---

## 📁 Output Files

### trades.csv
Detailed breakdown of each trade:
```csv
Entry Time,Entry Price,Exit Time,Exit Price,Type,Volume,Stop Loss,Take Profit,Exit Reason,Profit/Loss,Pips,Return %
0,1.10500,25,1.11700,BUY,0.58,1.09900,1.11700,TP,690.00,120.00,6.90
25,1.11700,50,1.10900,SELL,0.58,1.12300,1.10900,TP,464.00,80.00,4.64
```

### backtest_results.json
Machine-readable summary:
```json
{
  "timestamp": "2024-11-12T10:30:00",
  "results": {
    "initial_balance": 10000.00,
    "final_balance": 9549.30,
    "total_return_percent": -4.51,
    "total_trades": 19,
    "win_rate": 31.58,
    "sharpe_ratio": -1.32,
    "max_drawdown_percent": 11.83
  }
}
```

---

## 🧪 Testing Your EA Logic

### Step 1: Implement Your Signals
Create a custom simulator class:

```python
class MyEASimulator:
    def get_signal(self, indicators_dict) -> int:
        # Your signal logic here
        # Return: 1=BUY, -1=SELL, 0=NO SIGNAL
        pass
```

### Step 2: Run Backtest
```python
backtester = Backtester(10000, 2.0)
simulator = MyEASimulator()

# Your backtesting loop
for bar in range(20, num_bars):
    signal = simulator.get_signal(indicators)
    if signal != 0:
        trade = backtester.execute_trade(...)
```

### Step 3: Analyze Results
```python
backtester.print_report()
backtester.export_trades_csv('my_ea_trades.csv')
```

---

## 💡 Best Practices

### 1. Use Realistic Parameters
- Match your actual broker's spread
- Use realistic slippage (10-20 pips)
- Account for commissions if applicable

### 2. Test Multiple Scenarios
```python
# Bull market
# Bear market
# Choppy sideways
# High volatility
# Low volatility
```

### 3. Look at the Full Picture
Don't just focus on win rate:
- High win rate + small wins = bad
- Low win rate + large wins = good
- Check Sharpe/Sortino for risk-adjusted performance

### 4. Walk Forward Testing
- Test on different time periods
- Ensure consistency across markets
- Avoid curve-fitting to past data

---

## 🐛 Troubleshooting

### No Trades Generated
**Problem**: Backtester runs but generates 0 trades

**Solution**: Lower signal thresholds in `get_signal()`
```python
if vector_mag < 0.30:  # Lower from 0.65
    return 0
```

### Negative Returns on All Trades
**Problem**: Every trade is losing money

**Solution**:
- Check stop loss placement (too tight?)
- Check take profit ratio (too tight?)
- Verify indicator calculation

### High Drawdown
**Problem**: Large negative swings in equity

**Solution**:
- Reduce risk per trade (2% → 1%)
- Make entry signals more strict
- Increase stop loss distance

---

## 📚 Advanced Topics

### Kelly Criterion Formula
```
f = (2*P - 1) * Multiplier

where:
  P = Win probability (0-1)
  f = Fraction of capital to risk
  Multiplier = Conservative adjustment (usually 0.25)
```

### Sharpe Ratio Formula
```
Sharpe = (Mean Return - Risk Free Rate) / Std Dev of Returns
(Annualized by multiplying by sqrt(252))
```

### Sortino Ratio
Like Sharpe but only penalizes negative volatility:
```
Sortino = Mean Return / Downside Volatility
```

---

## 🔗 Files Included

- `ea_backtester.py` - Main backtesting framework
- `EA_VECTORUM_ADVANCED.mq5` - VECTORUM EA for MT5
- `BACKTESTER_GUIDE.md` - This file

---

## 📞 Usage Examples

### Example 1: Quick Backtest
```bash
python3 ea_backtester.py
```

### Example 2: Custom Test with Different Risk
```python
backtester = Backtester(20000, 1.0)  # $20k, 1% risk
# ... run your trading loop ...
backtester.print_report()
```

### Example 3: Load and Analyze Results
```python
import json

with open('backtest_results.json') as f:
    results = json.load(f)

print(f"Win Rate: {results['results']['win_rate']}%")
print(f"Sharpe: {results['results']['sharpe_ratio']}")
```

---

**Happy Testing! 🚀**
