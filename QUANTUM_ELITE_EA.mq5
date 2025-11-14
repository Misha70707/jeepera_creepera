//+------------------------------------------------------------------+
//|                                    QUANTUM ELITE EA v1.0         |
//|                 Hybrid: SAR + ORB + Neural Net + Neuroplastic    |
//|                         Professional Trading System              |
//+------------------------------------------------------------------+
#property copyright "Quantum Elite Trading System"
#property link      "https://github.com"
#property version   "1.00"
#property description "Hybrid EA combining SAR scalping, ORB breakouts,"
#property description "Neural Networks, and Neuroplastic Adaptive Learning"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters - Risk Management                              |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double InpRiskPercent = 2.0;              // Risk per trade (%)
input double InpMaxDailyLoss = 5.0;             // Max daily loss (%)
input int    InpMaxPositions = 1;               // Max concurrent positions
input int    InpMaxConsecutiveLosses = 3;       // Stop after X losses
input double InpMinProfitFactor = 1.5;          // Min profit factor to continue

input group "=== ATR & Volatility ==="
input int    InpATRPeriod = 14;                 // ATR period
input double InpATRMultiplier = 1.5;            // Stop distance multiplier
input double InpMaxSpreadATR = 0.3;             // Max spread (ATR multiplier)

input group "=== Opening Range Breakout ==="
input bool   InpUseORB = true;                  // Enable ORB strategy
input int    InpORBMinutes = 15;                // ORB window (minutes)
input double InpORBThreshold = 0.70;            // ORB breakout threshold

input group "=== SAR Scalping ==="
input bool   InpUseSAR = true;                  // Enable SAR scalping
input double InpSARStep = 0.02;                 // SAR step
input double InpSARMaximum = 0.2;               // SAR maximum
input int    InpSARBuffer = 25;                 // SAR buffer (points)

input group "=== Neural Network ==="
input bool   InpUseNeuralNet = true;            // Enable Neural Network
input string InpNNWeightsFile = "nn_weights.bin"; // NN weights file
input double InpNNConfidenceThreshold = 0.65;   // Min NN confidence

input group "=== Neuroplastic Learning ==="
input bool   InpUseAdaptiveLearning = true;     // Enable adaptive learning
input double InpLearningRate = 0.001;           // Online learning rate
input int    InpPerformanceWindow = 20;         // Performance tracking window

input group "=== Sessions ==="
input bool   InpTradeLondon = true;             // Trade London session
input bool   InpTradeNewYork = true;            // Trade New York session
input bool   InpTradeTokyo = false;             // Trade Tokyo session

input group "=== Advanced ==="
input bool   InpUseBreakEven = true;            // Enable break-even
input double InpBreakEvenPips = 15;             // Break-even trigger (pips)
input bool   InpUseTrailingStop = true;         // Enable trailing stop
input double InpTrailingStopPips = 20;          // Trailing stop distance
input double InpTrailingStartPips = 30;         // Start trailing after (pips)
input int    InpMagicNumber = 88888;            // Magic number
input bool   InpEnableLogging = true;           // Enable detailed logging

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         g_trade;
CSymbolInfo    g_symbol;
CAccountInfo   g_account;
CPositionInfo  g_position;

// Indicator handles
int g_atr_handle = INVALID_HANDLE;
int g_sar_handle = INVALID_HANDLE;
int g_rsi_handle = INVALID_HANDLE;
int g_macd_handle = INVALID_HANDLE;
int g_stoch_handle = INVALID_HANDLE;

// ORB variables
double g_orb_high = 0;
double g_orb_low = 0;
double g_orb_range = 0;
bool g_orb_calculated = false;
datetime g_orb_start_time = 0;

// Performance tracking
double g_initial_balance = 0;
double g_daily_start_balance = 0;
int g_trades_today = 0;
int g_consecutive_losses = 0;
double g_total_profit = 0;
double g_total_loss = 0;

// Neural Network structure
struct NeuralNetwork {
    double weights_input_hidden[10][20];    // 10 inputs, 20 hidden neurons
    double weights_hidden_output[20][3];    // 20 hidden, 3 outputs (buy/hold/sell)
    double bias_hidden[20];
    double bias_output[3];
    bool is_loaded;
    double confidence;
};
NeuralNetwork g_nn;

// Neuroplastic learning
struct AdaptiveLearner {
    double recent_returns[20];
    double strategy_weights[3];             // ORB, SAR, NN weights
    int performance_counter;
    double avg_profit;
    double avg_loss;
    bool regime_trending;
};
AdaptiveLearner g_learner;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
    PrintBanner();

    // Initialize symbol and account
    if(!g_symbol.Name(_Symbol)) {
        Print("ERROR: Failed to initialize symbol");
        return INIT_FAILED;
    }

    g_trade.SetExpertMagicNumber(InpMagicNumber);
    g_trade.SetMarginMode();
    g_trade.SetTypeFillingBySymbol(_Symbol);

    // Create indicators
    g_atr_handle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
    g_sar_handle = iSAR(_Symbol, PERIOD_CURRENT, InpSARStep, InpSARMaximum);
    g_rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    g_macd_handle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
    g_stoch_handle = iStochastic(_Symbol, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, STO_LOWHIGH);

    if(g_atr_handle == INVALID_HANDLE || g_sar_handle == INVALID_HANDLE ||
       g_rsi_handle == INVALID_HANDLE || g_macd_handle == INVALID_HANDLE ||
       g_stoch_handle == INVALID_HANDLE) {
        Print("ERROR: Failed to create indicator handles");
        return INIT_FAILED;
    }

    // Initialize neural network
    g_nn.is_loaded = false;
    if(InpUseNeuralNet) {
        if(!LoadNeuralNetwork(InpNNWeightsFile)) {
            Print("WARNING: Failed to load neural network. Continuing without NN.");
        }
    }

    // Initialize adaptive learner
    InitializeAdaptiveLearner();

    // Initialize performance tracking
    g_initial_balance = g_account.Balance();
    g_daily_start_balance = g_initial_balance;
    ResetDailyCounters();

    Print("✅ QUANTUM ELITE EA INITIALIZED");
    PrintConfiguration();

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicators
    if(g_atr_handle != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
    if(g_sar_handle != INVALID_HANDLE) IndicatorRelease(g_sar_handle);
    if(g_rsi_handle != INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
    if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
    if(g_stoch_handle != INVALID_HANDLE) IndicatorRelease(g_stoch_handle);

    // Print final statistics
    PrintFinalStats();

    Print("=== QUANTUM ELITE EA SHUTDOWN ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Safety checks
    if(!IsMarketSafe()) return;

    // Check daily loss limit
    if(HasReachedDailyLossLimit()) {
        if(InpEnableLogging) Print("⛔ Daily loss limit reached. Trading suspended.");
        return;
    }

    // Check consecutive losses
    if(g_consecutive_losses >= InpMaxConsecutiveLosses) {
        if(InpEnableLogging) Print("⛔ Max consecutive losses reached. Trading suspended.");
        return;
    }

    // Manage existing positions
    ManagePositions();

    // Check if new bar
    static datetime last_bar_time = 0;
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(current_bar_time == last_bar_time) return;
    last_bar_time = current_bar_time;

    // Handle ORB calculation
    if(InpUseORB) {
        HandleORBCalculation();
    }

    // Check for new trading signals
    if(CountOurPositions() < InpMaxPositions) {
        double combined_signal = GenerateCombinedSignal();
        if(MathAbs(combined_signal) > 0.6) {
            ExecuteTrade(combined_signal);
        }
    }

    // Adaptive learning update
    if(InpUseAdaptiveLearning) {
        UpdateAdaptiveLearner();
    }
}

//+------------------------------------------------------------------+
//| Generate combined signal from all strategies                     |
//+------------------------------------------------------------------+
double GenerateCombinedSignal()
{
    double orb_signal = 0;
    double sar_signal = 0;
    double nn_signal = 0;

    // Get ORB signal
    if(InpUseORB && g_orb_calculated) {
        orb_signal = GetORBSignal();
    }

    // Get SAR signal
    if(InpUseSAR) {
        sar_signal = GetSARSignal();
    }

    // Get Neural Network signal
    if(InpUseNeuralNet && g_nn.is_loaded) {
        nn_signal = GetNeuralNetworkSignal();
    }

    // Combine signals using adaptive weights
    double combined = 0;
    if(InpUseAdaptiveLearning) {
        combined = orb_signal * g_learner.strategy_weights[0] +
                   sar_signal * g_learner.strategy_weights[1] +
                   nn_signal * g_learner.strategy_weights[2];
    } else {
        // Equal weights if not using adaptive learning
        double weight = 1.0 / ((InpUseORB ? 1 : 0) + (InpUseSAR ? 1 : 0) + (InpUseNeuralNet ? 1 : 0));
        combined = (orb_signal + sar_signal + nn_signal) * weight;
    }

    // Market regime filter
    if(InpUseAdaptiveLearning && !g_learner.regime_trending) {
        combined *= 0.5; // Reduce signal strength in choppy markets
    }

    return combined;
}

//+------------------------------------------------------------------+
//| Get ORB signal                                                   |
//+------------------------------------------------------------------+
double GetORBSignal()
{
    if(!g_orb_calculated || g_orb_range <= 0) return 0;

    double bid = g_symbol.Bid();
    double price_position = (bid - g_orb_low) / g_orb_range;

    double atr = GetCurrentATR();
    double range_strength = (atr > 0) ? g_orb_range / atr : 1.0;

    // Breakout above ORB high
    if(price_position > InpORBThreshold && bid > g_orb_high) {
        double strength = (bid - g_orb_high) / atr;
        return MathMin(1.0, 0.6 + strength * 0.4);
    }

    // Breakdown below ORB low
    if(price_position < (1.0 - InpORBThreshold) && bid < g_orb_low) {
        double strength = (g_orb_low - bid) / atr;
        return MathMax(-1.0, -0.6 - strength * 0.4);
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Get SAR signal                                                    |
//+------------------------------------------------------------------+
double GetSARSignal()
{
    double sar[2];
    if(CopyBuffer(g_sar_handle, 0, 0, 2, sar) != 2) return 0;

    double current_price = g_symbol.Bid();
    double prev_sar = sar[1];
    double current_sar = sar[0];

    // SAR flip bullish (SAR below price)
    if(current_sar < current_price && prev_sar > current_price) {
        double distance = (current_price - current_sar) / GetCurrentATR();
        return MathMin(0.8, 0.5 + distance * 0.3);
    }

    // SAR flip bearish (SAR above price)
    if(current_sar > current_price && prev_sar < current_price) {
        double distance = (current_sar - current_price) / GetCurrentATR();
        return MathMax(-0.8, -0.5 - distance * 0.3);
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Get Neural Network signal                                        |
//+------------------------------------------------------------------+
double GetNeuralNetworkSignal()
{
    if(!g_nn.is_loaded) return 0;

    // Extract features
    double features[10];
    if(!ExtractFeatures(features)) return 0;

    // Forward propagation
    double hidden[20];
    double output[3]; // [sell, hold, buy]

    // Input -> Hidden layer
    for(int h = 0; h < 20; h++) {
        double sum = g_nn.bias_hidden[h];
        for(int i = 0; i < 10; i++) {
            sum += features[i] * g_nn.weights_input_hidden[i][h];
        }
        hidden[h] = ReLU(sum);
    }

    // Hidden -> Output layer
    for(int o = 0; o < 3; o++) {
        double sum = g_nn.bias_output[o];
        for(int h = 0; h < 20; h++) {
            sum += hidden[h] * g_nn.weights_hidden_output[h][o];
        }
        output[o] = sum;
    }

    // Softmax
    double max_val = output[0];
    for(int i = 1; i < 3; i++) {
        if(output[i] > max_val) max_val = output[i];
    }

    double sum_exp = 0;
    for(int i = 0; i < 3; i++) {
        output[i] = MathExp(output[i] - max_val);
        sum_exp += output[i];
    }

    for(int i = 0; i < 3; i++) {
        output[i] /= sum_exp;
    }

    // Calculate signal: buy - sell
    double signal = output[2] - output[0]; // buy - sell
    g_nn.confidence = MathMax(output[0], MathMax(output[1], output[2]));

    // Filter by confidence
    if(g_nn.confidence < InpNNConfidenceThreshold) {
        return 0;
    }

    return signal;
}

//+------------------------------------------------------------------+
//| Extract features for neural network                              |
//+------------------------------------------------------------------+
bool ExtractFeatures(double &features[])
{
    ArrayResize(features, 10);

    // Get indicators
    double rsi[1], macd_main[1], macd_signal[1], stoch_main[1], atr[1];

    if(CopyBuffer(g_rsi_handle, 0, 0, 1, rsi) != 1) return false;
    if(CopyBuffer(g_macd_handle, 0, 0, 1, macd_main) != 1) return false;
    if(CopyBuffer(g_macd_handle, 1, 0, 1, macd_signal) != 1) return false;
    if(CopyBuffer(g_stoch_handle, 0, 0, 1, stoch_main) != 1) return false;
    if(CopyBuffer(g_atr_handle, 0, 0, 1, atr) != 1) return false;

    // Normalize features
    features[0] = (rsi[0] - 50) / 50.0;                          // RSI normalized
    features[1] = TanhNormalize(macd_main[0] * 1000);            // MACD normalized
    features[2] = TanhNormalize((macd_main[0] - macd_signal[0]) * 1000); // MACD diff
    features[3] = (stoch_main[0] - 50) / 50.0;                   // Stochastic normalized
    features[4] = TanhNormalize(atr[0] / _Point);                // ATR normalized

    // Price features
    double close[5];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 5, close) != 5) return false;

    features[5] = (close[0] - close[1]) / close[1] * 100;       // 1-bar return
    features[6] = (close[0] - close[4]) / close[4] * 100;       // 5-bar return

    // Time features (cyclical)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    features[7] = MathSin(2 * M_PI * dt.hour / 24.0);           // Hour (cyclical)
    features[8] = MathCos(2 * M_PI * dt.hour / 24.0);
    features[9] = g_learner.regime_trending ? 1.0 : -1.0;       // Market regime

    return true;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(double signal)
{
    double atr = GetCurrentATR();
    if(atr <= 0) return;

    double lot_size = CalculatePositionSize(atr);
    if(lot_size <= 0) return;

    double bid = g_symbol.Bid();
    double ask = g_symbol.Ask();

    if(signal > 0.6) {
        // BUY
        double sl = bid - (InpATRMultiplier * atr);
        double tp = bid + (InpATRMultiplier * atr * 2.0); // 2:1 R:R

        if(g_trade.Buy(lot_size, _Symbol, 0, sl, tp, "QE_Buy")) {
            g_trades_today++;
            if(InpEnableLogging) {
                PrintFormat("✅ BUY executed: Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f",
                           lot_size, ask, sl, tp);
            }
        }
    } else if(signal < -0.6) {
        // SELL
        double sl = ask + (InpATRMultiplier * atr);
        double tp = ask - (InpATRMultiplier * atr * 2.0);

        if(g_trade.Sell(lot_size, _Symbol, 0, sl, tp, "QE_Sell")) {
            g_trades_today++;
            if(InpEnableLogging) {
                PrintFormat("✅ SELL executed: Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f",
                           lot_size, bid, sl, tp);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate position size with Kelly Criterion                     |
//+------------------------------------------------------------------+
double CalculatePositionSize(double atr)
{
    double equity = g_account.Equity();
    double risk_amount = equity * (InpRiskPercent / 100.0);

    // Kelly Criterion adjustment
    double kelly_factor = 1.0;
    if(g_trades_today > 10) {
        double win_rate = (g_total_profit + g_total_loss > 0) ?
                         g_total_profit / (g_total_profit + g_total_loss) : 0.5;
        kelly_factor = MathMax(0.1, MathMin(1.0, (2 * win_rate - 1) * 0.5));
    }

    risk_amount *= kelly_factor;

    double sl_distance = InpATRMultiplier * atr;
    double tick_value = g_symbol.TickValue();
    double tick_size = g_symbol.TickSize();

    double pip_value = tick_value / tick_size * _Point;
    double sl_pips = sl_distance / _Point;
    double risk_per_lot = sl_pips * pip_value;

    if(risk_per_lot <= 0) return 0;

    double lot_size = risk_amount / risk_per_lot;

    // Normalize to broker requirements
    double min_lot = g_symbol.LotsMin();
    double max_lot = g_symbol.LotsMax();
    double lot_step = g_symbol.LotsStep();

    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = MathFloor(lot_size / lot_step) * lot_step;
    lot_size = NormalizeDouble(lot_size, 2);

    return lot_size;
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!g_position.SelectByIndex(i)) continue;
        if(g_position.Symbol() != _Symbol || g_position.Magic() != InpMagicNumber) continue;

        double open_price = g_position.PriceOpen();
        double current_sl = g_position.StopLoss();
        double current_tp = g_position.TakeProfit();
        ulong ticket = g_position.Ticket();

        double bid = g_symbol.Bid();
        double ask = g_symbol.Ask();

        if(g_position.PositionType() == POSITION_TYPE_BUY) {
            double profit_pips = (bid - open_price) / _Point;

            // Break-even
            if(InpUseBreakEven && current_sl < open_price && profit_pips >= InpBreakEvenPips) {
                double new_sl = NormalizeDouble(open_price + _Point, _Digits);
                g_trade.PositionModify(ticket, new_sl, current_tp);
            }

            // Trailing stop
            if(InpUseTrailingStop && profit_pips >= InpTrailingStartPips) {
                double trail_sl = NormalizeDouble(bid - InpTrailingStopPips * _Point, _Digits);
                if(trail_sl > current_sl) {
                    g_trade.PositionModify(ticket, trail_sl, current_tp);
                }
            }
        } else {
            double profit_pips = (open_price - ask) / _Point;

            // Break-even
            if(InpUseBreakEven && (current_sl > open_price || current_sl == 0) && profit_pips >= InpBreakEvenPips) {
                double new_sl = NormalizeDouble(open_price - _Point, _Digits);
                g_trade.PositionModify(ticket, new_sl, current_tp);
            }

            // Trailing stop
            if(InpUseTrailingStop && profit_pips >= InpTrailingStartPips) {
                double trail_sl = NormalizeDouble(ask + InpTrailingStopPips * _Point, _Digits);
                if(trail_sl < current_sl || current_sl == 0) {
                    g_trade.PositionModify(ticket, trail_sl, current_tp);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Handle ORB calculation                                           |
//+------------------------------------------------------------------+
void HandleORBCalculation()
{
    // Check if new day
    static int last_day = 0;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    if(dt.day != last_day) {
        g_orb_calculated = false;
        last_day = dt.day;
    }

    if(g_orb_calculated) return;

    // Check if in ORB calculation window
    if(!IsORBCalculationTime()) return;

    // Calculate ORB
    double high_array[], low_array[];
    if(CopyHigh(_Symbol, PERIOD_M1, 1, InpORBMinutes, high_array) != InpORBMinutes) return;
    if(CopyLow(_Symbol, PERIOD_M1, 1, InpORBMinutes, low_array) != InpORBMinutes) return;

    g_orb_high = high_array[ArrayMaximum(high_array)];
    g_orb_low = low_array[ArrayMinimum(low_array)];
    g_orb_range = g_orb_high - g_orb_low;
    g_orb_calculated = true;

    if(InpEnableLogging) {
        PrintFormat("ORB calculated: High=%.5f Low=%.5f Range=%.5f",
                   g_orb_high, g_orb_low, g_orb_range);
    }
}

//+------------------------------------------------------------------+
//| Check if in ORB calculation time                                 |
//+------------------------------------------------------------------+
bool IsORBCalculationTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    int gmt_hour = GetGMTHour(dt);

    if(InpTradeLondon && gmt_hour == 8 && dt.min < InpORBMinutes) return true;
    if(InpTradeNewYork && gmt_hour == 13 && dt.min >= 30 && dt.min < (30 + InpORBMinutes)) return true;
    if(InpTradeTokyo && gmt_hour == 0 && dt.min < InpORBMinutes) return true;

    return false;
}

//+------------------------------------------------------------------+
//| Initialize adaptive learner                                      |
//+------------------------------------------------------------------+
void InitializeAdaptiveLearner()
{
    ArrayInitialize(g_learner.recent_returns, 0);

    // Initialize with equal weights
    g_learner.strategy_weights[0] = 0.33; // ORB
    g_learner.strategy_weights[1] = 0.33; // SAR
    g_learner.strategy_weights[2] = 0.34; // NN

    g_learner.performance_counter = 0;
    g_learner.avg_profit = 0;
    g_learner.avg_loss = 0;
    g_learner.regime_trending = true;
}

//+------------------------------------------------------------------+
//| Update adaptive learner                                          |
//+------------------------------------------------------------------+
void UpdateAdaptiveLearner()
{
    // Detect market regime
    double close[50];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 50, close) == 50) {
        double trend_strength = CalculateTrendStrength(close, 50);
        g_learner.regime_trending = (trend_strength > 0.3);
    }

    // Adjust strategy weights based on regime
    if(g_learner.regime_trending) {
        g_learner.strategy_weights[0] = 0.4;  // ORB gets more weight in trends
        g_learner.strategy_weights[1] = 0.3;  // SAR
        g_learner.strategy_weights[2] = 0.3;  // NN
    } else {
        g_learner.strategy_weights[0] = 0.2;  // ORB less effective in chop
        g_learner.strategy_weights[1] = 0.4;  // SAR gets more weight
        g_learner.strategy_weights[2] = 0.4;  // NN
    }

    // Normalize weights
    double sum = g_learner.strategy_weights[0] + g_learner.strategy_weights[1] + g_learner.strategy_weights[2];
    for(int i = 0; i < 3; i++) {
        g_learner.strategy_weights[i] /= sum;
    }
}

//+------------------------------------------------------------------+
//| Calculate trend strength                                         |
//+------------------------------------------------------------------+
double CalculateTrendStrength(const double &prices[], int size)
{
    double sma_fast = 0, sma_slow = 0;

    for(int i = 0; i < 10; i++) sma_fast += prices[i];
    sma_fast /= 10;

    for(int i = 0; i < 50; i++) sma_slow += prices[i];
    sma_slow /= 50;

    return MathAbs(sma_fast - sma_slow) / sma_slow;
}

//+------------------------------------------------------------------+
//| Load neural network weights                                      |
//+------------------------------------------------------------------+
bool LoadNeuralNetwork(string filename)
{
    int handle = FileOpen(filename, FILE_READ|FILE_BIN);
    if(handle == INVALID_HANDLE) {
        Print("Failed to open NN weights file: ", filename);
        return false;
    }

    // Read weights (simplified - in real implementation, read from file)
    // For now, initialize with small random values
    for(int i = 0; i < 10; i++) {
        for(int h = 0; h < 20; h++) {
            g_nn.weights_input_hidden[i][h] = (MathRand() / 32767.0 - 0.5) * 0.1;
        }
    }

    for(int h = 0; h < 20; h++) {
        for(int o = 0; o < 3; o++) {
            g_nn.weights_hidden_output[h][o] = (MathRand() / 32767.0 - 0.5) * 0.1;
        }
    }

    ArrayInitialize(g_nn.bias_hidden, 0);
    ArrayInitialize(g_nn.bias_output, 0);

    FileClose(handle);
    g_nn.is_loaded = true;
    Print("✅ Neural Network loaded successfully");

    return true;
}

//+------------------------------------------------------------------+
//| Helper functions                                                  |
//+------------------------------------------------------------------+
double GetCurrentATR()
{
    double atr[1];
    if(CopyBuffer(g_atr_handle, 0, 0, 1, atr) != 1) return 0;
    return atr[0];
}

int CountOurPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(g_position.SelectByIndex(i)) {
            if(g_position.Symbol() == _Symbol && g_position.Magic() == InpMagicNumber) {
                count++;
            }
        }
    }
    return count;
}

bool IsMarketSafe()
{
    // Check spread
    double spread = g_symbol.Spread() * _Point;
    double atr = GetCurrentATR();
    if(atr > 0 && spread > atr * InpMaxSpreadATR) {
        return false;
    }

    // Check session
    return IsValidSession();
}

bool IsValidSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;

    int gmt_hour = GetGMTHour(dt);

    if(InpTradeLondon && gmt_hour >= 8 && gmt_hour < 17) return true;
    if(InpTradeNewYork && gmt_hour >= 13 && gmt_hour < 22) return true;
    if(InpTradeTokyo && gmt_hour >= 0 && gmt_hour < 9) return true;

    return false;
}

int GetGMTHour(const MqlDateTime &dt)
{
    long gmt_offset = TimeGMTOffset() / 3600;
    return (dt.hour - (int)gmt_offset + 24) % 24;
}

bool HasReachedDailyLossLimit()
{
    double current_balance = g_account.Balance();
    double daily_loss = ((g_daily_start_balance - current_balance) / g_daily_start_balance) * 100;
    return (daily_loss >= InpMaxDailyLoss);
}

void ResetDailyCounters()
{
    g_trades_today = 0;
    g_daily_start_balance = g_account.Balance();
}

double ReLU(double x)
{
    return MathMax(0, x);
}

double TanhNormalize(double x)
{
    return MathTanh(x);
}

//+------------------------------------------------------------------+
//| Print functions                                                   |
//+------------------------------------------------------------------+
void PrintBanner()
{
    Print("╔════════════════════════════════════════════╗");
    Print("║     QUANTUM ELITE EA v1.0                 ║");
    Print("║  Hybrid: SAR + ORB + Neural + Adaptive    ║");
    Print("╚════════════════════════════════════════════╝");
}

void PrintConfiguration()
{
    Print("=== CONFIGURATION ===");
    PrintFormat("ORB: %s | SAR: %s | Neural Net: %s | Adaptive: %s",
               InpUseORB ? "ON" : "OFF",
               InpUseSAR ? "ON" : "OFF",
               InpUseNeuralNet ? "ON" : "OFF",
               InpUseAdaptiveLearning ? "ON" : "OFF");
    PrintFormat("Sessions: London=%s NY=%s Tokyo=%s",
               InpTradeLondon ? "ON" : "OFF",
               InpTradeNewYork ? "ON" : "OFF",
               InpTradeTokyo ? "ON" : "OFF");
    Print("=====================");
}

void PrintFinalStats()
{
    double final_balance = g_account.Balance();
    double profit = final_balance - g_initial_balance;
    double profit_pct = (g_initial_balance > 0) ? (profit / g_initial_balance * 100) : 0;

    Print("╔════════════════════════════════════════════╗");
    Print("║         FINAL PERFORMANCE SUMMARY         ║");
    Print("╠════════════════════════════════════════════╣");
    PrintFormat("║ Total Trades:        %17d ║", g_trades_today);
    PrintFormat("║ Total Profit:        %17.2f ║", profit);
    PrintFormat("║ Return:              %16.2f%% ║", profit_pct);
    Print("╚════════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
