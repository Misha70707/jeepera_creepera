# Real ML Trading System v2.0

**A proper machine learning trading system that delivers what the original code promised.**

---

## 🎯 What This System Does

This is a **REAL** AI/ML trading bot that:
- ✅ Collects actual market data with proper labels
- ✅ Trains machine learning models with cross-validation
- ✅ Uses trained models for live trading decisions
- ✅ Has proper backtesting and statistical validation
- ✅ Includes risk management and position sizing
- ✅ No fake "neuroplastic learning" - uses proven ML algorithms

---

## 📦 System Components

### 1. **DataCollector.mq5**
- Runs on MT5 to collect training data
- Gathers 27 technical features per bar
- Labels data with future outcomes
- Exports to CSV for Python training

### 2. **train_model.py**
- Loads collected data
- Trains Random Forest classifier
- Uses time-series cross-validation
- Generates performance reports
- Exports model weights

### 3. **MLTradingBot.mq5**
- Production trading EA
- Loads trained ML model
- Makes predictions on live data
- Executes trades with proper risk management
- Falls back to rule-based strategy if model unavailable

---

## 🚀 Setup Instructions

### Prerequisites
- MetaTrader 5
- Python 3.7+ with pip
- Demo account (for initial testing)

### Step 1: Install Python Dependencies

```bash
pip install pandas numpy scikit-learn joblib matplotlib seaborn
```

### Step 2: Collect Training Data

1. Copy `DataCollector.mq5` to MT5: `<MT5_DATA_FOLDER>/MQL5/Experts/`
2. Open MT5 and load the EA on any chart (H1 recommended)
3. Settings:
   - `InpCollectOnly = true` (just collect, don't trade)
   - Let it run for **at least 200-500 bars** (1-3 weeks on H1)
4. Find `training_data.csv` in `<MT5_DATA_FOLDER>/MQL5/Files/`

**Important**: More data = better model. Aim for 1000+ labeled samples.

### Step 3: Train the Model

```bash
# Copy training_data.csv to this directory
python train_model.py
```

This will:
- Load and validate your data
- Train a Random Forest model
- Show performance metrics
- Save `trading_model.pkl` and `model_weights.txt`
- Generate `model_performance.png`

**Check the results!**
- Look at `model_performance.png` for confusion matrix
- Check test set accuracy (should be >55% for profitable trading)
- Review `feature_importance.csv` to understand what matters

### Step 4: Backtest (Optional but Recommended)

```bash
# Run the EA in MT5 Strategy Tester
# 1. Load MLTradingBot.mq5
# 2. Set InpUseModelPredictions = false (test fallback first)
# 3. Run on historical data
# 4. Copy model_weights.txt to MT5/MQL5/Files/
# 5. Set InpUseModelPredictions = true
# 6. Run again and compare results
```

### Step 5: Deploy (with EXTREME caution)

1. Copy `MLTradingBot.mq5` to `<MT5_DATA_FOLDER>/MQL5/Experts/`
2. Copy `model_weights.txt` to `<MT5_DATA_FOLDER>/MQL5/Files/`
3. Load on a **DEMO ACCOUNT** first
4. Monitor for at least 1 week
5. Only then consider live trading with minimal capital

---

## ⚙️ Key Parameters

### DataCollector.mq5
- `InpCollectOnly`: true = just collect data, false = trade while collecting
- `InpDataFile`: Output CSV filename
- `InpRSIPeriod`, `InpRSIBuy`, `InpRSISell`: Simple strategy for labeling

### train_model.py
- `model_type`: 'random_forest' or 'gradient_boosting'
- Check script for hyperparameters (n_estimators, max_depth, etc.)

### MLTradingBot.mq5
- `InpModelWeightsFile`: Model file to load
- `InpConfidenceThreshold`: Minimum confidence to trade (0.6 = 60%)
- `InpMaxRiskPercent`: Max risk per trade
- `InpStopLossPips` / `InpTakeProfitPips`: SL/TP in pips
- `InpUseModelPredictions`: true = use ML, false = fallback strategy

---

## 📊 Understanding Model Performance

### What to Look For:

**Good Signs:**
- Test accuracy > 55% (better than random)
- Similar train/test accuracy (no overfitting)
- F1-score > 0.50 for BUY/SELL classes
- CV scores consistent across folds

**Warning Signs:**
- Train accuracy 90%, test accuracy 40% = **overfitting!**
- Class imbalance (e.g., 90% HOLD) = model won't trade much
- High variance in CV scores = unstable model
- Feature importance dominated by 1-2 features = fragile

### Minimum Data Requirements:
- **Bare minimum**: 100 labeled samples
- **Recommended**: 500+ samples
- **Good**: 1000+ samples
- **Ideal**: 5000+ samples

---

## 🔬 How It Actually Works

### Data Collection Phase:
1. DataCollector EA runs on MT5
2. Every bar, it captures:
   - Price data (OHLC, volume)
   - 15+ technical indicators
   - Engineered features (momentum, S/R, time patterns)
3. After N bars, it labels what *actually happened*:
   - `optimal_action`: Should we have bought, sold, or held?
   - Based on actual price movement 10 bars later

### Training Phase:
1. Python loads CSV data
2. Splits into train (80%) and test (20%) **chronologically**
3. Trains Random Forest with:
   - 200 decision trees
   - Class balancing for imbalanced data
   - Time-series cross-validation (5 folds)
4. Evaluates on held-out test set
5. Exports model weights

### Trading Phase:
1. MLTradingBot loads model weights
2. Each bar, gathers same 27 features
3. Standardizes using saved scaler
4. Predicts: BUY / HOLD / SELL
5. If confidence > threshold, executes trade
6. Manages position with trailing stop

---

## 🎓 Why This is Better Than Original Code

| Original Code | This System |
|---------------|-------------|
| Fake "neuroplastic learning" | Real Random Forest ML |
| Learns from single trades | Trains on hundreds of samples |
| No validation | Time-series cross-validation |
| No statistical rigor | Proper train/test splits |
| Creates indicator handles every tick | Creates once, reuses |
| Multi-agent complexity | Clean, single model |
| No data collection framework | Full pipeline |
| Can't backtest learning | Full backtesting support |

---

## ⚠️ Risk Warnings

**CRITICAL**: This is still experimental. No ML system is guaranteed to profit.

1. **Always start with demo accounts**
2. **Backtest extensively** before live trading
3. **Monitor the bot closely** for first week
4. **Start with minimum lot sizes**
5. **Market conditions change** - model may stop working
6. **Never risk more than you can afford to lose**

### Known Limitations:
- Simplified model export (not full Random Forest)
- No online learning (model is static after training)
- Requires retraining periodically as market evolves
- May not work well in volatile/news-driven markets
- Past performance ≠ future results

---

## 📈 Next Steps for Improvement

### Short Term:
1. Collect more data (run DataCollector for months)
2. Try different ML algorithms (Gradient Boosting, XGBoost)
3. Add more features (correlations, volatility regimes)
4. Optimize hyperparameters with grid search

### Medium Term:
1. Implement ONNX export for full model deployment
2. Add ensemble of multiple models
3. Implement walk-forward optimization
4. Add market regime detection

### Long Term:
1. Deep learning (LSTM, Transformer models)
2. Reinforcement learning with proper reward functions
3. Multi-timeframe analysis
4. Portfolio optimization across multiple pairs

---

## 🐛 Troubleshooting

### "Failed to open model file"
- Check `model_weights.txt` is in `MT5/MQL5/Files/`
- Check filename matches `InpModelWeightsFile` parameter

### "Insufficient labeled data"
- Run DataCollector longer (need 100+ samples minimum)
- Check CSV has rows with non-null `optimal_action`

### "Model not trading"
- Lower `InpConfidenceThreshold` (try 0.5 instead of 0.6)
- Check model accuracy - may be predicting mostly HOLD
- Verify features are calculated correctly

### "Poor backtesting results"
- Model may be overfit - collect more diverse data
- Try different ML algorithm or hyperparameters
- Check if market conditions changed since training data

### Indicator handle errors
- Make sure all indicator handles are valid
- Check MT5 terminal has enough memory
- Restart MT5 if indicators stop working

---

## 📝 File Locations

```
Your Trading Folder/
├── DataCollector.mq5          # Copy to MT5/MQL5/Experts/
├── MLTradingBot.mq5           # Copy to MT5/MQL5/Experts/
├── train_model.py             # Run in this folder
├── training_data.csv          # Generated by DataCollector
├── model_weights.txt          # Generated by train_model.py
├── trading_model.pkl          # Generated by train_model.py
├── model_performance.png      # Generated by train_model.py
├── feature_importance.csv     # Generated by train_model.py
└── README.md                  # This file
```

---

## 📚 Further Reading

- [Scikit-learn Documentation](https://scikit-learn.org/)
- [Random Forests Explained](https://en.wikipedia.org/wiki/Random_forest)
- [Time Series Cross-Validation](https://scikit-learn.org/stable/modules/cross_validation.html#time-series-split)
- [Backtesting Best Practices](https://www.quantstart.com/articles/Backtesting-Systematic-Trading-Strategies-in-Python-Considerations-and-Open-Source-Frameworks/)

---

## 🤝 Contributing

Found a bug? Want to improve the system? Contributions welcome!

1. Test thoroughly on demo account
2. Document your changes
3. Share results (accuracy, profitability, etc.)

---

## 📄 License

Use at your own risk. No warranty provided. Trading is risky.

---

## ✅ Final Checklist

Before live trading:

- [ ] Collected 500+ training samples
- [ ] Trained model with >55% test accuracy
- [ ] Reviewed feature importance makes sense
- [ ] Backtested on 3+ months of historical data
- [ ] Forward tested on demo for 1+ week
- [ ] Understood risk management parameters
- [ ] Set up proper SL/TP levels
- [ ] Monitoring system in place
- [ ] Only risking capital you can afford to lose
- [ ] Have realistic expectations (not get-rich-quick)

---

**Good luck, and trade responsibly! 🚀**
