# CLAUDE.md - AI Assistant Guide

This document provides comprehensive guidance for AI assistants working with the `tweny_fo_seven_trees_ixty_five` repository.

## Repository Overview

**Name:** tweny_fo_seven_trees_ixty_five
**Description:** Top Secret
**License:** Apache License 2.0
**Status:** Early stage - minimal structure established

## Project Type

This repository is designed for **MetaTrader 5 (MT5) Algorithmic Trading** development with advanced **Neural Network** and **Neuroplastic** adaptive learning systems. The `.gitignore` configuration suggests MPS/Java build patterns, which may be used for auxiliary tooling or code generation for MT5 systems.

### Primary Focus:
- **MetaTrader 5 (MT5)** - Professional algorithmic trading platform
- **MQL5** - Native programming language for MT5 Expert Advisors (EAs) and indicators
- **Neural Networks** - Deep learning models for market prediction and pattern recognition
- **Neuroplastic Modules** - Adaptive learning systems that evolve with market conditions

### Key Indicators:
- Ignores MPS-specific directories: `classes_gen`, `source_gen`, `test_gen`
- Ignores MPS workspace configuration: `workspace.xml`
- Ignores MPS build artifacts and JUnit test results
- May use Java/MPS for preprocessing, backtesting infrastructure, or ML model training

## Repository Structure

```
tweny_fo_seven_trees_ixty_five/
├── .git/                 # Git version control
├── .gitattributes        # Git text normalization (LF line endings)
├── .gitignore           # JetBrains MPS exclusions
├── LICENSE              # Apache License 2.0
├── README.md            # Project description
└── CLAUDE.md            # This file
```

### Current State
- **No source code yet** - repository contains only configuration files
- **Single commit** - "Initial commit" (5dec970)
- **Clean working directory** - no uncommitted changes

## Development Workflow

### Git Branch Strategy

**CRITICAL:** This repository uses a specific branch naming convention for AI assistant development:

**Current Development Branch:**
```
claude/<descriptive-name>-<session-id>
```

**Branch Naming Pattern:**
- Must start with `claude/`
- Must end with the session ID
- Format: `claude/<descriptive-name>-<session-id>`

### Git Operations Best Practices

#### Pushing Changes
```bash
# Always use -u flag for first push to set upstream
git push -u origin claude/<descriptive-name>-<session-id>

# CRITICAL: Branch must follow naming convention or push will fail with 403
```

**Retry Logic for Network Failures:**
- Retry up to 4 times with exponential backoff: 2s, 4s, 8s, 16s
- Applies to: `git push`, `git fetch`, `git pull`

#### Fetching/Pulling
```bash
# Fetch specific branch
git fetch origin claude/<descriptive-name>-<session-id>

# Pull specific branch
git pull origin claude/<descriptive-name>-<session-id>
```

### Commit Guidelines

**Format:**
```
<type>: <short description>

<optional detailed explanation>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code restructuring without behavior change
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `build:` - Build system changes

**Example:**
```bash
git commit -m "$(cat <<'EOF'
feat: Add initial MPS language definition

Created base language structure for domain-specific language.
Includes basic syntax and type system definitions.
EOF
)"
```

### Workflow Steps

1. **Ensure you're on the correct branch:**
   ```bash
   git checkout claude/<descriptive-name>-<session-id>
   ```

2. **Make changes and stage:**
   ```bash
   git add <files>
   ```

3. **Commit with descriptive message:**
   ```bash
   git commit -m "$(cat <<'EOF'
   <commit message>
   EOF
   )"
   ```

4. **Push to remote:**
   ```bash
   git push -u origin claude/<descriptive-name>-<session-id>
   ```

## AI Assistant Conventions

### Task Management

Use the TodoWrite tool for:
- Complex multi-step tasks (3+ steps)
- Non-trivial implementations
- Multiple user requests
- Tracking progress on ongoing work

**Mark tasks:**
- `pending` - Not started
- `in_progress` - Currently working (ONE at a time)
- `completed` - Finished

### Code Quality Standards

1. **Security First:**
   - Avoid OWASP Top 10 vulnerabilities
   - No command injection, XSS, SQL injection
   - Immediately fix any security issues discovered

2. **File Operations:**
   - Use specialized tools (Read, Edit, Write) over bash commands
   - Prefer editing existing files over creating new ones
   - Don't create documentation files unless explicitly requested

3. **Tool Usage:**
   - Use Task tool with `subagent_type=Explore` for codebase exploration
   - Run independent commands in parallel when possible
   - Use specific tools instead of bash when available

### Communication Guidelines

- **Concise responses** - This is a CLI environment
- **No emojis** unless explicitly requested
- **Technical accuracy** over validation
- **Direct, objective** technical information
- **Reference code** with `file_path:line_number` pattern

### File References

When referencing code, use this format:
```
The function is in src/main/Example.java:42
```

## Expected Project Development

Given the MPS-focused `.gitignore`, future development will likely include:

### Potential Directory Structure
```
tweny_fo_seven_trees_ixty_five/
├── MQL5/                          # MetaTrader 5 code
│   ├── Experts/                   # Expert Advisors (EAs)
│   ├── Indicators/                # Custom indicators
│   ├── Scripts/                   # Utility scripts
│   ├── Include/                   # Shared libraries and classes
│   │   ├── NeuralNetwork/         # NN module implementations
│   │   └── Neuroplastic/          # Adaptive learning modules
│   └── Files/                     # Data files, models, weights
├── Python/                        # Python ML/NN training scripts
│   ├── models/                    # Neural network architectures
│   ├── training/                  # Training pipelines
│   ├── data/                      # Historical data, preprocessed datasets
│   └── utils/                     # Helper functions
├── languages/                     # MPS language definitions (if used)
├── solutions/                     # MPS solutions (if used)
├── classes_gen/                   # Generated Java classes (gitignored)
├── source_gen/                    # Generated source files (gitignored)
├── test_gen/                      # Generated test code (gitignored)
└── build/                         # Build outputs
```

### MPS-Specific Patterns

**Generated Files (gitignored):**
- `classes_gen/` - Compiled Java bytecode
- `source_gen/` - Generated Java source
- `source_gen.caches/` - MPS caches
- `test_gen/` - Generated test code
- `test_gen.caches/` - Test caches

**Build Artifacts (gitignored):**
- `TEST-*.xml` - JUnit test results
- `junit*.properties` - JUnit configuration
- `workspace.xml` - IDE workspace settings
- `build.properties` - Build configuration

---

## MetaTrader 5 (MT5) Deep Knowledge

### Platform Architecture

**MetaTrader 5** is a multi-asset trading platform supporting Forex, stocks, futures, and CFDs. Understanding its architecture is critical for building robust trading systems.

#### Core Components

1. **Terminal** - Client application for traders
2. **Server** - Broker's trading server (not directly accessible)
3. **Data Feed** - Real-time and historical market data
4. **Strategy Tester** - Backtesting and optimization engine
5. **MQL5 Cloud Network** - Distributed computing for optimization

#### Market Data Structure

```mql5
// Understanding ticks vs bars is fundamental
MqlTick tick;           // Individual price updates (bid, ask, last, volume)
MqlRates rates[];       // OHLCV bars (Open, High, Low, Close, Volume)
```

**Critical Concepts:**
- **Ticks** - Asynchronous price updates (use for tick-based EAs)
- **Bars** - Time-aggregated OHLCV data (use for indicator-based strategies)
- **Depth of Market (DOM)** - Level 2 data for advanced strategies

### MQL5 Programming Best Practices

#### Program Types

1. **Expert Advisors (EAs)** - Automated trading systems
   - Must handle `OnInit()`, `OnDeinit()`, `OnTick()` events
   - Use object-oriented design for complex strategies

2. **Indicators** - Technical analysis calculations
   - Must implement `OnCalculate()` efficiently
   - Use indicator buffers for performance

3. **Scripts** - One-time utility functions
   - Execute once and terminate
   - Useful for batch operations

#### Critical MQL5 Patterns

**1. Event-Driven Architecture**
```mql5
// Expert Advisor structure
int OnInit() {
    // Initialize: load models, set parameters
    // ALWAYS validate inputs here
    // Return INIT_SUCCEEDED or INIT_FAILED
}

void OnDeinit(const int reason) {
    // Cleanup: save state, close handles
    // CRITICAL: Free all resources (files, indicators, timers)
}

void OnTick() {
    // Execute on every price update
    // Keep this FAST - offload heavy computation
}
```

**2. Error Handling**
```mql5
// ALWAYS check return values
int ticket = OrderSend(...);
if(ticket < 0) {
    int error = GetLastError();
    Print("OrderSend failed: ", ErrorDescription(error));
    // Handle specific errors (requotes, insufficient margin, etc.)
}
```

**3. Memory Management**
```mql5
// Arrays and buffers
double prices[];
ArraySetAsSeries(prices, true);  // CRITICAL: Most recent data at index 0
ArrayResize(prices, 1000);       // Pre-allocate to avoid reallocation

// Dynamic objects - use pointers carefully
CMyClass* obj = new CMyClass();
delete obj;  // MUST manually delete
```

#### Performance Optimization

**Rule #1: Minimize calculations in OnTick()**
- Cache indicator values
- Use static variables for persistent state
- Implement trade logic only on new bar formation

**Rule #2: Use indicator buffers efficiently**
```mql5
#property indicator_buffers 3
#property indicator_plots   1

double MainBuffer[];      // Visible plot
double TempBuffer1[];     // Intermediate calculations
double TempBuffer2[];     // Intermediate calculations

int OnInit() {
    SetIndexBuffer(0, MainBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, TempBuffer1, INDICATOR_CALCULATIONS);
    SetIndexBuffer(2, TempBuffer2, INDICATOR_CALCULATIONS);
}
```

**Rule #3: Avoid repainting**
```mql5
// BAD: Repaints on every tick
if(iClose(Symbol(), PERIOD_CURRENT, 0) > iMA(...)) { }

// GOOD: Uses confirmed closed bar
if(iClose(Symbol(), PERIOD_CURRENT, 1) > iMA(...)) { }
```

### Trading Operations Best Practices

#### Order Management

**1. Position Sizing**
```mql5
// CRITICAL: Never risk more than you can afford to lose
double CalculateLotSize(double stopLossPoints, double riskPercent) {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskMoney = accountBalance * riskPercent / 100.0;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotSize = riskMoney / (stopLossPoints * tickValue);

    // Normalize to broker's lot step
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

    return lotSize;
}
```

**2. Slippage Protection**
```mql5
MqlTradeRequest request = {};
MqlTradeResult result = {};

request.action = TRADE_ACTION_DEAL;
request.symbol = _Symbol;
request.volume = lot;
request.type = ORDER_TYPE_BUY;
request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
request.deviation = 10;  // Max slippage in points
request.magic = MAGIC_NUMBER;

if(!OrderSend(request, result)) {
    Print("OrderSend error: ", result.retcode);
}
```

**3. Partial Close & Trailing Stop**
```mql5
// Partial position close
bool ClosePartialPosition(ulong ticket, double percentToClose) {
    if(!PositionSelectByTicket(ticket)) return false;

    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    double closeVolume = NormalizeDouble(currentVolume * percentToClose, 2);

    MqlTradeRequest request = {};
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.volume = closeVolume;
    // ... set other parameters
}
```

### Data Management

#### Historical Data Access

```mql5
// ALWAYS check if enough bars are available
int bars = Bars(_Symbol, _Period);
if(bars < 100) {
    Print("Not enough historical data");
    return;
}

// Copy price data efficiently
MqlRates rates[];
ArraySetAsSeries(rates, true);
int copied = CopyRates(_Symbol, _Period, 0, 100, rates);
if(copied <= 0) {
    Print("Failed to copy rates: ", GetLastError());
}
```

#### File I/O for Neural Network Integration

```mql5
// Save neural network weights/state
int fileHandle = FileOpen("NN_Weights.bin", FILE_WRITE|FILE_BIN);
if(fileHandle != INVALID_HANDLE) {
    FileWriteArray(fileHandle, weights);
    FileClose(fileHandle);
}

// Load neural network weights
fileHandle = FileOpen("NN_Weights.bin", FILE_READ|FILE_BIN);
if(fileHandle != INVALID_HANDLE) {
    FileReadArray(fileHandle, weights);
    FileClose(fileHandle);
}
```

---

## Neural Network Modules for Trading

### Architecture Considerations

#### Why Neural Networks for Trading?

1. **Pattern Recognition** - Identify complex, non-linear market patterns
2. **Feature Learning** - Automatically discover predictive features
3. **Adaptation** - Learn from new market data continuously
4. **Multi-timeframe Analysis** - Process multiple scales simultaneously

#### Common NN Architectures for Trading

**1. Feedforward Networks (FNN)**
- **Use case:** Price prediction, classification (buy/sell/hold)
- **Input:** Technical indicators, price features
- **Output:** Price forecast or trade signal
- **Pros:** Simple, fast inference
- **Cons:** No temporal awareness

**2. Recurrent Networks (RNN/LSTM/GRU)**
- **Use case:** Time series prediction, sequence modeling
- **Input:** Sequences of prices, multi-timeframe data
- **Output:** Next price movement, volatility forecast
- **Pros:** Captures temporal dependencies
- **Cons:** Slow training, vanishing gradients (RNN)

**3. Convolutional Networks (CNN)**
- **Use case:** Chart pattern recognition, image-based analysis
- **Input:** Price charts as images, candlestick patterns
- **Output:** Pattern classification
- **Pros:** Translation invariance, efficient for spatial data
- **Cons:** Requires image preprocessing

**4. Transformer Networks**
- **Use case:** Multi-asset correlation, attention-based forecasting
- **Input:** Multi-asset price sequences
- **Output:** Cross-asset predictions
- **Pros:** Parallel processing, long-range dependencies
- **Cons:** High computational cost

**5. Ensemble Methods**
- **Use case:** Robust predictions, uncertainty quantification
- **Architecture:** Multiple models voting
- **Pros:** Reduces overfitting, more stable
- **Cons:** Increased inference time

### Neural Network Integration with MQL5

#### Two-Stage Approach (Recommended)

**Stage 1: Python Training Pipeline**
```python
# Python: Train model offline
import tensorflow as tf
import numpy as np

# 1. Prepare data
X_train, y_train = prepare_market_data()

# 2. Define model
model = tf.keras.Sequential([
    tf.keras.layers.LSTM(64, return_sequences=True),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.LSTM(32),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear')
])

# 3. Train
model.compile(optimizer='adam', loss='mse')
model.fit(X_train, y_train, epochs=100, validation_split=0.2)

# 4. Export weights to binary format for MQL5
weights = model.get_weights()
np.save('model_weights.npy', weights)
```

**Stage 2: MQL5 Inference**
```mql5
// MQL5: Load model and perform inference
class CNeuralNetwork {
private:
    double weights_l1[][];  // Layer 1 weights
    double weights_l2[][];  // Layer 2 weights
    double bias_l1[];
    double bias_l2[];

public:
    bool LoadWeights(string filename) {
        // Load weights from file
        int handle = FileOpen(filename, FILE_READ|FILE_BIN);
        if(handle == INVALID_HANDLE) return false;

        // Read weight matrices
        // ... implementation
        FileClose(handle);
        return true;
    }

    double Predict(double &features[]) {
        // Forward propagation
        double hidden[];
        ArrayResize(hidden, 64);

        // Layer 1: Input -> Hidden
        MatMul(features, weights_l1, hidden);
        AddBias(hidden, bias_l1);
        ReLU(hidden);

        // Layer 2: Hidden -> Output
        double output[];
        MatMul(hidden, weights_l2, output);
        AddBias(output, bias_l2);

        return output[0];
    }

private:
    void ReLU(double &arr[]) {
        for(int i = 0; i < ArraySize(arr); i++)
            arr[i] = MathMax(0, arr[i]);
    }

    void MatMul(double &input[], double &weights[][], double &output[]) {
        // Matrix multiplication implementation
        // ... optimized for MQL5
    }
};
```

#### Feature Engineering for NNs

**Critical Features for Trading NNs:**

```mql5
class CFeatureExtractor {
public:
    void ExtractFeatures(double &features[]) {
        int idx = 0;

        // 1. Price-based features (normalized)
        features[idx++] = NormalizePrice(iClose(_Symbol, PERIOD_CURRENT, 1));
        features[idx++] = NormalizePrice(iOpen(_Symbol, PERIOD_CURRENT, 1));
        features[idx++] = NormalizePrice(iHigh(_Symbol, PERIOD_CURRENT, 1));
        features[idx++] = NormalizePrice(iLow(_Symbol, PERIOD_CURRENT, 1));

        // 2. Returns (more stationary than prices)
        features[idx++] = CalculateReturn(1);   // 1-bar return
        features[idx++] = CalculateReturn(5);   // 5-bar return
        features[idx++] = CalculateReturn(20);  // 20-bar return

        // 3. Volatility
        features[idx++] = CalculateVolatility(20);

        // 4. Technical indicators (normalized)
        features[idx++] = NormalizeIndicator(iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, 1));
        features[idx++] = NormalizeIndicator(iMACD(...));
        features[idx++] = NormalizeIndicator(iBands(...));

        // 5. Volume features
        features[idx++] = NormalizeVolume(iVolume(_Symbol, PERIOD_CURRENT, 1));

        // 6. Time features (cyclical encoding)
        features[idx++] = MathSin(2 * M_PI * TimeHour(iTime(_Symbol, PERIOD_CURRENT, 0)) / 24.0);
        features[idx++] = MathCos(2 * M_PI * TimeHour(iTime(_Symbol, PERIOD_CURRENT, 0)) / 24.0);

        // 7. Market regime indicators
        features[idx++] = DetectTrend();
        features[idx++] = DetectVolatilityRegime();
    }

private:
    double NormalizePrice(double price) {
        // Z-score normalization or min-max scaling
        double mean = CalculateMean(prices, 100);
        double std = CalculateStd(prices, 100);
        return (price - mean) / (std + 1e-8);
    }
};
```

### Training Data Best Practices

**1. Data Quality**
- Remove outliers and data errors
- Handle missing data (forward fill, interpolation)
- Ensure sufficient history (minimum 2-3 years)

**2. Feature Scaling**
```python
from sklearn.preprocessing import StandardScaler, RobustScaler

# Use RobustScaler for financial data (handles outliers better)
scaler = RobustScaler()
X_scaled = scaler.fit_transform(X_train)
```

**3. Train/Validation/Test Split**
```python
# Time-based split (NEVER shuffle financial data!)
train_size = int(0.7 * len(data))
val_size = int(0.15 * len(data))

X_train = data[:train_size]
X_val = data[train_size:train_size+val_size]
X_test = data[train_size+val_size:]
```

**4. Walk-Forward Optimization**
- Train on historical data
- Validate on out-of-sample data
- Retrain periodically (monthly/quarterly)
- Always test on truly unseen data

### Overfitting Prevention

**Critical Techniques:**

1. **Dropout** - Randomly disable neurons during training
2. **Early Stopping** - Stop when validation loss stops improving
3. **Regularization** - L1/L2 penalties on weights
4. **Cross-Validation** - Multiple train/test splits (time-aware)
5. **Ensemble Methods** - Average predictions from multiple models

```python
# Example: Early stopping
early_stop = tf.keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=10,
    restore_best_weights=True
)

model.fit(X_train, y_train,
          validation_data=(X_val, y_val),
          callbacks=[early_stop])
```

---

## Neuroplastic Modules - Adaptive Learning Systems

### Concept: Neuroplasticity in Trading

**Neuroplasticity** refers to the brain's ability to reorganize and adapt. In trading systems, neuroplastic modules continuously learn and adapt to changing market conditions without complete retraining.

### Why Neuroplastic Systems?

Markets are **non-stationary** - statistical properties change over time:
- Volatility regimes shift
- Correlations break down
- New patterns emerge
- Old patterns stop working

**Traditional ML problem:** Models degrade over time
**Neuroplastic solution:** Continuous online learning and adaptation

### Neuroplastic Architecture Types

#### 1. Online Learning

**Concept:** Update model incrementally with each new data point

```python
# Incremental learning with SGD
class OnlineLearner:
    def __init__(self, model):
        self.model = model
        self.optimizer = tf.keras.optimizers.SGD(learning_rate=0.001)

    def update(self, x_new, y_true):
        """Update model with single new observation"""
        with tf.GradientTape() as tape:
            y_pred = self.model(x_new, training=True)
            loss = tf.keras.losses.mse(y_true, y_pred)

        gradients = tape.gradient(loss, self.model.trainable_variables)
        self.optimizer.apply_gradients(zip(gradients, self.model.trainable_variables))

        return loss.numpy()
```

**MQL5 Implementation:**
```mql5
// Simplified online gradient descent
class COnlineNN {
private:
    double learning_rate;
    double weights[];

public:
    void UpdateWeights(double &features[], double actual, double predicted) {
        double error = actual - predicted;

        // Gradient descent update
        for(int i = 0; i < ArraySize(weights); i++) {
            double gradient = error * features[i];
            weights[i] += learning_rate * gradient;
        }
    }

    void AdaptToMarket() {
        // Decay learning rate over time
        learning_rate *= 0.999;

        // Prevent learning rate from becoming too small
        if(learning_rate < 0.00001) learning_rate = 0.00001;
    }
};
```

#### 2. Ensemble with Dynamic Weighting

**Concept:** Maintain multiple models, adjust weights based on recent performance

```mql5
class CAdaptiveEnsemble {
private:
    CNeuralNetwork* models[];   // Array of different models
    double weights[];           // Performance-based weights
    double performance[];       // Recent performance scores

public:
    CAdaptiveEnsemble() {
        ArrayResize(models, 5);      // 5 different models
        ArrayResize(weights, 5);
        ArrayResize(performance, 5);
        ArrayFill(weights, 0, 5, 0.2);  // Equal weights initially
    }

    double Predict(double &features[]) {
        double prediction = 0.0;

        // Weighted average of all models
        for(int i = 0; i < ArraySize(models); i++) {
            prediction += weights[i] * models[i].Predict(features);
        }

        return prediction;
    }

    void UpdatePerformance(double actual) {
        // Update performance metrics for each model
        for(int i = 0; i < ArraySize(models); i++) {
            double pred = models[i].Predict(last_features);
            double error = MathAbs(actual - pred);

            // Exponential moving average of errors
            performance[i] = 0.9 * performance[i] + 0.1 * (1.0 / (error + 0.001));
        }

        // Rebalance weights based on performance
        RebalanceWeights();
    }

    void RebalanceWeights() {
        // Softmax to convert performance to weights
        double sum = 0.0;
        double temp[];
        ArrayResize(temp, ArraySize(performance));

        for(int i = 0; i < ArraySize(performance); i++) {
            temp[i] = MathExp(performance[i]);
            sum += temp[i];
        }

        for(int i = 0; i < ArraySize(weights); i++) {
            weights[i] = temp[i] / sum;
        }
    }
};
```

#### 3. Market Regime Detection & Model Switching

**Concept:** Detect market regime, activate specialized models

```mql5
enum MARKET_REGIME {
    REGIME_TRENDING_UP,
    REGIME_TRENDING_DOWN,
    REGIME_RANGING,
    REGIME_HIGH_VOLATILITY,
    REGIME_LOW_VOLATILITY
};

class CRegimeAdaptiveSystem {
private:
    MARKET_REGIME current_regime;
    CNeuralNetwork* trend_model;
    CNeuralNetwork* range_model;
    CNeuralNetwork* volatility_model;

public:
    MARKET_REGIME DetectRegime() {
        // Calculate regime indicators
        double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 1);
        double atr_avg = CalculateATRAverage(50);

        double adx = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_MAIN, 1);

        // High volatility regime
        if(atr > 1.5 * atr_avg) return REGIME_HIGH_VOLATILITY;

        // Trending regime
        if(adx > 25) {
            double plus_di = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_PLUSDI, 1);
            double minus_di = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_MINUSDI, 1);
            return (plus_di > minus_di) ? REGIME_TRENDING_UP : REGIME_TRENDING_DOWN;
        }

        // Ranging regime
        return REGIME_RANGING;
    }

    double AdaptivePredict(double &features[]) {
        current_regime = DetectRegime();

        switch(current_regime) {
            case REGIME_TRENDING_UP:
            case REGIME_TRENDING_DOWN:
                return trend_model.Predict(features);

            case REGIME_RANGING:
                return range_model.Predict(features);

            case REGIME_HIGH_VOLATILITY:
            case REGIME_LOW_VOLATILITY:
                return volatility_model.Predict(features);
        }

        return 0.0;  // Default
    }
};
```

#### 4. Meta-Learning (Learning to Learn)

**Concept:** Higher-level learning system that adjusts learning parameters

```python
# Meta-learning: Adjust hyperparameters based on market conditions
class MetaLearner:
    def __init__(self):
        self.base_model = create_model()
        self.meta_params = {
            'learning_rate': 0.001,
            'dropout_rate': 0.2,
            'lookback_window': 20
        }

    def adjust_hyperparameters(self, market_metrics):
        """Adjust based on market volatility, trend strength, etc."""
        volatility = market_metrics['volatility']
        trend_strength = market_metrics['adx']

        # Higher volatility -> lower learning rate (be cautious)
        if volatility > 0.02:
            self.meta_params['learning_rate'] = 0.0005
        else:
            self.meta_params['learning_rate'] = 0.001

        # Strong trend -> longer lookback
        if trend_strength > 30:
            self.meta_params['lookback_window'] = 50
        else:
            self.meta_params['lookback_window'] = 20

        # Update model with new parameters
        self.base_model.compile(
            optimizer=tf.keras.optimizers.Adam(self.meta_params['learning_rate'])
        )
```

### Neuroplastic System Best Practices

**1. Concept Drift Detection**
```mql5
class CConceptDriftDetector {
private:
    double recent_errors[];
    double historical_error_mean;
    double historical_error_std;

public:
    bool DetectDrift() {
        double recent_mean = CalculateMean(recent_errors);

        // Statistical test: Is recent performance significantly worse?
        double z_score = (recent_mean - historical_error_mean) / historical_error_std;

        if(z_score > 2.0) {  // 2 standard deviations worse
            Print("Concept drift detected! Model needs retraining.");
            return true;
        }

        return false;
    }

    void TriggerRetraining() {
        // Signal to retrain model or switch to backup model
        // Export recent data for retraining
        ExportTrainingData();
    }
};
```

**2. Gradual Adaptation vs. Catastrophic Forgetting**

Balance between:
- **Too fast adaptation** → Overfits to noise
- **Too slow adaptation** → Doesn't track regime changes

```mql5
// Solution: Exponential weighting of old vs. new data
class CBalancedLearner {
private:
    double decay_factor;  // 0.95 = keep 95% old, 5% new

public:
    void UpdateModel(double &new_data[]) {
        // Weighted combination of old and new
        for(int i = 0; i < ArraySize(model_state); i++) {
            model_state[i] = decay_factor * model_state[i] +
                           (1 - decay_factor) * new_data[i];
        }
    }
};
```

**3. A/B Testing Framework**

```mql5
class CABTestingFramework {
private:
    CNeuralNetwork* model_A;  // Current production model
    CNeuralNetwork* model_B;  // New adaptive model

    double performance_A;
    double performance_B;

    int trades_A;
    int trades_B;

public:
    void RouteToModel(double &features[]) {
        // Randomly assign 80/20 to A/B
        if(MathRand() % 100 < 80) {
            // Use model A
            double signal = model_A.Predict(features);
            ExecuteTrade(signal, "Model_A");
            trades_A++;
        } else {
            // Use model B
            double signal = model_B.Predict(features);
            ExecuteTrade(signal, "Model_B");
            trades_B++;
        }
    }

    void EvaluatePerformance() {
        // After sufficient trades, compare performance
        if(trades_A > 100 && trades_B > 100) {
            if(performance_B > performance_A * 1.1) {  // 10% better
                Print("Model B is superior. Promoting to production.");
                PromoteModelB();
            }
        }
    }
};
```

**4. Continuous Monitoring Dashboard**

Track key metrics:
- Prediction accuracy over time
- Sharpe ratio by model
- Drawdown periods
- Regime detection accuracy
- Feature importance drift

### Hybrid Approach: Best of Both Worlds

```mql5
class CHybridNeuroplasticSystem {
private:
    // Static component: Well-tested base model
    CNeuralNetwork* base_model;

    // Adaptive component: Online learner
    COnlineNN* adaptive_layer;

    // Ensemble weight
    double base_weight;
    double adaptive_weight;

public:
    double Predict(double &features[]) {
        double base_pred = base_model.Predict(features);
        double adaptive_pred = adaptive_layer.Predict(features);

        // Weighted combination
        return base_weight * base_pred + adaptive_weight * adaptive_pred;
    }

    void Update(double actual) {
        // Update only the adaptive layer
        double adaptive_pred = adaptive_layer.Predict(last_features);
        adaptive_layer.UpdateWeights(last_features, actual, adaptive_pred);

        // Gradually adjust ensemble weights based on recent performance
        AdjustEnsembleWeights();
    }
};
```

## GitHub CLI Note

The `gh` CLI tool is **not available** in this environment. For GitHub operations, request information directly from users.

## Environment Details

- **Platform:** Linux 4.4.0
- **Working Directory:** `/home/user/tweny_fo_seven_trees_ixty_five`
- **Git Status:** Clean working directory
- **Current Branch:** `(Dynamic - check git status)`

## Quick Reference

### Check Repository Status
```bash
git status
git log --oneline -10
ls -la
```

### Common Operations
```bash
# View all files including hidden
ls -la

# Search for pattern in files
# Use Grep tool, not bash grep

# Read file contents
# Use Read tool, not cat

# Edit files
# Use Edit tool, not sed/awk
```

## Notes for AI Assistants

1. **Repository is minimal** - Only configuration files exist currently
2. **MPS project expected** - Based on gitignore configuration
3. **Branch naming is strict** - Must follow `claude/<name>-<session-id>` pattern
4. **No main branch specified** - This is a feature branch workflow
5. **Apache 2.0 licensed** - Open source, commercial use allowed

## Future Development Checklist

When adding MPS language definitions:
- [ ] Create language structure in `languages/` directory
- [ ] Define language aspects (structure, editor, typesystem, etc.)
- [ ] Add solutions in `solutions/` directory
- [ ] Configure build scripts
- [ ] Add tests
- [ ] Update this CLAUDE.md with project-specific conventions

## Questions to Clarify

If you're developing this repository, consider documenting:
1. What is the specific DSL being created?
2. What is the domain/problem being solved?
3. Are there specific MPS version requirements?
4. What build system is being used (Ant, Gradle)?
5. What are the testing requirements?

---

**Last Updated:** 2025-11-14
**Document Version:** 2.0.0
**Branch:** (varies)

## Changelog

### Version 2.0.0 (2025-11-14)
- Added comprehensive MetaTrader 5 (MT5) deep knowledge section
- Added MQL5 programming best practices and patterns
- Added Neural Network modules for trading with architectures and integration
- Added Neuroplastic adaptive learning systems with multiple approaches
- Updated project focus from pure MPS to MT5 algorithmic trading
- Updated directory structure to reflect MT5/Python/MPS hybrid architecture
- Added detailed code examples for EA development, NN integration, and adaptive systems
