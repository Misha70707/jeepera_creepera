# Quick Start Guide

## 🚀 Get Trading in 5 Steps

### Step 1: Install Python Dependencies (2 minutes)
```bash
pip install -r requirements.txt
```

### Step 2: Collect Data (1-3 weeks passive)
1. Copy `DataCollector.mq5` to your MT5 Experts folder
2. Attach to H1 chart on demo account
3. Set `InpCollectOnly = true`
4. Let it run for 200-500 bars minimum
5. Find `training_data.csv` in MT5/Files folder

**Tip**: Run it on multiple pairs simultaneously to collect more data faster!

### Step 3: Train Model (5 minutes)
```bash
python train_model.py
```

Look at the output:
- ✅ Test accuracy >55%? Good to go!
- ❌ Test accuracy <50%? Collect more data or adjust parameters

### Step 4: Backtest (30 minutes)
1. Copy `MLTradingBot.mq5` to MT5 Experts folder
2. Copy `model_weights.txt` to MT5/Files folder
3. Run in Strategy Tester on 3 months of history
4. Check: Win rate >50%? Profit factor >1.2? Max DD <20%?

### Step 5: Demo Forward Test (1 week minimum)
1. Run on demo account
2. Monitor daily
3. Verify model is making sensible decisions
4. If profitable after 20+ trades, consider small live test

---

## ⚡ Commands Cheat Sheet

```bash
# Install dependencies
pip install -r requirements.txt

# Train model
python train_model.py

# Train with gradient boosting instead
# (edit train_model.py, change model_type='gradient_boosting')
python train_model.py
```

---

## 📊 Expected Results

**With 500 samples:**
- Test accuracy: 52-58%
- Win rate: 48-55%
- Profit factor: 1.1-1.4

**With 1000+ samples:**
- Test accuracy: 55-62%
- Win rate: 52-58%
- Profit factor: 1.3-1.8

**Note**: These are realistic expectations, not guarantees!

---

## 🔍 What to Monitor

### During Data Collection:
- CSV file growing (check every few days)
- Simple trades being executed (if InpCollectOnly=false)

### During Training:
- No overfitting (train accuracy ≈ test accuracy)
- Feature importances make sense (not 90% from one feature)
- CV scores are stable (not huge variance)

### During Live Trading:
- Confidence scores (should vary, not always 0.6)
- Trade frequency (not too many, not too few)
- Drawdown stays under max limit
- Win rate tracks with backtest expectations

---

## ❌ Common Mistakes

1. **Not enough data** - Minimum 100 samples, aim for 500+
2. **Skipping backtesting** - Always backtest before live!
3. **Overfitting** - If train=90% but test=45%, you overfit
4. **Wrong files location** - model_weights.txt must be in MT5/Files/
5. **Impatient** - ML needs time to collect good data

---

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "File not found" | Check file is in MT5/MQL5/Files/ folder |
| Model not loading | Verify model_weights.txt format is correct |
| No trades executing | Lower InpConfidenceThreshold to 0.5 |
| Poor results | Collect more diverse data, retrain |
| Overtrading | Increase InpMinBarsBetweenTrades |

---

## 📞 Need Help?

1. Read the full README.md
2. Check logs in MT5 Experts tab
3. Review model_performance.png for ML issues
4. Test with InpUseModelPredictions=false to verify EA basics work

---

**Remember: This is experimental. Start small, test thoroughly, never risk more than you can afford to lose!**
