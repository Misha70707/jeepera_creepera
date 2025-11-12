//+------------------------------------------------------------------+
//|                                               DataCollector.mq5  |
//|                                    Real ML Trading System v2.0   |
//+------------------------------------------------------------------+
#property copyright "ML Trading System"
#property version   "2.00"
#property description "Collects market data and trade outcomes for ML training"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "══════ Data Collection Settings ══════"
input string InpDataFile = "training_data.csv";        // Output CSV filename
input bool   InpCollectOnly = false;                   // Just collect data (no trading)
input int    InpBarsHistory = 1000;                    // Bars of history to collect

input group "══════ Simple Strategy for Labels ══════"
input double InpLotSize = 0.01;                        // Lot Size
input double InpStopLossPips = 25;                     // Stop Loss (pips)
input double InpTakeProfitPips = 50;                   // Take Profit (pips)
input int    InpRSIPeriod = 14;                        // RSI Period
input double InpRSIBuy = 30;                           // RSI Buy Level
input double InpRSISell = 70;                          // RSI Sell Level

input group "══════ Risk Management ══════"
input double InpMaxRiskPercent = 2.0;                  // Max Risk Per Trade (%)
input int    InpMaxPositions = 1;                      // Max Open Positions

//--- Global Objects
CTrade         g_trade;
CPositionInfo  g_position;
CAccountInfo   g_account;
CSymbolInfo    g_symbol;

//--- Indicator Handles
int g_atr_handle;
int g_rsi_handle;
int g_macd_handle;
int g_bb_handle;
int g_stoch_handle;
int g_adx_handle;
int g_cci_handle;

//--- Data Storage
struct DataPoint {
    datetime timestamp;

    // Price features (normalized)
    double close_norm;
    double high_norm;
    double low_norm;
    double open_norm;
    double volume_norm;

    // Technical indicators
    double atr;
    double rsi;
    double macd_main;
    double macd_signal;
    double bb_upper;
    double bb_middle;
    double bb_lower;
    double stoch_k;
    double stoch_d;
    double adx;
    double cci;

    // Price action
    double momentum;
    double velocity;
    double acceleration;

    // Support/Resistance
    double support_distance;
    double resistance_distance;

    // Time features
    int hour;
    int day_of_week;

    // Label (what happened next)
    double next_bar_return;        // % change next bar
    double next_5bar_return;       // % change in 5 bars
    double next_10bar_return;      // % change in 10 bars
    int optimal_action;            // 1=buy, -1=sell, 0=hold

    // If we took a trade
    bool trade_taken;
    int trade_direction;           // 1=buy, -1=sell
    double trade_profit;           // Actual P&L if trade was taken
};

DataPoint g_data_buffer[];
int g_buffer_index = 0;
int g_buffer_size = 10000;

//--- Trade tracking
datetime g_last_bar_time = 0;
ulong g_current_ticket = 0;
double g_entry_price = 0;
datetime g_entry_time = 0;
int g_entry_bar_index = 0;

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
    g_trade.SetExpertMagicNumber(888999);
    g_trade.SetMarginMode();
    g_trade.SetTypeFillingBySymbol(_Symbol);

    // Create indicator handles (CREATE ONCE, REUSE!)
    g_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
    g_rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
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

    // Initialize data buffer
    ArrayResize(g_data_buffer, g_buffer_size);
    g_buffer_index = 0;

    // Write CSV header
    WriteCSVHeader();

    PrintFormat("╔════════════════════════════════════════════╗");
    PrintFormat("║       ML DATA COLLECTOR INITIALIZED        ║");
    PrintFormat("╠════════════════════════════════════════════╣");
    PrintFormat("║ Mode: %-37s║", InpCollectOnly ? "DATA COLLECTION ONLY" : "COLLECT + TRADE");
    PrintFormat("║ Output: %-35s║", InpDataFile);
    PrintFormat("║ Buffer Size: %-30d║", g_buffer_size);
    PrintFormat("╚════════════════════════════════════════════╝");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Release indicator handles
    IndicatorRelease(g_atr_handle);
    IndicatorRelease(g_rsi_handle);
    IndicatorRelease(g_macd_handle);
    IndicatorRelease(g_bb_handle);
    IndicatorRelease(g_stoch_handle);
    IndicatorRelease(g_adx_handle);
    IndicatorRelease(g_cci_handle);

    // Save remaining data
    FlushDataToFile();

    PrintFormat("Data Collector stopped. Collected %d data points.", g_buffer_index);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Check for new bar
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(current_bar_time == g_last_bar_time) return;

    g_last_bar_time = current_bar_time;

    // Update existing data points with labels (what actually happened)
    UpdateLabels();

    // Collect new data point
    DataPoint dp;
    if(CollectDataPoint(dp)) {
        // Add to buffer
        if(g_buffer_index >= g_buffer_size) {
            FlushDataToFile();
            g_buffer_index = 0;
        }
        g_data_buffer[g_buffer_index] = dp;
        g_buffer_index++;

        // Trading logic (if enabled)
        if(!InpCollectOnly) {
            ExecuteSimpleStrategy(dp);
        }
    }

    // Periodic save
    if(g_buffer_index >= 100 && g_buffer_index % 100 == 0) {
        FlushDataToFile();
    }
}

//+------------------------------------------------------------------+
//| Collect current market state                                      |
//+------------------------------------------------------------------+
bool CollectDataPoint(DataPoint &dp) {
    // Get price arrays
    double close[], high[], low[], open[], volume[];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 100, close) < 100) return false;
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 100, high) < 100) return false;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 100, low) < 100) return false;
    if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 100, open) < 100) return false;
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 100, volume) < 100) return false;

    dp.timestamp = iTime(_Symbol, PERIOD_CURRENT, 0);

    // Normalize price features (0-1 range over last 100 bars)
    double min_price = low[ArrayMinimum(low)];
    double max_price = high[ArrayMaximum(high)];
    double price_range = max_price - min_price;

    if(price_range > 0) {
        dp.close_norm = (close[0] - min_price) / price_range;
        dp.high_norm = (high[0] - min_price) / price_range;
        dp.low_norm = (low[0] - min_price) / price_range;
        dp.open_norm = (open[0] - min_price) / price_range;
    } else {
        dp.close_norm = dp.high_norm = dp.low_norm = dp.open_norm = 0.5;
    }

    // Normalize volume
    double min_vol = volume[ArrayMinimum(volume)];
    double max_vol = volume[ArrayMaximum(volume)];
    double vol_range = max_vol - min_vol;
    dp.volume_norm = (vol_range > 0) ? (volume[0] - min_vol) / vol_range : 0.5;

    // Get indicator values
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

    dp.atr = atr[0];
    dp.rsi = rsi[0];
    dp.macd_main = macd_main[0];
    dp.macd_signal = macd_signal[0];
    dp.bb_upper = bb_upper[0];
    dp.bb_middle = bb_middle[0];
    dp.bb_lower = bb_lower[0];
    dp.stoch_k = stoch_k[0];
    dp.stoch_d = stoch_d[0];
    dp.adx = adx[0];
    dp.cci = cci[0];

    // Price action features
    if(close[1] != 0) {
        dp.momentum = (close[0] - close[10]) / close[10];
        dp.velocity = (close[0] - close[1]) / close[1];
        double prev_velocity = (close[1] - close[2]) / close[2];
        dp.acceleration = dp.velocity - prev_velocity;
    } else {
        dp.momentum = dp.velocity = dp.acceleration = 0;
    }

    // Support/Resistance
    double support = low[ArrayMinimum(low, 0, 50)];
    double resistance = high[ArrayMaximum(high, 0, 50)];
    dp.support_distance = (close[0] > support && support > 0) ?
                         (close[0] - support) / close[0] : 0.0;
    dp.resistance_distance = (resistance > close[0] && resistance > 0) ?
                            (resistance - close[0]) / close[0] : 0.0;

    // Time features
    MqlDateTime time_struct;
    TimeToStruct(dp.timestamp, time_struct);
    dp.hour = time_struct.hour;
    dp.day_of_week = time_struct.day_of_week;

    // Labels will be filled later when we know what happened
    dp.next_bar_return = 0;
    dp.next_5bar_return = 0;
    dp.next_10bar_return = 0;
    dp.optimal_action = 0;

    dp.trade_taken = false;
    dp.trade_direction = 0;
    dp.trade_profit = 0;

    return true;
}

//+------------------------------------------------------------------+
//| Update labels for past data points                                |
//+------------------------------------------------------------------+
void UpdateLabels() {
    double close[];
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 20, close) < 20) return;

    // Update labels for recent data points
    for(int i = 0; i < g_buffer_index; i++) {
        if(g_data_buffer[i].next_10bar_return != 0) continue; // Already labeled

        // Find how many bars ago this data point was
        int bars_ago = iBarShift(_Symbol, PERIOD_CURRENT, g_data_buffer[i].timestamp);
        if(bars_ago < 0 || bars_ago > 15) continue;

        // Calculate returns
        double entry_price = iClose(_Symbol, PERIOD_CURRENT, bars_ago);
        if(entry_price == 0) continue;

        if(bars_ago >= 1) {
            double next_price = iClose(_Symbol, PERIOD_CURRENT, bars_ago - 1);
            g_data_buffer[i].next_bar_return = (next_price - entry_price) / entry_price;
        }

        if(bars_ago >= 5) {
            double next_5_price = iClose(_Symbol, PERIOD_CURRENT, bars_ago - 5);
            g_data_buffer[i].next_5bar_return = (next_5_price - entry_price) / entry_price;
        }

        if(bars_ago >= 10) {
            double next_10_price = iClose(_Symbol, PERIOD_CURRENT, bars_ago - 10);
            g_data_buffer[i].next_10bar_return = (next_10_price - entry_price) / entry_price;

            // Determine optimal action (with hindsight)
            // Consider transaction costs (2 pips = ~0.0002 for major pairs)
            double threshold = 0.0005; // 0.05% minimum profit target

            if(g_data_buffer[i].next_10bar_return > threshold) {
                g_data_buffer[i].optimal_action = 1; // Should have bought
            } else if(g_data_buffer[i].next_10bar_return < -threshold) {
                g_data_buffer[i].optimal_action = -1; // Should have sold
            } else {
                g_data_buffer[i].optimal_action = 0; // Should have held
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Simple strategy for generating labeled data                       |
//+------------------------------------------------------------------+
void ExecuteSimpleStrategy(DataPoint &dp) {
    // Don't trade if position already open
    if(PositionSelect(_Symbol)) return;

    // Simple RSI strategy
    int signal = 0;
    if(dp.rsi < InpRSIBuy && dp.macd_main > dp.macd_signal) {
        signal = 1; // Buy
    } else if(dp.rsi > InpRSISell && dp.macd_main < dp.macd_signal) {
        signal = -1; // Sell
    }

    if(signal == 0) return;

    // Calculate position size
    double lot_size = InpLotSize;

    // Calculate SL/TP
    double point = g_symbol.Point();
    double sl = 0, tp = 0;

    if(signal == 1) { // Buy
        double ask = g_symbol.Ask();
        sl = ask - InpStopLossPips * 10 * point;
        tp = ask + InpTakeProfitPips * 10 * point;

        if(g_trade.Buy(lot_size, _Symbol, ask, sl, tp, "DataCollector")) {
            g_current_ticket = g_trade.ResultOrder();
            g_entry_price = ask;
            g_entry_time = TimeCurrent();
            g_entry_bar_index = g_buffer_index - 1;

            // Mark in data
            if(g_entry_bar_index >= 0 && g_entry_bar_index < g_buffer_index) {
                g_data_buffer[g_entry_bar_index].trade_taken = true;
                g_data_buffer[g_entry_bar_index].trade_direction = 1;
            }

            Print("BUY executed at ", ask);
        }
    } else { // Sell
        double bid = g_symbol.Bid();
        sl = bid + InpStopLossPips * 10 * point;
        tp = bid - InpTakeProfitPips * 10 * point;

        if(g_trade.Sell(lot_size, _Symbol, bid, sl, tp, "DataCollector")) {
            g_current_ticket = g_trade.ResultOrder();
            g_entry_price = bid;
            g_entry_time = TimeCurrent();
            g_entry_bar_index = g_buffer_index - 1;

            // Mark in data
            if(g_entry_bar_index >= 0 && g_entry_bar_index < g_buffer_index) {
                g_data_buffer[g_entry_bar_index].trade_taken = true;
                g_data_buffer[g_entry_bar_index].trade_direction = -1;
            }

            Print("SELL executed at ", bid);
        }
    }
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

                // Record profit in original data point
                if(g_entry_bar_index >= 0 && g_entry_bar_index < g_buffer_index) {
                    g_data_buffer[g_entry_bar_index].trade_profit = total_profit;
                }

                PrintFormat("Trade closed: P/L = %.2f", total_profit);

                g_current_ticket = 0;
                g_entry_bar_index = -1;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Write CSV header                                                  |
//+------------------------------------------------------------------+
void WriteCSVHeader() {
    int file_handle = FileOpen(InpDataFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    if(file_handle == INVALID_HANDLE) {
        Print("Failed to create CSV file");
        return;
    }

    // Write header
    string header = "timestamp,close_norm,high_norm,low_norm,open_norm,volume_norm,";
    header += "atr,rsi,macd_main,macd_signal,bb_upper,bb_middle,bb_lower,";
    header += "stoch_k,stoch_d,adx,cci,";
    header += "momentum,velocity,acceleration,";
    header += "support_distance,resistance_distance,";
    header += "hour,day_of_week,";
    header += "next_bar_return,next_5bar_return,next_10bar_return,optimal_action,";
    header += "trade_taken,trade_direction,trade_profit";

    FileWrite(file_handle, header);
    FileClose(file_handle);
}

//+------------------------------------------------------------------+
//| Flush data buffer to file                                         |
//+------------------------------------------------------------------+
void FlushDataToFile() {
    if(g_buffer_index == 0) return;

    int file_handle = FileOpen(InpDataFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    if(file_handle == INVALID_HANDLE) {
        Print("Failed to open CSV file for writing");
        return;
    }

    // Move to end of file
    FileSeek(file_handle, 0, SEEK_END);

    // Write data points
    for(int i = 0; i < g_buffer_index; i++) {
        DataPoint dp = g_data_buffer[i];

        string line = StringFormat("%s,%.6f,%.6f,%.6f,%.6f,%.6f,",
            TimeToString(dp.timestamp, TIME_DATE|TIME_MINUTES),
            dp.close_norm, dp.high_norm, dp.low_norm, dp.open_norm, dp.volume_norm);

        line += StringFormat("%.6f,%.2f,%.8f,%.8f,%.5f,%.5f,%.5f,",
            dp.atr, dp.rsi, dp.macd_main, dp.macd_signal,
            dp.bb_upper, dp.bb_middle, dp.bb_lower);

        line += StringFormat("%.2f,%.2f,%.2f,%.2f,",
            dp.stoch_k, dp.stoch_d, dp.adx, dp.cci);

        line += StringFormat("%.6f,%.6f,%.6f,",
            dp.momentum, dp.velocity, dp.acceleration);

        line += StringFormat("%.6f,%.6f,",
            dp.support_distance, dp.resistance_distance);

        line += StringFormat("%d,%d,",
            dp.hour, dp.day_of_week);

        line += StringFormat("%.6f,%.6f,%.6f,%d,",
            dp.next_bar_return, dp.next_5bar_return, dp.next_10bar_return, dp.optimal_action);

        line += StringFormat("%d,%d,%.2f",
            dp.trade_taken ? 1 : 0, dp.trade_direction, dp.trade_profit);

        FileWrite(file_handle, line);
    }

    FileClose(file_handle);
    PrintFormat("Flushed %d data points to %s", g_buffer_index, InpDataFile);
    g_buffer_index = 0;
}
//+------------------------------------------------------------------+
