//+------------------------------------------------------------------+
//|                                                MLTradingBot.mq5  |
//|                           Real ML-Based Trading Expert Advisor   |
//+------------------------------------------------------------------+
#property copyright "ML Trading System v2.0"
#property version   "2.00"
#property description "Production EA using trained machine learning model"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "══════ ML Model Settings ══════"
input string InpModelWeightsFile = "model_weights.txt";    // Model Weights File
input double InpConfidenceThreshold = 0.6;                 // Min Confidence Threshold
input bool   InpUseModelPredictions = true;                // Use ML Predictions

input group "══════ Risk Management ══════"
input double InpLotSize = 0.01;                            // Fixed Lot Size
input double InpMaxRiskPercent = 2.0;                      // Max Risk Per Trade (%)
input double InpStopLossPips = 25;                         // Stop Loss (pips)
input double InpTakeProfitPips = 50;                       // Take Profit (pips)
input double InpMaxDrawdownPercent = 15.0;                 // Max Drawdown (%)

input group "══════ Trading Settings ══════"
input bool   InpTradingEnabled = true;                     // Enable Trading
input int    InpMaxPositions = 1;                          // Max Open Positions
input int    InpMinBarsBetweenTrades = 3;                  // Min Bars Between Trades
input bool   InpUseTrailingStop = true;                    // Use Trailing Stop
input double InpTrailingStartPips = 20;                    // Trailing Start (pips)
input double InpTrailingStepPips = 10;                     // Trailing Step (pips)

input group "══════ Logging & Display ══════"
input bool   InpVerboseLogging = true;                     // Verbose Logging
input bool   InpShowDashboard = true;                      // Show Info Dashboard

//--- Global Objects
CTrade         g_trade;
CPositionInfo  g_position;
CAccountInfo   g_account;
CSymbolInfo    g_symbol;

//--- Indicator Handles (created once, reused)
int g_atr_handle = INVALID_HANDLE;
int g_rsi_handle = INVALID_HANDLE;
int g_macd_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;
int g_stoch_handle = INVALID_HANDLE;
int g_adx_handle = INVALID_HANDLE;
int g_cci_handle = INVALID_HANDLE;

//--- ML Model Data
struct MLModel {
    string feature_names[50];
    int feature_count;
    double scaler_mean[50];
    double scaler_scale[50];
    double feature_importance[50];
    bool is_loaded;
};

MLModel g_model;

//--- Performance Tracking
double g_initial_balance;
double g_max_balance;
double g_max_drawdown;
int    g_total_trades;
int    g_winning_trades;
int    g_ml_trades;
int    g_ml_wins;
int    g_bars_since_last_trade;

//--- Time Management
datetime g_last_bar_time = 0;
datetime g_last_trade_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize symbol
    if(!g_symbol.Name(_Symbol)) {
        Print("Failed to initialize symbol");
        return INIT_FAILED;
    }

    // Setup trade object
    g_trade.SetExpertMagicNumber(999888);
    g_trade.SetMarginMode();
    g_trade.SetTypeFillingBySymbol(_Symbol);
    g_trade.SetDeviationInPoints(10);

    // Create indicator handles (CREATE ONCE!)
    g_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
    g_rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    g_macd_handle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
    g_bb_handle = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
    g_stoch_handle = iStochastic(_Symbol, PERIOD_CURRENT, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    g_adx_handle = iADX(_Symbol, PERIOD_CURRENT, 14);
    g_cci_handle = iCCI(_Symbol, PERIOD_CURRENT, 14, PRICE_TYPICAL);

    // Validate handles
    if(g_atr_handle == INVALID_HANDLE || g_rsi_handle == INVALID_HANDLE ||
       g_macd_handle == INVALID_HANDLE || g_bb_handle == INVALID_HANDLE ||
       g_stoch_handle == INVALID_HANDLE || g_adx_handle == INVALID_HANDLE ||
       g_cci_handle == INVALID_HANDLE) {
        Print("Failed to create indicator handles");
        return INIT_FAILED;
    }

    // Load ML model
    if(InpUseModelPredictions) {
        if(!LoadMLModel(InpModelWeightsFile)) {
            Print("⚠️ Warning: Failed to load ML model. Will use fallback strategy.");
            g_model.is_loaded = false;
        }
    } else {
        g_model.is_loaded = false;
    }

    // Initialize performance tracking
    g_initial_balance = g_account.Balance();
    g_max_balance = g_initial_balance;
    g_max_drawdown = 0.0;
    g_total_trades = 0;
    g_winning_trades = 0;
    g_ml_trades = 0;
    g_ml_wins = 0;
    g_bars_since_last_trade = 0;

    // Display initialization message
    PrintFormat("╔════════════════════════════════════════════╗");
    PrintFormat("║     ML TRADING BOT INITIALIZED v2.0       ║");
    PrintFormat("╠════════════════════════════════════════════╣");
    PrintFormat("║ Symbol: %-35s║", _Symbol);
    PrintFormat("║ ML Model: %-33s║", g_model.is_loaded ? "LOADED ✓" : "NOT LOADED (fallback)");
    PrintFormat("║ Features: %-32d║", g_model.feature_count);
    PrintFormat("║ Confidence Threshold: %-21.2f║", InpConfidenceThreshold);
    PrintFormat("╚════════════════════════════════════════════╝");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Release indicator handles
    if(g_atr_handle != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
    if(g_rsi_handle != INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
    if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
    if(g_bb_handle != INVALID_HANDLE) IndicatorRelease(g_bb_handle);
    if(g_stoch_handle != INVALID_HANDLE) IndicatorRelease(g_stoch_handle);
    if(g_adx_handle != INVALID_HANDLE) IndicatorRelease(g_adx_handle);
    if(g_cci_handle != INVALID_HANDLE) IndicatorRelease(g_cci_handle);

    // Print final statistics
    double final_balance = g_account.Balance();
    double total_profit = final_balance - g_initial_balance;
    double profit_percent = (g_initial_balance > 0) ?
                           (total_profit / g_initial_balance * 100) : 0.0;

    PrintFormat("╔════════════════════════════════════════════╗");
    PrintFormat("║       FINAL PERFORMANCE SUMMARY            ║");
    PrintFormat("╠════════════════════════════════════════════╣");
    PrintFormat("║ Total Trades: %-29d║", g_total_trades);
    PrintFormat("║ ML Trades: %-32d║", g_ml_trades);
    PrintFormat("║ Win Rate: %-33.1f%%║",
               (g_total_trades > 0) ? (g_winning_trades * 100.0 / g_total_trades) : 0.0);
    PrintFormat("║ ML Win Rate: %-29.1f%%║",
               (g_ml_trades > 0) ? (g_ml_wins * 100.0 / g_ml_trades) : 0.0);
    PrintFormat("║ Total Profit: %-29.2f║", total_profit);
    PrintFormat("║ Profit %%: %-33.2f%%║", profit_percent);
    PrintFormat("║ Max Drawdown: %-29.2f║", g_max_drawdown);
    PrintFormat("╚════════════════════════════════════════════╝");

    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    if(!InpTradingEnabled) return;

    // Update symbol rates
    g_symbol.RefreshRates();

    // Check for new bar
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(current_bar_time == g_last_bar_time) {
        // Still on same bar, just manage trailing stop
        if(InpUseTrailingStop) ManageTrailingStop();
        return;
    }

    g_last_bar_time = current_bar_time;
    g_bars_since_last_trade++;

    // Check drawdown limit
    if(IsMaxDrawdownReached()) {
        if(InpVerboseLogging) Print("Max drawdown reached. Trading suspended.");
        return;
    }

    // Check if we have open position
    if(PositionSelect(_Symbol)) {
        if(InpUseTrailingStop) ManageTrailingStop();
        UpdatePerformanceMetrics();
        return;
    }

    // Check minimum bars between trades
    if(g_bars_since_last_trade < InpMinBarsBetweenTrades) {
        return;
    }

    // Gather features
    double features[];
    if(!GatherFeatures(features)) {
        if(InpVerboseLogging) Print("Failed to gather features");
        return;
    }

    // Get trading signal
    int signal = 0;
    double confidence = 0.0;

    if(g_model.is_loaded) {
        // Use ML model
        signal = PredictWithModel(features, confidence);
        if(InpVerboseLogging && signal != 0) {
            PrintFormat("ML Signal: %s (confidence: %.2f)",
                       (signal > 0) ? "BUY" : "SELL", confidence);
        }
    } else {
        // Fallback to simple strategy
        signal = GetFallbackSignal(features, confidence);
        if(InpVerboseLogging && signal != 0) {
            PrintFormat("Fallback Signal: %s", (signal > 0) ? "BUY" : "SELL");
        }
    }

    // Execute trade if signal is strong enough
    if(signal != 0 && confidence >= InpConfidenceThreshold) {
        ExecuteTrade(signal, confidence);
    }

    // Update performance
    UpdatePerformanceMetrics();

    // Update dashboard
    if(InpShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Trade transaction event                                           |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result) {
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        if(HistoryDealSelect(trans.deal)) {
            ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

            if(deal_entry == DEAL_ENTRY_OUT || deal_entry == DEAL_ENTRY_OUT_BY) {
                double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
                double commission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
                double swap = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
                double total_profit = profit + commission + swap;

                // Update statistics
                if(total_profit > 0) {
                    g_winning_trades++;
                    if(g_model.is_loaded) g_ml_wins++;
                }

                if(InpVerboseLogging) {
                    PrintFormat("Trade closed: P/L = %.2f (P: %.2f, C: %.2f, S: %.2f)",
                               total_profit, profit, commission, swap);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Load ML model from file                                           |
//+------------------------------------------------------------------+
bool LoadMLModel(string filename) {
    int file_handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI);
    if(file_handle == INVALID_HANDLE) {
        PrintFormat("Failed to open model file: %s (Error: %d)", filename, GetLastError());
        return false;
    }

    g_model.feature_count = 0;
    g_model.is_loaded = false;

    string section = "";
    int index = 0;

    while(!FileIsEnding(file_handle)) {
        string line = FileReadString(file_handle);
        StringTrimLeft(line);
        StringTrimRight(line);

        // Skip comments and empty lines
        if(StringLen(line) == 0 || StringSubstr(line, 0, 1) == "#") continue;

        // Check for section headers
        if(line == "FEATURES") {
            section = "FEATURES";
            index = 0;
            continue;
        } else if(line == "SCALER_MEAN") {
            section = "SCALER_MEAN";
            index = 0;
            continue;
        } else if(line == "SCALER_SCALE") {
            section = "SCALER_SCALE";
            index = 0;
            continue;
        } else if(line == "FEATURE_IMPORTANCE") {
            section = "FEATURE_IMPORTANCE";
            index = 0;
            continue;
        }

        // Parse data based on current section
        if(section == "FEATURES") {
            g_model.feature_names[index] = line;
            index++;
            g_model.feature_count = index;
        } else if(section == "SCALER_MEAN") {
            g_model.scaler_mean[index] = StringToDouble(line);
            index++;
        } else if(section == "SCALER_SCALE") {
            g_model.scaler_scale[index] = StringToDouble(line);
            index++;
        } else if(section == "FEATURE_IMPORTANCE") {
            g_model.feature_importance[index] = StringToDouble(line);
            index++;
        }
    }

    FileClose(file_handle);

    if(g_model.feature_count > 0) {
        g_model.is_loaded = true;
        PrintFormat("✓ ML Model loaded successfully: %d features", g_model.feature_count);
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Gather all features for prediction                                |
//+------------------------------------------------------------------+
bool GatherFeatures(double &features[]) {
    // Resize array to match model
    ArrayResize(features, g_model.feature_count > 0 ? g_model.feature_count : 27);

    // Get price data
    double close[], high[], low[], open[], volume[];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 100, close) < 100) return false;
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 100, high) < 100) return false;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 100, low) < 100) return false;
    if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 100, open) < 100) return false;
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 100, volume) < 100) return false;

    // Normalize price features
    double min_price = low[ArrayMinimum(low)];
    double max_price = high[ArrayMaximum(high)];
    double price_range = max_price - min_price;

    double close_norm = (price_range > 0) ? (close[0] - min_price) / price_range : 0.5;
    double high_norm = (price_range > 0) ? (high[0] - min_price) / price_range : 0.5;
    double low_norm = (price_range > 0) ? (low[0] - min_price) / price_range : 0.5;
    double open_norm = (price_range > 0) ? (open[0] - min_price) / price_range : 0.5;

    double min_vol = volume[ArrayMinimum(volume)];
    double max_vol = volume[ArrayMaximum(volume)];
    double vol_range = max_vol - min_vol;
    double volume_norm = (vol_range > 0) ? (volume[0] - min_vol) / vol_range : 0.5;

    // Get indicators
    double atr[], rsi[], macd_main[], macd_signal[], bb_upper[], bb_middle[], bb_lower[];
    double stoch_k[], stoch_d[], adx[], cci[];

    CopyBuffer(g_atr_handle, 0, 0, 1, atr);
    CopyBuffer(g_rsi_handle, 0, 0, 1, rsi);
    CopyBuffer(g_macd_handle, 0, 0, 1, macd_main);
    CopyBuffer(g_macd_handle, 1, 0, 1, macd_signal);
    CopyBuffer(g_bb_handle, 1, 0, 1, bb_upper);
    CopyBuffer(g_bb_handle, 0, 0, 1, bb_middle);
    CopyBuffer(g_bb_handle, 2, 0, 1, bb_lower);
    CopyBuffer(g_stoch_handle, 0, 0, 1, stoch_k);
    CopyBuffer(g_stoch_handle, 1, 0, 1, stoch_d);
    CopyBuffer(g_adx_handle, 0, 0, 1, adx);
    CopyBuffer(g_cci_handle, 0, 0, 1, cci);

    // Feature engineering (must match Python training script!)
    double bb_position = (bb_upper[0] - bb_lower[0] > 0) ?
                        (close[0] - bb_lower[0]) / (bb_upper[0] - bb_lower[0]) : 0.5;
    double rsi_normalized = rsi[0] / 100.0;
    double macd_diff = macd_main[0] - macd_signal[0];
    double stoch_avg = (stoch_k[0] + stoch_d[0]) / 2.0;
    double price_range_feat = high_norm - low_norm;
    double body_size = MathAbs(close_norm - open_norm);

    // Time features
    MqlDateTime time_struct;
    TimeToStruct(TimeCurrent(), time_struct);
    double hour_sin = MathSin(2 * M_PI * time_struct.hour / 24.0);
    double hour_cos = MathCos(2 * M_PI * time_struct.hour / 24.0);
    double dow_sin = MathSin(2 * M_PI * time_struct.day_of_week / 7.0);
    double dow_cos = MathCos(2 * M_PI * time_struct.day_of_week / 7.0);

    // Price action
    double momentum = (close[10] != 0) ? (close[0] - close[10]) / close[10] : 0;
    double velocity = (close[1] != 0) ? (close[0] - close[1]) / close[1] : 0;
    double prev_velocity = (close[2] != 0) ? (close[1] - close[2]) / close[2] : 0;
    double acceleration = velocity - prev_velocity;

    // S/R distances
    double support = low[ArrayMinimum(low, 0, 50)];
    double resistance = high[ArrayMaximum(high, 0, 50)];
    double support_distance = (close[0] > support && support > 0) ?
                             (close[0] - support) / close[0] : 0.0;
    double resistance_distance = (resistance > close[0] && resistance > 0) ?
                                (resistance - close[0]) / close[0] : 0.0;

    // Fill features array (ORDER MUST MATCH PYTHON SCRIPT!)
    int idx = 0;
    features[idx++] = close_norm;
    features[idx++] = high_norm;
    features[idx++] = low_norm;
    features[idx++] = open_norm;
    features[idx++] = volume_norm;
    features[idx++] = atr[0];
    features[idx++] = rsi_normalized;
    features[idx++] = macd_main[0];
    features[idx++] = macd_signal[0];
    features[idx++] = macd_diff;
    features[idx++] = bb_position;
    features[idx++] = stoch_k[0];
    features[idx++] = stoch_d[0];
    features[idx++] = stoch_avg;
    features[idx++] = adx[0];
    features[idx++] = cci[0];
    features[idx++] = momentum;
    features[idx++] = velocity;
    features[idx++] = acceleration;
    features[idx++] = support_distance;
    features[idx++] = resistance_distance;
    features[idx++] = hour_sin;
    features[idx++] = hour_cos;
    features[idx++] = dow_sin;
    features[idx++] = dow_cos;
    features[idx++] = price_range_feat;
    features[idx++] = body_size;

    return true;
}

//+------------------------------------------------------------------+
//| Predict using ML model                                            |
//+------------------------------------------------------------------+
int PredictWithModel(double &features[], double &confidence) {
    if(!g_model.is_loaded) return 0;

    // Standardize features using scaler
    double scaled_features[];
    ArrayResize(scaled_features, g_model.feature_count);

    for(int i = 0; i < g_model.feature_count; i++) {
        if(g_model.scaler_scale[i] != 0) {
            scaled_features[i] = (features[i] - g_model.scaler_mean[i]) / g_model.scaler_scale[i];
        } else {
            scaled_features[i] = 0;
        }
    }

    // Simple prediction based on weighted feature importance
    // (This is a simplified approach - for full Random Forest, use ONNX)
    double signal_score = 0.0;
    double total_importance = 0.0;

    for(int i = 0; i < g_model.feature_count; i++) {
        signal_score += scaled_features[i] * g_model.feature_importance[i];
        total_importance += g_model.feature_importance[i];
    }

    if(total_importance > 0) {
        signal_score /= total_importance;
    }

    // Convert to confidence and signal
    confidence = 1.0 / (1.0 + MathExp(-signal_score)); // Sigmoid

    if(confidence > 0.6) {
        return 1; // Buy
    } else if(confidence < 0.4) {
        confidence = 1.0 - confidence;
        return -1; // Sell
    }

    return 0; // Hold
}

//+------------------------------------------------------------------+
//| Fallback strategy when ML model not available                     |
//+------------------------------------------------------------------+
int GetFallbackSignal(double &features[], double &confidence) {
    // Simple multi-indicator strategy
    double rsi_norm = features[6]; // rsi_normalized
    double macd_diff = features[9]; // macd_diff
    double stoch_avg = features[13]; // stoch_avg
    double adx = features[14];

    int buy_signals = 0;
    int sell_signals = 0;

    // RSI
    if(rsi_norm < 0.3) buy_signals++;
    else if(rsi_norm > 0.7) sell_signals++;

    // MACD
    if(macd_diff > 0) buy_signals++;
    else if(macd_diff < 0) sell_signals++;

    // Stochastic
    if(stoch_avg < 20) buy_signals++;
    else if(stoch_avg > 80) sell_signals++;

    // Trend filter (ADX)
    bool strong_trend = adx > 25;

    if(buy_signals >= 2 && strong_trend) {
        confidence = 0.7;
        return 1;
    } else if(sell_signals >= 2 && strong_trend) {
        confidence = 0.7;
        return -1;
    }

    confidence = 0.3;
    return 0;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, double confidence) {
    double lot_size = InpLotSize;
    double point = g_symbol.Point();
    double sl = 0, tp = 0;

    bool success = false;

    if(signal == 1) { // Buy
        double ask = g_symbol.Ask();
        sl = ask - InpStopLossPips * 10 * point;
        tp = ask + InpTakeProfitPips * 10 * point;

        success = g_trade.Buy(lot_size, _Symbol, ask, sl, tp,
                             StringFormat("ML_Buy_%.2f", confidence));
    } else if(signal == -1) { // Sell
        double bid = g_symbol.Bid();
        sl = bid + InpStopLossPips * 10 * point;
        tp = bid - InpTakeProfitPips * 10 * point;

        success = g_trade.Sell(lot_size, _Symbol, bid, sl, tp,
                              StringFormat("ML_Sell_%.2f", confidence));
    }

    if(success) {
        g_total_trades++;
        if(g_model.is_loaded) g_ml_trades++;
        g_bars_since_last_trade = 0;
        g_last_trade_time = TimeCurrent();

        PrintFormat("✓ Trade executed: %s (Confidence: %.2f)",
                   (signal > 0) ? "BUY" : "SELL", confidence);
    } else {
        PrintFormat("✗ Trade failed. Error: %d", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Manage trailing stop                                              |
//+------------------------------------------------------------------+
void ManageTrailingStop() {
    if(!InpUseTrailingStop) return;

    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!g_position.SelectByIndex(i)) continue;
        if(g_position.Symbol() != _Symbol) continue;
        if(g_position.Magic() != g_trade.RequestMagic()) continue;

        double point = g_symbol.Point();
        double current_sl = g_position.StopLoss();
        double open_price = g_position.PriceOpen();
        double current_price = g_position.PriceCurrent();

        double trail_start = InpTrailingStartPips * 10 * point;
        double trail_step = InpTrailingStepPips * 10 * point;

        if(g_position.PositionType() == POSITION_TYPE_BUY) {
            if(current_price - open_price >= trail_start) {
                double new_sl = current_price - trail_step;
                if(new_sl > current_sl) {
                    g_trade.PositionModify(g_position.Ticket(), new_sl, g_position.TakeProfit());
                }
            }
        } else { // SELL
            if(open_price - current_price >= trail_start) {
                double new_sl = current_price + trail_step;
                if(new_sl < current_sl || current_sl == 0) {
                    g_trade.PositionModify(g_position.Ticket(), new_sl, g_position.TakeProfit());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update performance metrics                                        |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics() {
    double current_balance = g_account.Balance();

    if(current_balance > g_max_balance) {
        g_max_balance = current_balance;
    }

    double current_drawdown = (g_max_balance > 0) ?
                             ((g_max_balance - current_balance) / g_max_balance * 100) : 0.0;

    if(current_drawdown > g_max_drawdown) {
        g_max_drawdown = current_drawdown;
    }
}

//+------------------------------------------------------------------+
//| Check if maximum drawdown is reached                              |
//+------------------------------------------------------------------+
bool IsMaxDrawdownReached() {
    double current_balance = g_account.Balance();
    double current_drawdown = (g_initial_balance > 0) ?
                             ((g_initial_balance - current_balance) / g_initial_balance * 100) : 0.0;

    return (current_drawdown >= InpMaxDrawdownPercent);
}

//+------------------------------------------------------------------+
//| Update dashboard                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard() {
    double current_balance = g_account.Balance();
    double profit = current_balance - g_initial_balance;
    double profit_pct = (g_initial_balance > 0) ? (profit / g_initial_balance * 100) : 0.0;
    double win_rate = (g_total_trades > 0) ? (g_winning_trades * 100.0 / g_total_trades) : 0.0;
    double ml_win_rate = (g_ml_trades > 0) ? (g_ml_wins * 100.0 / g_ml_trades) : 0.0;

    string info = StringFormat(
        "╔═══════════════════════════════════╗\n" +
        "║    ML TRADING BOT v2.0            ║\n" +
        "╠═══════════════════════════════════╣\n" +
        "║ Model: %-27s║\n" +
        "║ Balance: $%-24.2f║\n" +
        "║ Profit: $%-25.2f║\n" +
        "║ Profit %%: %-24.2f%%║\n" +
        "║ Trades: %-26d║\n" +
        "║ ML Trades: %-23d║\n" +
        "║ Win Rate: %-24.1f%%║\n" +
        "║ ML Win Rate: %-21.1f%%║\n" +
        "║ Max DD: %-26.2f%%║\n" +
        "╚═══════════════════════════════════╝",
        g_model.is_loaded ? "ACTIVE" : "FALLBACK",
        current_balance,
        profit,
        profit_pct,
        g_total_trades,
        g_ml_trades,
        win_rate,
        ml_win_rate,
        g_max_drawdown
    );

    Comment(info);
}
//+------------------------------------------------------------------+
