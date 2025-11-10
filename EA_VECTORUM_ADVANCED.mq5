//+------------------------------------------------------------------+
//|                              EA_VECTORUM_ADVANCED.mq5             |
//|                                          Claude Code Design       |
//|                     Vector-Based Math-Driven Trading System       |
//+------------------------------------------------------------------+
#property copyright "Claude Code"
#property link      "https://www.claude.ai"
#property version   "1.0"
#property description "Advanced Vector-Based EA with Kelly Criterion, Correlation Analysis, and Volatility Adaptation"

//--- Input parameters
input double     RiskPercent = 2.0;           // Risk per trade (%)
input int        LookbackPeriod = 20;        // Lookback for correlation matrix
input double     MinCorrelation = 0.70;      // Minimum confluence correlation (0.0-1.0)
input double     VectorMagnitudeThreshold = 0.65; // Signal strength threshold
input double     KellyCriterion = 0.25;      // Kelly multiplier (0.25 = conservative)
input int        ATRPeriod = 14;             // Volatility measurement period
input double     VolatilityMultiplier = 1.5; // Stop distance = ATR * this
input int        MaxOpenPositions = 1;       // Max concurrent positions
input int        MagicNumber = 77777;        // Magic number for EA
input bool       UseKellyCriterion = true;   // Enable optimal position sizing
input int        MaxBarsBack = 500;          // History for correlation calculation

//--- Global variables
int rsi_handle, macd_handle, stoch_handle, atr_handle;
double point_value;
double win_rate = 0.5;  // Initial assumption
int total_trades = 0;
int winning_trades = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Get indicator handles
    rsi_handle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    macd_handle = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
    stoch_handle = iStochastic(_Symbol, _Period, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
    atr_handle = iATR(_Symbol, _Period, ATRPeriod);

    if (rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE ||
        stoch_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE)
    {
        Print("Failed to create indicator handles. Error: ", GetLastError());
        return(INIT_FAILED);
    }

    point_value = _Point;
    if (_Digits == 3 || _Digits == 5)
    {
        point_value = _Point * 10;
    }

    Print("=== VECTORUM EA INITIALIZED ===");
    PrintFormat("Symbol: %s, Timeframe: %s, Risk: %.1f%%", _Symbol, EnumToString(_Period), RiskPercent);
    PrintFormat("Correlation Threshold: %.2f, Vector Threshold: %.2f", MinCorrelation, VectorMagnitudeThreshold);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ReleaseHandle(rsi_handle);
    ReleaseHandle(macd_handle);
    ReleaseHandle(stoch_handle);
    ReleaseHandle(atr_handle);

    PrintFormat("=== VECTORUM EA DEINIT ===");
    PrintFormat("Total Trades: %d, Winning: %d, Win Rate: %.2f%%",
                total_trades, winning_trades, (total_trades > 0 ? (100.0 * winning_trades / total_trades) : 0.0));
}

//+------------------------------------------------------------------+
//| Release Indicator Handle                                         |
//+------------------------------------------------------------------+
void ReleaseHandle(int handle)
{
    if (handle != INVALID_HANDLE)
    {
        IndicatorRelease(handle);
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CheckForTradeSignal();
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Count EA Positions                                               |
//+------------------------------------------------------------------+
int CountEAPositions()
{
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
            count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| VECTOR MOMENTUM ANALYSIS                                         |
//| Returns magnitude (0-1) of momentum vector from 3 indicators     |
//+------------------------------------------------------------------+
double GetVectorMagnitude()
{
    // Get indicator values
    double rsi[1], macd_line[1], macd_signal[1], stoch_main[1];

    if (CopyBuffer(rsi_handle, 0, 0, 1, rsi) <= 0 ||
        CopyBuffer(macd_handle, 0, 0, 1, macd_line) <= 0 ||
        CopyBuffer(macd_handle, 1, 0, 1, macd_signal) <= 0 ||
        CopyBuffer(stoch_handle, 0, 0, 1, stoch_main) <= 0)
    {
        return 0.0;
    }

    // Normalize indicators to -1 to 1 range (as vector components)
    double rsi_normalized = (rsi[0] - 50.0) / 50.0;      // Range: -1 to 1
    double macd_normalized = (macd_line[0] - macd_signal[0]) > 0 ? 1.0 : -1.0; // Direction
    double stoch_normalized = (stoch_main[0] - 50.0) / 50.0; // Range: -1 to 1

    // Calculate vector magnitude: sqrt(x² + y² + z²)
    double magnitude = MathSqrt(rsi_normalized*rsi_normalized +
                               macd_normalized*macd_normalized +
                               stoch_normalized*stoch_normalized);

    // Normalize to 0-1 range (max magnitude for 3D vector is sqrt(3) ≈ 1.73)
    magnitude = magnitude / MathSqrt(3.0);

    PrintFormat("VECTOR: RSI=%.3f, MACD=%.3f, STOCH=%.3f, Magnitude=%.3f",
                rsi_normalized, macd_normalized, stoch_normalized, magnitude);

    return magnitude;
}

//+------------------------------------------------------------------+
//| CORRELATION MATRIX ANALYSIS                                      |
//| Returns correlation of indicators (confluence detection)         |
//+------------------------------------------------------------------+
double GetIndicatorCorrelation()
{
    double rsi_array[20], macd_array[20], stoch_array[20];

    // Get recent values
    if (CopyBuffer(rsi_handle, 0, 0, LookbackPeriod, rsi_array) <= 0 ||
        CopyBuffer(macd_handle, 0, 0, LookbackPeriod, macd_array) <= 0 ||
        CopyBuffer(stoch_handle, 0, 0, LookbackPeriod, stoch_array) <= 0)
    {
        return 0.0;
    }

    // Calculate correlation between RSI and MACD
    double corr_rsi_macd = CalculatePearsonCorrelation(rsi_array, macd_array, LookbackPeriod);

    // Calculate correlation between MACD and Stochastic
    double corr_macd_stoch = CalculatePearsonCorrelation(macd_array, stoch_array, LookbackPeriod);

    // Calculate correlation between RSI and Stochastic
    double corr_rsi_stoch = CalculatePearsonCorrelation(rsi_array, stoch_array, LookbackPeriod);

    // Average correlation (higher = stronger confluence)
    double avg_correlation = (MathAbs(corr_rsi_macd) + MathAbs(corr_macd_stoch) + MathAbs(corr_rsi_stoch)) / 3.0;

    PrintFormat("CORRELATION: RSI-MACD=%.3f, MACD-STOCH=%.3f, RSI-STOCH=%.3f, Avg=%.3f",
                corr_rsi_macd, corr_macd_stoch, corr_rsi_stoch, avg_correlation);

    return avg_correlation;
}

//+------------------------------------------------------------------+
//| PEARSON CORRELATION COEFFICIENT                                  |
//| Measures linear relationship between two data series (-1 to 1)   |
//+------------------------------------------------------------------+
double CalculatePearsonCorrelation(double &series1[], double &series2[], int size)
{
    if (size < 2) return 0.0;

    double mean1 = 0, mean2 = 0;

    // Calculate means
    for (int i = 0; i < size; i++)
    {
        mean1 += series1[i];
        mean2 += series2[i];
    }
    mean1 /= size;
    mean2 /= size;

    // Calculate covariance and standard deviations
    double covariance = 0, std1 = 0, std2 = 0;
    for (int i = 0; i < size; i++)
    {
        double diff1 = series1[i] - mean1;
        double diff2 = series2[i] - mean2;
        covariance += diff1 * diff2;
        std1 += diff1 * diff1;
        std2 += diff2 * diff2;
    }

    std1 = MathSqrt(std1 / size);
    std2 = MathSqrt(std2 / size);

    if (std1 == 0 || std2 == 0) return 0.0;

    return covariance / (size * std1 * std2);
}

//+------------------------------------------------------------------+
//| Get Signal Direction (1=BUY, -1=SELL, 0=NONE)                    |
//+------------------------------------------------------------------+
int GetSignalDirection()
{
    double rsi[1], macd_line[1], macd_signal[1], stoch[1];

    if (CopyBuffer(rsi_handle, 0, 0, 1, rsi) <= 0 ||
        CopyBuffer(macd_handle, 0, 0, 1, macd_line) <= 0 ||
        CopyBuffer(macd_handle, 1, 0, 1, macd_signal) <= 0 ||
        CopyBuffer(stoch_handle, 0, 0, 1, stoch) <= 0)
    {
        return 0;
    }

    int buy_signals = 0, sell_signals = 0;

    // RSI signal (oversold/overbought)
    if (rsi[0] < 40) buy_signals++;
    if (rsi[0] > 60) sell_signals++;

    // MACD signal (line above/below signal)
    if (macd_line[0] > macd_signal[0]) buy_signals++;
    if (macd_line[0] < macd_signal[0]) sell_signals++;

    // Stochastic signal
    if (stoch[0] < 30) buy_signals++;
    if (stoch[0] > 70) sell_signals++;

    if (buy_signals >= 2) return 1;
    if (sell_signals >= 2) return -1;
    return 0;
}

//+------------------------------------------------------------------+
//| CHECK FOR TRADE SIGNAL                                           |
//+------------------------------------------------------------------+
void CheckForTradeSignal()
{
    if (CountEAPositions() >= MaxOpenPositions)
    {
        return;
    }

    // Step 1: Calculate Vector Magnitude (momentum strength)
    double vector_mag = GetVectorMagnitude();
    if (vector_mag < VectorMagnitudeThreshold)
    {
        Print("SKIP: Vector magnitude too low (", vector_mag, " < ", VectorMagnitudeThreshold, ")");
        return;
    }

    // Step 2: Get Signal Direction
    int signal = GetSignalDirection();
    if (signal == 0)
    {
        Print("SKIP: No directional consensus");
        return;
    }

    // Step 3: Check Correlation (confluence detection)
    double correlation = GetIndicatorCorrelation();
    if (correlation < MinCorrelation)
    {
        PrintFormat("SKIP: Correlation too low (%.3f < %.3f)", correlation, MinCorrelation);
        return;
    }

    // Step 4: All checks passed - execute trade!
    PrintFormat("SIGNAL GENERATED: Direction=%s, Magnitude=%.3f, Correlation=%.3f",
                (signal == 1 ? "BUY" : "SELL"), vector_mag, correlation);

    ENUM_ORDER_TYPE order_type = (signal == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    ExecuteTrade(order_type);
}

//+------------------------------------------------------------------+
//| CALCULATE OPTIMAL POSITION SIZE (KELLY CRITERION)                |
//| Optimal f = (BP * P - L) / B                                     |
//| P = Win probability, L = Loss per winning trade, B = Payoff      |
//+------------------------------------------------------------------+
double CalculatePositionSize(double entry_price, double stop_loss)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPercent / 100.0);

    // Calculate pip distance
    double price_diff = MathAbs(entry_price - stop_loss);
    double pip_distance = price_diff / point_value;

    if (pip_distance <= 0)
    {
        Print("Invalid SL distance");
        return 0.01;
    }

    // Get contract size and pip value
    double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double pip_value = (point_value * contract_size) / 100.0;

    // Base position size (risk-based)
    double position_size = risk_amount / (pip_distance * pip_value);

    // Apply Kelly Criterion if enabled
    if (UseKellyCriterion && total_trades >= 10)
    {
        double kelly_fraction = (2.0 * win_rate - 1.0) * KellyCriterion; // Simplified Kelly
        if (kelly_fraction < 0) kelly_fraction = 0;
        if (kelly_fraction > 1) kelly_fraction = 1;

        position_size *= kelly_fraction;
        PrintFormat("KELLY ADJUSTMENT: WinRate=%.2f%%, Fraction=%.3f", win_rate * 100, kelly_fraction);
    }

    // Apply lot limits
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

    position_size = MathFloor(position_size / lot_step) * lot_step;
    if (position_size < min_lot) position_size = min_lot;
    if (position_size > max_lot) position_size = max_lot;

    PrintFormat("POSITION SIZING: Balance=%.2f, Risk=%.2f, PipDist=%.1f, Lots=%.2f",
                account_balance, risk_amount, pip_distance, position_size);

    return position_size;
}

//+------------------------------------------------------------------+
//| CALCULATE VOLATILITY-ADJUSTED STOP LOSS                          |
//+------------------------------------------------------------------+
double CalculateVolatilityStop(double entry_price, int signal_direction)
{
    double atr[1];
    if (CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
    {
        Print("Failed to get ATR");
        return 0;
    }

    double stop_loss;
    if (signal_direction == 1) // BUY
    {
        stop_loss = entry_price - (atr[0] * VolatilityMultiplier);
    }
    else // SELL
    {
        stop_loss = entry_price + (atr[0] * VolatilityMultiplier);
    }

    // Validate SL distance
    double min_sl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point_value;
    double sl_dist = MathAbs(entry_price - stop_loss);

    if (sl_dist < min_sl)
    {
        PrintFormat("SL too close, adjusting from %.5f to %.5f", stop_loss,
                   (signal_direction == 1) ? entry_price - min_sl : entry_price + min_sl);
        stop_loss = (signal_direction == 1) ? entry_price - min_sl : entry_price + min_sl;
    }

    PrintFormat("VOLATILITY STOP: ATR=%.5f, Stop=%.5f", atr[0], stop_loss);
    return stop_loss;
}

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE order_type)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double entry_price = (order_type == ORDER_TYPE_BUY) ? ask : bid;

    // Calculate stops
    double stop_loss = CalculateVolatilityStop(entry_price, order_type == ORDER_TYPE_BUY ? 1 : -1);

    // Calculate TP (Risk:Reward = 1:2)
    double sl_distance = MathAbs(entry_price - stop_loss);
    double take_profit = (order_type == ORDER_TYPE_BUY) ?
                        entry_price + (sl_distance * 2.0) :
                        entry_price - (sl_distance * 2.0);

    // Calculate position size
    double volume = CalculatePositionSize(entry_price, stop_loss);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.type = order_type;
    request.volume = volume;
    request.price = entry_price;
    request.sl = stop_loss;
    request.tp = take_profit;
    request.deviation = 10;
    request.magic = MagicNumber;

    if (!OrderSend(request, result))
    {
        PrintFormat("Trade execution failed. Error: %d", GetLastError());
    }
    else
    {
        PrintFormat("TRADE EXECUTED: Type=%s, Entry=%.5f, SL=%.5f, TP=%.5f, Volume=%.2f",
                    (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
                    entry_price, stop_loss, take_profit, volume);
        total_trades++;
    }
}

//+------------------------------------------------------------------+
//| MANAGE POSITIONS (EXIT LOGIC)                                    |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_price = (type == POSITION_TYPE_BUY) ?
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Calculate profit
        double profit = (type == POSITION_TYPE_BUY) ?
                       (current_price - open_price) * 100000 :
                       (open_price - current_price) * 100000;

        // CHECK EXIT CONDITION: Correlation breakdown (loss of confluence)
        double correlation = GetIndicatorCorrelation();
        double vector_mag = GetVectorMagnitude();

        if (correlation < (MinCorrelation * 0.5) || vector_mag < (VectorMagnitudeThreshold * 0.3))
        {
            PrintFormat("EXIT SIGNAL: Confluence breakdown (Corr=%.3f, Vec=%.3f)", correlation, vector_mag);
            CloseTrade(ticket);

            if (profit > 0) winning_trades++;
            continue;
        }

        // Trailing stop: Move SL 50% toward entry when in profit
        if (profit > 50) // 5 pips profit
        {
            double current_sl = PositionGetDouble(POSITION_SL);
            double new_sl = (open_price + current_price) / 2.0;

            if (type == POSITION_TYPE_BUY && new_sl > current_sl)
            {
                ModifyTrade(ticket, new_sl);
            }
            else if (type == POSITION_TYPE_SELL && new_sl < current_sl)
            {
                ModifyTrade(ticket, new_sl);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| CLOSE TRADE                                                      |
//+------------------------------------------------------------------+
void CloseTrade(ulong ticket)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = _Symbol;
    request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ?
                  ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.deviation = 10;

    double close_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request.price = close_price;

    if (OrderSend(request, result))
    {
        PrintFormat("Position #%I64u closed at %.5f", ticket, close_price);
    }
}

//+------------------------------------------------------------------+
//| MODIFY TRADE (SL/TP)                                             |
//+------------------------------------------------------------------+
void ModifyTrade(ulong ticket, double new_sl)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.sl = new_sl;
    request.tp = PositionGetDouble(POSITION_TP);

    if (OrderSend(request, result))
    {
        PrintFormat("Position #%I64u modified, new SL=%.5f", ticket, new_sl);
    }
}

//+------------------------------------------------------------------+
