# 🚀 VECTORUM EA Backtester - GUI Quick Start

Professional desktop application for backtesting trading EAs with a beautiful graphical interface.

---

## 🎯 Quick Launch

### **Windows**
1. Double-click `launch_backtester.bat`
2. The GUI will open automatically

### **macOS / Linux**
1. Double-click `launch_backtester.sh`
2. Or run: `bash launch_backtester.sh`
3. Or run: `python3 backtester_gui.py`

---

## ✨ Features

### **🎨 Beautiful Dark Theme Interface**
- Professional dark UI with accent colors
- Easy-to-read metrics and statistics
- Responsive design that works at any resolution

### **⚙️ Configurable Parameters**
- **Initial Balance**: Set your starting capital ($1 - $∞)
- **Risk Per Trade**: Percentage of account to risk (0.5% - 10%)
- **Vector Magnitude**: Signal strength threshold (0.1 - 1.0)
- **Correlation Threshold**: Confluence requirement (0.0 - 1.0)

### **📊 Real-time Results**
- Live progress indicator during backtest
- Instant status updates
- Professional HTML-styled console output

### **📈 Three Analytics Tabs**

#### **Summary Tab**
Shows all key statistics:
- Account performance ($$ and %)
- Trade statistics (count, win rate, profit factor)
- Risk metrics (drawdown, Sharpe, Sortino)
- Trade streaks and durations

#### **Trades Tab**
Detailed list of every trade:
- Entry/Exit times and prices
- Position type (BUY/SELL)
- Profit/Loss in dollars and percentage
- Exit reason (TP/SL/SIGNAL)

#### **Metrics Tab**
Advanced analytics:
- Profitability analysis
- Risk/reward ratios
- Volatility metrics
- Trade characteristics
- Interpretation guide

### **💾 Export Options**
- **Export CSV**: Individual trade breakdown (open in Excel)
- **Export JSON**: Machine-readable format (for scripts)

---

## 🖱️ How to Use

### **1. Launch the Application**
```bash
python3 backtester_gui.py
# OR
bash launch_backtester.sh  # macOS/Linux
# OR
launch_backtester.bat     # Windows (double-click)
```

### **2. Configure Parameters**
Set your desired backtesting parameters in the left panel:
```
Initial Balance:        $10,000
Risk Per Trade:         2.0%
Vector Magnitude:       0.50
Min Correlation:        0.50
```

### **3. Run Backtest**
Click the **▶ Run Backtest** button and wait for completion.

### **4. Analyze Results**
- **Summary Tab**: Overview of performance
- **Trades Tab**: Individual trade breakdown
- **Metrics Tab**: Detailed statistics

### **5. Export**
Export your results for further analysis:
```
💾 Export CSV   → trades.csv (Excel/Sheets)
📑 Export JSON  → results.json (Programmatic use)
```

---

## 📊 Understanding the Display

### **Account Statistics**
```
Initial Balance:        $10,000.00
Final Balance:          $10,450.70
Total Return:           $450.70
Total Return %:         +4.51%
```
Shows your starting capital and final profitability.

### **Trade Statistics**
```
Total Trades:           19
Winning Trades:         12
Losing Trades:          7
Win Rate:               63.16%
Profit Factor:          1.82
```
- **Win Rate > 50%**: Positive edge
- **Profit Factor > 1.5**: Good system
- **Profit Factor > 2.0**: Excellent system

### **Risk Metrics**
```
Max Drawdown:           $1,183.44 (-11.83%)
Sharpe Ratio:           1.25
Sortino Ratio:          2.15
```
- **Sharpe > 1.0**: Good risk-adjusted returns
- **Sharpe > 2.0**: Excellent
- **Drawdown < 10%**: Low risk

---

## 🔧 Customization

### **Adjust Vector Magnitude**
**Lower (0.30)**: More trades, more false signals
**Higher (0.70)**: Fewer trades, higher quality signals

### **Adjust Correlation Threshold**
**Lower (0.30)**: Accept weaker confluence
**Higher (0.80)**: Require strong indicator agreement

### **Adjust Risk Per Trade**
**1%**: Conservative, safer but slower growth
**5%**: Aggressive, faster growth but higher risk
**Best Practice**: 2% (balance between safety and growth)

---

## 💡 Tips & Tricks

### **1. Find Your Optimal Settings**
Run multiple backtests with different parameters:
```
Test 1: Risk 1%, Vector 0.50, Corr 0.60
Test 2: Risk 2%, Vector 0.60, Corr 0.70
Test 3: Risk 3%, Vector 0.40, Corr 0.50
```

### **2. Compare Results**
Export multiple backtests to JSON and compare:
```
backtest_conservative.json
backtest_moderate.json
backtest_aggressive.json
```

### **3. Look for Consistency**
Good systems have:
- Consistent win rate (not lucky streaks)
- Low drawdown relative to profits
- Positive Sharpe ratio
- Reasonable trade durations

### **4. Avoid Over-optimization**
Don't optimize too hard to past data:
- Use reasonable parameter ranges
- Test on different market conditions
- Validate on new data

---

## 🐛 Troubleshooting

### **"No trades generated"**
- Lower the Vector Magnitude threshold
- Lower the Correlation threshold
- Check that parameters are within valid ranges

### **"GUI won't open"**
```bash
# Make sure Python 3 and tkinter are installed
python3 --version  # Should be 3.7+
python3 -m tkinter  # Should open a test window
```

### **On Windows: "Python not found"**
1. Install Python 3.8+ from python.org
2. Check "Add Python to PATH" during installation
3. Restart computer
4. Try again

### **On macOS: "Permission denied"**
```bash
chmod +x launch_backtester.sh
./launch_backtester.sh
```

### **On Linux: "Module not found"**
```bash
pip3 install numpy pandas
python3 backtester_gui.py
```

---

## 📁 File Structure

```
.
├── backtester_gui.py              # Main GUI application
├── ea_backtester.py               # Backtesting engine
├── launch_backtester.sh           # macOS/Linux launcher
├── launch_backtester.bat          # Windows launcher
├── vectorum-backtester.desktop    # Linux app entry
├── EA_VECTORUM_ADVANCED.mq5       # MT5 EA
├── BACKTESTER_GUIDE.md            # Detailed guide
└── GUI_QUICKSTART.md              # This file
```

---

## 🚀 Next Steps

1. **Run a backtest** with default parameters
2. **Review the Summary tab** to see overall performance
3. **Check the Trades tab** to see what worked/didn't
4. **Analyze Metrics tab** for risk-adjusted returns
5. **Export CSV** and open in Excel for more analysis
6. **Experiment** with different parameter combinations

---

## 💬 Support

### Common Questions

**Q: What do the thresholds mean?**
A: Vector Magnitude measures signal strength (0-1). Correlation measures indicator agreement (0-1). Higher = stricter filters.

**Q: Why are my trades not profitable?**
A: This is synthetic data! Real backtests depend on actual market data. Use these parameters as starting points.

**Q: Can I use real market data?**
A: Yes! Modify `run_sample_backtest()` in `ea_backtester.py` to load your data.

**Q: How often should I optimize?**
A: Be careful with over-optimization. Test monthly with new data to ensure continued edge.

---

## 🎓 Educational Resources

See these files for more info:
- `BACKTESTER_GUIDE.md` - Detailed metric explanations
- `EA_VECTORUM_ADVANCED.mq5` - VECTORUM EA source code
- `ea_backtester.py` - Python backtester source

---

**Enjoy your professional backtesting! 🚀**
