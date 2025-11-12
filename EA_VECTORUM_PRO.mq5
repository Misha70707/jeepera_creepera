//+------------------------------------------------------------------+
//|                              EA_VECTORUM_PRO.mq5                 |
//|                                          Claude Code Design       |
//| Advanced Exit Strategy + Market Condition Detection (EURUSD)      |
//+------------------------------------------------------------------+
#property copyright "Claude Code"
#property link      "https://www.claude.ai"
#property version   "2.0"
#property description "VECTORUM PRO: Smart Exits + Market Detector for EURUSD"

//--- Input parameters
input double     RiskPercent = 2.0;           // Risk per trade (%)
input int        LookbackPeriod = 20;        // Lookback for correlation
input double     MinCorrelation = 0.70;      // Confluence correlation
input double     VectorMagnitudeThreshold = 0.65; // Signal strength
input double     KellyCriterion = 0.25;      // Kelly multiplier
input int        ATRPeriod = 14;             // Volatility period
input double     VolatilityMultiplier = 1.5; // Stop distance = ATR * this
input int        MaxOpenPositions = 1;       // Max concurrent positions
input int        MagicNumber = 77777;        // Magic number
input bool       UseSmartExits = true;       // Enable smart exits
input bool       UseMarketDetector = true;   // Enable market detector
input int        BreakevenProfitPips = 10;   // Profit to move to breakeven
input double     TrailingStopPercent = 0.5;  // Trailing % of risk
input int        MaxConsecutiveLosses = 3;   // Stop after X losses

//--- Global variables
int rsi_handle, macd_handle, stoch_handle, atr_handle;
double point_value;
int consecutive_losses = 0;

//--- Market Condition Enum
enum MARKET_CONDITION {
    MARKET_TRENDING_UP = 1,
    MARKET_TRENDING_DOWN = -1,
    MARKET_CHOPPY = 0,
    MARKET_UNKNOWN = 2
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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

    Print("=== VECTORUM PRO INITIALIZED (EURUSD) ===");
    PrintFormat("Smart Exits: %s, Market Detector: %s",
                UseSmartExits ? "ON" : "OFF", UseMarketDetector ? "ON" : "OFF");

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

    Print("=== VECTORUM PRO DEINIT ===");
}

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
    // Market condition check
    MARKET_CONDITION market = DetectMarketCondition();

    // Skip trading in choppy markets
    if (UseMarketDetector && market == MARKET_CHOPPY)
    {
        Print("⚠️ CHOPPY MARKET DETECTED - Skipping entries");
        ManagePositions(market);
        return;
    }

    CheckForTradeSignal(market);
    ManagePositions(market);
}

//+------------------------------------------------------------------+
//| DETECT MARKET CONDITION (Trending vs Choppy)                     |
//+------------------------------------------------------------------+
MARKET_CONDITION DetectMarketCondition()
{
    // Get ADX (Average Directional Index) equivalent
    double close_array[20];
    double high_array[20];
    double low_array[20];

    if (CopyClose(_Symbol, _Period, 0, 20, close_array) <= 0 ||
        CopyHigh(_Symbol, _Period, 0, 20, high_array) <= 0 ||
        CopyLow(_Symbol, _Period, 0, 20, low_array) <= 0)
    {
        return MARKET_UNKNOWN;
    }

    // Calculate trend strength using range analysis
    double total_range = 0;
    double true_range = 0;

    for (int i = 0; i < 20; i++)
    {
        double range = high_array[i] - low_array[i];
        total_range += range;

        if (i > 0)
        {
            double tr = MathMax(high_array[i] - low_array[i],
                               MathMax(MathAbs(high_array[i] - close_array[i+1]),
                                      MathAbs(low_array[i] - close_array[i+1])));
            true_range += tr;
        }
    }

    double avg_range = total_range / 20;
    double avg_tr = true_range / 19;

    // Volatility ratio
    double volatility_ratio = (avg_tr > 0) ? avg_range / avg_tr : 1.0;

    // Check trend direction
    double sma_fast = iMA(_Symbol, _Period, 5, 0, MODE_SMA, PRICE_CLOSE, 0);
    double sma_slow = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
    double current_close = iClose(_Symbol, _Period, 0);

    if (volatility_ratio > 0.8) // Trending market
    {
        if (current_close > sma_fast && sma_fast > sma_slow)
            return MARKET_TRENDING_UP;
        else if (current_close < sma_fast && sma_fast < sma_slow)
            return MARKET_TRENDING_DOWN;
    }

    // Choppy market
    return MARKET_CHOPPY;
}

//+------------------------------------------------------------------+
//| COUNT EA POSITIONS                                                |
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
//| CHECK FOR TRADE SIGNAL                                            |
//+------------------------------------------------------------------+
void CheckForTradeSignal(MARKET_CONDITION market)
{
    // Don't trade after too many consecutive losses
    if (consecutive_losses >= MaxConsecutiveLosses)
    {
        Print("⛔ Max consecutive losses reached. Trading disabled.");
        return;
    }

    if (CountEAPositions() >= MaxOpenPositions)
        return;

    // Get vector and correlation
    double rsi[1], macd_line[1], macd_signal[1], stoch[1];

    if (CopyBuffer(rsi_handle, 0, 0, 1, rsi) <= 0 ||
        CopyBuffer(macd_handle, 0, 0, 1, macd_line) <= 0 ||
        CopyBuffer(macd_handle, 1, 0, 1, macd_signal) <= 0 ||
        CopyBuffer(stoch_handle, 0, 0, 1, stoch) <= 0)
    {
        return;
    }

    double vector_mag = GetVectorMagnitude(rsi[0], macd_line[0], stoch[0]);
    if (vector_mag < VectorMagnitudeThreshold)
        return;

    int signal = GetSignalDirection(rsi[0], macd_line[0], macd_signal[0], stoch[0]);

    if (signal != 0)
    {
        ENUM_ORDER_TYPE order_type = (signal == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        ExecuteTrade(order_type, market);
    }
}

//+------------------------------------------------------------------+
//| GET VECTOR MAGNITUDE                                              |
//+------------------------------------------------------------------+
double GetVectorMagnitude(double rsi, double macd_line, double stoch)
{
    double rsi_norm = (rsi - 50.0) / 50.0;
    double macd_norm = macd_line > 0 ? 1.0 : -1.0;
    double stoch_norm = (stoch - 50.0) / 50.0;

    double magnitude = MathSqrt(rsi_norm*rsi_norm + macd_norm*macd_norm + stoch_norm*stoch_norm) / MathSqrt(3.0);

    return MathMin(1.0, magnitude);
}

//+------------------------------------------------------------------+
//| GET SIGNAL DIRECTION                                              |
//+------------------------------------------------------------------+
int GetSignalDirection(double rsi, double macd_line, double macd_signal, double stoch)
{
    int buy_signals = 0, sell_signals = 0;

    if (rsi < 40) buy_signals++;
    if (rsi > 60) sell_signals++;

    if (macd_line > macd_signal) buy_signals++;
    if (macd_line < macd_signal) sell_signals++;

    if (stoch < 30) buy_signals++;
    if (stoch > 70) sell_signals++;

    if (buy_signals >= 2) return 1;
    if (sell_signals >= 2) return -1;
    return 0;
}

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE order_type, MARKET_CONDITION market)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double entry_price = (order_type == ORDER_TYPE_BUY) ? ask : bid;

    // Dynamic SL based on ATR
    double atr[1];
    if (CopyBuffer(atr_handle, 0, 0, 1, atr) <= 0)
        return;

    double sl_distance = atr[0] * VolatilityMultiplier;
    double stop_loss = (order_type == ORDER_TYPE_BUY) ?
                      entry_price - sl_distance :
                      entry_price + sl_distance;

    // TP at 2:1 Risk:Reward
    double tp_distance = sl_distance * 2.0;
    double take_profit = (order_type == ORDER_TYPE_BUY) ?
                        entry_price + tp_distance :
                        entry_price - tp_distance;

    // Position sizing
    double position_size = CalculatePositionSize(entry_price, stop_loss);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.type = order_type;
    request.volume = position_size;
    request.price = entry_price;
    request.sl = stop_loss;
    request.tp = take_profit;
    request.deviation = 10;
    request.magic = MagicNumber;

    if (!OrderSend(request, result))
    {
        PrintFormat("Trade failed. Error: %d", GetLastError());
    }
    else
    {
        PrintFormat("TRADE OPENED: %s, SL=%.5f, TP=%.5f, Volume=%.2f, Market=%d",
                    (order_type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
                    stop_loss, take_profit, position_size, market);
        consecutive_losses = 0;
    }
}

//+------------------------------------------------------------------+
//| CALCULATE POSITION SIZE                                           |
//+------------------------------------------------------------------+
double CalculatePositionSize(double entry_price, double stop_loss)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPercent / 100.0);

    double price_diff = MathAbs(entry_price - stop_loss);
    double pip_distance = price_diff / point_value;

    if (pip_distance <= 0)
        return 0.01;

    double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double pip_value = (point_value * contract_size) / 100.0;
    double position_size = risk_amount / (pip_distance * pip_value);

    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

    position_size = MathFloor(position_size / lot_step) * lot_step;
    if (position_size < min_lot) position_size = min_lot;
    if (position_size > max_lot) position_size = max_lot;

    return position_size;
}

//+------------------------------------------------------------------+
//| MANAGE POSITIONS (Smart Exits + Breakeven)                       |
//+------------------------------------------------------------------+
void ManagePositions(MARKET_CONDITION market)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;

        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_price = (type == POSITION_TYPE_BUY) ?
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        double profit_pips = (type == POSITION_TYPE_BUY) ?
                           (current_price - open_price) / point_value :
                           (open_price - current_price) / point_value;

        // Check for exit conditions
        bool should_exit = false;
        string exit_reason = "";

        // 1️⃣ BREAKEVEN PROTECTION
        if (UseSmartExits && profit_pips >= BreakevenProfitPips)
        {
            double current_sl = PositionGetDouble(POSITION_SL);
            double new_sl = open_price;

            if ((type == POSITION_TYPE_BUY && new_sl > current_sl) ||
                (type == POSITION_TYPE_SELL && new_sl < current_sl))
            {
                ModifyTrade(ticket, new_sl, PositionGetDouble(POSITION_TP));
                PrintFormat("BREAKEVEN activated for #%I64u", ticket);
            }
        }

        // 2️⃣ TRAILING STOP
        if (UseSmartExits && profit_pips > 0)
        {
            double atr[1];
            if (CopyBuffer(atr_handle, 0, 0, 1, atr) > 0)
            {
                double current_sl = PositionGetDouble(POSITION_SL);
                double trailing_distance = atr[0] * VolatilityMultiplier * TrailingStopPercent;
                double new_sl = 0;

                if (type == POSITION_TYPE_BUY)
                {
                    new_sl = current_price - trailing_distance;
                    if (new_sl > current_sl)
                    {
                        ModifyTrade(ticket, new_sl, PositionGetDouble(POSITION_TP));
                        PrintFormat("TRAILING STOP updated for #%I64u to %.5f", ticket, new_sl);
                    }
                }
                else if (type == POSITION_TYPE_SELL)
                {
                    new_sl = current_price + trailing_distance;
                    if (new_sl < current_sl)
                    {
                        ModifyTrade(ticket, new_sl, PositionGetDouble(POSITION_TP));
                        PrintFormat("TRAILING STOP updated for #%I64u to %.5f", ticket, new_sl);
                    }
                }
            }
        }

        // 3️⃣ MARKET CONDITION EXIT
        if (UseSmartExits && UseMarketDetector && market == MARKET_CHOPPY)
        {
            if (profit_pips > 5) // Only exit if profitable in choppy market
            {
                should_exit = true;
                exit_reason = "Market turned choppy (profit protection)";
            }
        }

        // 4️⃣ REVERSAL EXIT
        if (UseSmartExits)
        {
            double rsi[1], macd_line[1], macd_signal[1], stoch[1];

            if (CopyBuffer(rsi_handle, 0, 0, 1, rsi) > 0 &&
                CopyBuffer(macd_handle, 0, 0, 1, macd_line) > 0 &&
                CopyBuffer(macd_handle, 1, 0, 1, macd_signal) > 0 &&
                CopyBuffer(stoch_handle, 0, 0, 1, stoch) > 0)
            {
                int reversal_signal = GetSignalDirection(rsi[0], macd_line[0], macd_signal[0], stoch[0]);

                if (type == POSITION_TYPE_BUY && reversal_signal == -1 && profit_pips > 0)
                {
                    should_exit = true;
                    exit_reason = "Bearish reversal signal (profitable)";
                }
                else if (type == POSITION_TYPE_SELL && reversal_signal == 1 && profit_pips > 0)
                {
                    should_exit = true;
                    exit_reason = "Bullish reversal signal (profitable)";
                }
            }
        }

        if (should_exit)
        {
            CloseTrade(ticket, current_price, exit_reason);

            if (profit_pips < 0)
                consecutive_losses++;
            else
                consecutive_losses = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| MODIFY TRADE                                                     |
//+------------------------------------------------------------------+
void ModifyTrade(ulong ticket, double new_sl, double new_tp)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.sl = new_sl;
    request.tp = new_tp;

    OrderSend(request, result);
}

//+------------------------------------------------------------------+
//| CLOSE TRADE                                                      |
//+------------------------------------------------------------------+
void CloseTrade(ulong ticket, double close_price, string reason)
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
    request.price = close_price;
    request.deviation = 10;

    if (OrderSend(request, result))
    {
        PrintFormat("POSITION CLOSED #%I64u: %s", ticket, reason);
    }
}

//+------------------------------------------------------------------+
