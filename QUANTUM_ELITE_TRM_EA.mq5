//+------------------------------------------------------------------+
//|                              QUANTUM ELITE TRM EA v2.0           |
//|              Hybrid: SAR + ORB + TRM (Tiny Recursive Model)      |
//|                    Revolutionary Recursive AI Trading            |
//+------------------------------------------------------------------+
#property copyright "Quantum Elite TRM Trading System"
#property link      "https://github.com"
#property version   "2.00"
#property description "Hybrid EA with TRM Recursive Reasoning AI"
#property description "Combines SAR, ORB, and 6-step recursive AI thinking"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double InpRiskPercent = 2.0;              // Risk per trade (%)
input double InpMaxDailyLoss = 5.0;             // Max daily loss (%)
input int    InpMaxPositions = 1;               // Max concurrent positions
input int    InpMaxConsecutiveLosses = 3;       // Stop after X losses

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

input group "=== TRM (Tiny Recursive Model) ==="
input bool   InpUseTRM = true;                  // Enable TRM AI
input string InpTRMWeightsFile = "trm_weights.bin"; // TRM weights file
input double InpTRMConfidenceThreshold = 0.65;  // Min TRM confidence
input int    InpTRMIterations = 6;              // Recursive iterations

input group "=== Adaptive Learning ==="
input bool   InpUseAdaptiveLearning = true;     // Enable adaptive learning

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
input int    InpMagicNumber = 99999;            // Magic number
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

// Performance tracking
double g_initial_balance = 0;
double g_daily_start_balance = 0;
int g_trades_today = 0;
int g_consecutive_losses = 0;

// TRM (Tiny Recursive Model) structure
struct TinyRecursiveModel {
    // Architecture
    int input_size;      // 10
    int latent_size;     // 64
    int output_size;     // 3
    int num_iterations;  // 6

    // Weights - Layer 1: (input + output + latent) -> hidden
    double W1[256][141];  // 141 = 10 + 3 + 64 + 64, 256 = hidden size
    double b1[256];

    // Weights - Layer 2: hidden -> (latent + output)
    double W2[67][256];   // 67 = 64 + 3
    double b2[67];

    bool is_loaded;
    double confidence;
};

TinyRecursiveModel g_trm;

// Adaptive learner
struct AdaptiveLearner {
    double strategy_weights[3];  // ORB, SAR, TRM weights
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

    // Initialize TRM
    g_trm.is_loaded = false;
    if(InpUseTRM) {
        if(!LoadTRMWeights(InpTRMWeightsFile)) {
            Print("WARNING: Failed to load TRM weights. Will use ORB+SAR only.");
        }
    }

    // Initialize adaptive learner
    InitializeAdaptiveLearner();

    // Initialize performance tracking
    g_initial_balance = g_account.Balance();
    g_daily_start_balance = g_initial_balance;
    g_trades_today = 0;
    g_consecutive_losses = 0;

    Print("✅ QUANTUM ELITE TRM EA INITIALIZED");
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

    PrintFinalStats();
    Print("=== QUANTUM ELITE TRM EA SHUTDOWN ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Safety checks
    if(!IsMarketSafe()) return;

    // Check daily loss limit
    if(HasReachedDailyLossLimit()) return;

    // Check consecutive losses
    if(g_consecutive_losses >= InpMaxConsecutiveLosses) return;

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
    double trm_signal = 0;

    // Get ORB signal
    if(InpUseORB && g_orb_calculated) {
        orb_signal = GetORBSignal();
    }

    // Get SAR signal
    if(InpUseSAR) {
        sar_signal = GetSARSignal();
    }

    // Get TRM signal (recursive AI!)
    if(InpUseTRM && g_trm.is_loaded) {
        trm_signal = GetTRMSignal();
    }

    // Combine signals using adaptive weights
    double combined = orb_signal * g_learner.strategy_weights[0] +
                      sar_signal * g_learner.strategy_weights[1] +
                      trm_signal * g_learner.strategy_weights[2];

    // Market regime filter
    if(!g_learner.regime_trending) {
        combined *= 0.5; // Reduce signal strength in choppy markets
    }

    return combined;
}

//+------------------------------------------------------------------+
//| Get TRM signal using recursive reasoning                         |
//+------------------------------------------------------------------+
double GetTRMSignal()
{
    if(!g_trm.is_loaded) return 0;

    // Extract features
    double features[10];
    if(!ExtractFeatures(features)) return 0;

    // TRM RECURSIVE FORWARD PASS
    // Initialize answer and latent
    double answer[3];
    answer[0] = 0.33; // SELL
    answer[1] = 0.34; // HOLD
    answer[2] = 0.33; // BUY

    double latent[64];
    ArrayInitialize(latent, 0);

    // Recursive refinement (6 iterations!)
    for(int iter = 0; iter < g_trm.num_iterations; iter++) {
        // Combine: [features(10) + answer(3) + latent(64)] = 77
        double combined[77];

        // Copy features
        for(int i = 0; i < 10; i++) combined[i] = features[i];

        // Copy answer
        for(int i = 0; i < 3; i++) combined[10 + i] = answer[i];

        // Copy latent
        for(int i = 0; i < 64; i++) combined[13 + i] = latent[i];

        // Forward through Layer 1: combined -> hidden
        double hidden[256];
        for(int h = 0; h < 256; h++) {
            double sum = g_trm.b1[h];
            for(int i = 0; i < 77; i++) {
                sum += combined[i] * g_trm.W1[h][i];
            }
            hidden[h] = ReLU(sum);
        }

        // Forward through Layer 2: hidden -> [latent(64) + output(3)]
        double output[67];
        for(int o = 0; o < 67; o++) {
            double sum = g_trm.b2[o];
            for(int h = 0; h < 256; h++) {
                sum += hidden[h] * g_trm.W2[o][h];
            }
            output[o] = sum;
        }

        // Split output into new latent and raw answer
        for(int i = 0; i < 64; i++) {
            latent[i] = output[i];
        }

        double raw_answer[3];
        for(int i = 0; i < 3; i++) {
            raw_answer[i] = output[64 + i];
        }

        // Softmax on raw answer
        Softmax(raw_answer, answer, 3);

        // Log reasoning if enabled
        if(InpEnableLogging && iter == g_trm.num_iterations - 1) {
            PrintFormat("🧠 TRM Iteration %d: SELL=%.3f HOLD=%.3f BUY=%.3f",
                       iter + 1, answer[0], answer[1], answer[2]);
        }
    }

    // Calculate signal: BUY - SELL
    double signal = answer[2] - answer[0];
    g_trm.confidence = MathMax(answer[0], MathMax(answer[1], answer[2]));

    // Filter by confidence
    if(g_trm.confidence < InpTRMConfidenceThreshold) {
        return 0;
    }

    if(InpEnableLogging) {
        PrintFormat("✅ TRM Final: Signal=%.3f Confidence=%.3f", signal, g_trm.confidence);
    }

    return signal;
}

//+------------------------------------------------------------------+
//| ReLU activation                                                   |
//+------------------------------------------------------------------+
double ReLU(double x)
{
    return MathMax(0, x);
}

//+------------------------------------------------------------------+
//| Softmax activation                                                |
//+------------------------------------------------------------------+
void Softmax(const double &input[], double &output[], int size)
{
    double max_val = input[0];
    for(int i = 1; i < size; i++) {
        if(input[i] > max_val) max_val = input[i];
    }

    double sum = 0;
    for(int i = 0; i < size; i++) {
        output[i] = MathExp(input[i] - max_val);
        sum += output[i];
    }

    for(int i = 0; i < size; i++) {
        output[i] /= sum;
    }
}

//+------------------------------------------------------------------+
//| Load TRM weights from file                                        |
//+------------------------------------------------------------------+
bool LoadTRMWeights(string filename)
{
    int handle = FileOpen(filename, FILE_READ|FILE_BIN);
    if(handle == INVALID_HANDLE) {
        PrintFormat("Failed to open TRM weights file: %s", filename);
        return false;
    }

    // Read architecture
    int arch[4];
    for(int i = 0; i < 4; i++) {
        arch[i] = FileReadInteger(handle, INT_VALUE);
    }

    g_trm.input_size = arch[0];      // 10
    g_trm.latent_size = arch[1];     // 64
    g_trm.output_size = arch[2];     // 3
    g_trm.num_iterations = arch[3];  // 6

    // Combined input size: input + output + latent = 10 + 3 + 64 = 77
    int combined_size = g_trm.input_size + g_trm.output_size + g_trm.latent_size;
    int hidden_size = 256;
    int output_combined = g_trm.latent_size + g_trm.output_size; // 67

    // Read W1: (combined_size x hidden_size)
    for(int i = 0; i < combined_size; i++) {
        for(int j = 0; j < hidden_size; j++) {
            g_trm.W1[j][i] = FileReadDouble(handle);
        }
    }

    // Read b1: (hidden_size)
    for(int i = 0; i < hidden_size; i++) {
        g_trm.b1[i] = FileReadDouble(handle);
    }

    // Read W2: (hidden_size x output_combined)
    for(int i = 0; i < hidden_size; i++) {
        for(int j = 0; j < output_combined; j++) {
            g_trm.W2[j][i] = FileReadDouble(handle);
        }
    }

    // Read b2: (output_combined)
    for(int i = 0; i < output_combined; i++) {
        g_trm.b2[i] = FileReadDouble(handle);
    }

    FileClose(handle);
    g_trm.is_loaded = true;

    PrintFormat("✅ TRM loaded: %d inputs, %d latent, %d outputs, %d iterations",
                g_trm.input_size, g_trm.latent_size, g_trm.output_size, g_trm.num_iterations);

    return true;
}

//+------------------------------------------------------------------+
//| Extract features for TRM                                         |
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

    // Normalize features (same as training!)
    features[0] = (rsi[0] - 50) / 50.0;                          // RSI normalized
    features[1] = MathTanh(macd_main[0] * 1000);                // MACD normalized
    features[2] = MathTanh((macd_main[0] - macd_signal[0]) * 1000); // MACD diff
    features[3] = (stoch_main[0] - 50) / 50.0;                   // Stochastic normalized
    features[4] = MathTanh(atr[0] / _Point);                     // ATR normalized

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
//| Get ORB signal                                                    |
//+------------------------------------------------------------------+
double GetORBSignal()
{
    if(!g_orb_calculated || g_orb_range <= 0) return 0;

    double bid = g_symbol.Bid();
    double price_position = (bid - g_orb_low) / g_orb_range;

    double atr = GetCurrentATR();

    // Breakout above
    if(price_position > InpORBThreshold && bid > g_orb_high) {
        double strength = (atr > 0) ? (bid - g_orb_high) / atr : 0.5;
        return MathMin(1.0, 0.6 + strength * 0.4);
    }

    // Breakdown below
    if(price_position < (1.0 - InpORBThreshold) && bid < g_orb_low) {
        double strength = (atr > 0) ? (g_orb_low - bid) / atr : 0.5;
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

    // SAR flip bullish
    if(sar[0] < current_price && sar[1] > current_price) {
        double atr = GetCurrentATR();
        double distance = (atr > 0) ? (current_price - sar[0]) / atr : 0.5;
        return MathMin(0.8, 0.5 + distance * 0.3);
    }

    // SAR flip bearish
    if(sar[0] > current_price && sar[1] < current_price) {
        double atr = GetCurrentATR();
        double distance = (atr > 0) ? (sar[0] - current_price) / atr : 0.5;
        return MathMax(-0.8, -0.5 - distance * 0.3);
    }

    return 0;
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
        double tp = bid + (InpATRMultiplier * atr * 2.0);

        if(g_trade.Buy(lot_size, _Symbol, 0, sl, tp, "TRM_Buy")) {
            g_trades_today++;
            if(InpEnableLogging) {
                PrintFormat("✅ BUY: Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f",
                           lot_size, ask, sl, tp);
            }
        }
    } else if(signal < -0.6) {
        // SELL
        double sl = ask + (InpATRMultiplier * atr);
        double tp = ask - (InpATRMultiplier * atr * 2.0);

        if(g_trade.Sell(lot_size, _Symbol, 0, sl, tp, "TRM_Sell")) {
            g_trades_today++;
            if(InpEnableLogging) {
                PrintFormat("✅ SELL: Lots=%.2f Entry=%.5f SL=%.5f TP=%.5f",
                           lot_size, bid, sl, tp);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate position size                                          |
//+------------------------------------------------------------------+
double CalculatePositionSize(double atr)
{
    double equity = g_account.Equity();
    double risk_amount = equity * (InpRiskPercent / 100.0);

    double sl_distance = InpATRMultiplier * atr;
    double tick_value = g_symbol.TickValue();
    double tick_size = g_symbol.TickSize();

    double pip_value = tick_value / tick_size * _Point;
    double sl_pips = sl_distance / _Point;
    double risk_per_lot = sl_pips * pip_value;

    if(risk_per_lot <= 0) return 0;

    double lot_size = risk_amount / risk_per_lot;

    // Normalize
    double min_lot = g_symbol.LotsMin();
    double max_lot = g_symbol.LotsMax();
    double lot_step = g_symbol.LotsStep();

    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = MathFloor(lot_size / lot_step) * lot_step;

    return NormalizeDouble(lot_size, 2);
}

//+------------------------------------------------------------------+
//| Manage positions                                                  |
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
    static int last_day = 0;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    if(dt.day != last_day) {
        g_orb_calculated = false;
        last_day = dt.day;
    }

    if(g_orb_calculated) return;
    if(!IsORBCalculationTime()) return;

    double high_array[], low_array[];
    if(CopyHigh(_Symbol, PERIOD_M1, 1, InpORBMinutes, high_array) != InpORBMinutes) return;
    if(CopyLow(_Symbol, PERIOD_M1, 1, InpORBMinutes, low_array) != InpORBMinutes) return;

    g_orb_high = high_array[ArrayMaximum(high_array)];
    g_orb_low = low_array[ArrayMinimum(low_array)];
    g_orb_range = g_orb_high - g_orb_low;
    g_orb_calculated = true;

    if(InpEnableLogging) {
        PrintFormat("ORB: High=%.5f Low=%.5f Range=%.5f", g_orb_high, g_orb_low, g_orb_range);
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
    g_learner.strategy_weights[0] = 0.33; // ORB
    g_learner.strategy_weights[1] = 0.33; // SAR
    g_learner.strategy_weights[2] = 0.34; // TRM
    g_learner.regime_trending = true;
}

//+------------------------------------------------------------------+
//| Update adaptive learner                                          |
//+------------------------------------------------------------------+
void UpdateAdaptiveLearner()
{
    double close[50];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 50, close) == 50) {
        double trend_strength = CalculateTrendStrength(close, 50);
        g_learner.regime_trending = (trend_strength > 0.3);

        // Adjust weights
        if(g_learner.regime_trending) {
            g_learner.strategy_weights[0] = 0.4;  // ORB
            g_learner.strategy_weights[1] = 0.3;  // SAR
            g_learner.strategy_weights[2] = 0.3;  // TRM
        } else {
            g_learner.strategy_weights[0] = 0.2;  // ORB
            g_learner.strategy_weights[1] = 0.4;  // SAR
            g_learner.strategy_weights[2] = 0.4;  // TRM
        }
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
    double spread = g_symbol.Spread() * _Point;
    double atr = GetCurrentATR();
    if(atr > 0 && spread > atr * InpMaxSpreadATR) return false;

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

void PrintBanner()
{
    Print("╔════════════════════════════════════════════╗");
    Print("║   QUANTUM ELITE TRM EA v2.0               ║");
    Print("║   Hybrid: SAR + ORB + TRM Recursive AI    ║");
    Print("╚════════════════════════════════════════════╝");
}

void PrintConfiguration()
{
    Print("=== CONFIGURATION ===");
    PrintFormat("ORB: %s | SAR: %s | TRM: %s | Adaptive: %s",
               InpUseORB ? "ON" : "OFF",
               InpUseSAR ? "ON" : "OFF",
               InpUseTRM ? "ON" : "OFF",
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
    Print("║      FINAL PERFORMANCE SUMMARY            ║");
    Print("╠════════════════════════════════════════════╣");
    PrintFormat("║ Total Trades:        %17d ║", g_trades_today);
    PrintFormat("║ Total Profit:        %17.2f ║", profit);
    PrintFormat("║ Return:              %16.2f%% ║", profit_pct);
    Print("╚════════════════════════════════════════════╝");
}
//+------------------------------------------------------------------+
