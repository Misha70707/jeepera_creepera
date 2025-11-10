//+------------------------------------------------------------------+
//|                                   EA_3_Advanced_Ichimoku.mq5 |
//|                                                      Manus AI |
//|                                          https://www.manus.im |
//+------------------------------------------------------------------+
#property copyright "Manus AI"
#property link      "https://www.manus.im"
#property version   "3.01"
#property description "Advanced Ichimoku EA with MTF, Chikou Filter, Dynamic SL/TP, Break-Even, and Risk Management"

//--- Input parameters
input double RiskPercent = 2.0;      // Risk % per trade (position sizing)
input double FixedLotSize = 0.0;    // Fixed lot size (0 = use risk-based sizing)
input int    MagicNumber = 33333;    // Magic Number for EA
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H4; // Higher Timeframe for Trend Filter
input int    TenkanSen = 9;          // Tenkan-sen period
input int    KijunSen = 26;          // Kijun-sen period
input int    SenkouSpanB = 52;       // Senkou Span B period
input int    RiskRewardRatio = 2;    // Risk:Reward ratio for TP calculation
input int    MaxSpreadsPointsAllowed = 20; // Max spread to allow trades (in points)
input int    TrailingStopPips = 150; // Trailing Stop in points
input int    BreakEvenPips = 100;    // Profit in points to move to Break-Even
input int    MaxOpenPositions = 2;   // Maximum concurrent positions
input bool   UseChikouFilter = true; // Enable Chikou Span filter

//--- Global variables
int ichimoku_handle;
int ichimoku_trend_handle;
double point_value;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Get Ichimoku handle for current chart
    ichimoku_handle = iIchimoku(_Symbol, _Period, TenkanSen, KijunSen, SenkouSpanB);
    if (ichimoku_handle == INVALID_HANDLE)
    {
        Print("Failed to get Ichimoku handle. Error: ", GetLastError());
        return(INIT_FAILED);
    }

    //--- Get Ichimoku handle for trend timeframe
    ichimoku_trend_handle = iIchimoku(_Symbol, TrendTimeframe, TenkanSen, KijunSen, SenkouSpanB);
    if (ichimoku_trend_handle == INVALID_HANDLE)
    {
        Print("Failed to get Trend Ichimoku handle. Error: ", GetLastError());
        return(INIT_FAILED);
    }

    //--- Determine the point value for SL/TP calculation
    point_value = _Point;
    if (_Digits == 3 || _Digits == 5)
    {
        point_value = _Point * 10; // Adjust for 3 or 5 digit brokers
    }

    Print("EA initialized successfully. Magic: ", MagicNumber, ", Symbol: ", _Symbol);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ReleaseHandle(ichimoku_handle);
    ReleaseHandle(ichimoku_trend_handle);
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
    //--- Check for trade signals
    CheckForTradeSignal();

    //--- Manage open positions (Break-Even and Trailing Stop)
    ManagePositions();
}

//+------------------------------------------------------------------+
//| Count positions with EA's magic number                           |
//+------------------------------------------------------------------+
int CountEAPositions()
{
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong position_ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
            count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check spread is acceptable                                       |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable()
{
    long spread_points = (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
    if (spread_points > MaxSpreadsPointsAllowed)
    {
        Print("Spread too wide: ", spread_points, " > ", MaxSpreadsPointsAllowed);
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Check for Trade Signal                                           |
//+------------------------------------------------------------------+
void CheckForTradeSignal()
{
    // Check if we can open new trades
    if (CountEAPositions() >= MaxOpenPositions)
    {
        return;
    }

    // Check spread
    if (!IsSpreadAcceptable())
    {
        return;
    }

    //--- 1. Get Trend Filter (Higher Timeframe)
    int trend_direction = GetTrendDirection(ichimoku_trend_handle);
    if (trend_direction == 0) // Neutral trend
    {
        return;
    }

    //--- 2. Get Entry Signal (Current Timeframe)
    int entry_signal = GetEntrySignal(ichimoku_handle);
    if (entry_signal == 0)
    {
        return;
    }

    //--- 3. Get Chikou Span Filter (optional)
    int chikou_filter = 0;
    if (UseChikouFilter)
    {
        chikou_filter = GetChikouFilter(ichimoku_handle);
        if (chikou_filter == 0) // Chikou filter failed
        {
            return;
        }
    }
    else
    {
        chikou_filter = entry_signal; // Use entry signal as filter if Chikou disabled
    }

    //--- 4. Execute Trade based on confluence
    if (entry_signal == 1 && trend_direction == 1 && chikou_filter == 1) // Buy Signal + Uptrend + Chikou OK
    {
        ExecuteTrade(ORDER_TYPE_BUY, MagicNumber);
    }
    else if (entry_signal == -1 && trend_direction == -1 && chikou_filter == -1) // Sell Signal + Downtrend + Chikou OK
    {
        ExecuteTrade(ORDER_TYPE_SELL, MagicNumber);
    }
}

//+------------------------------------------------------------------+
//| Get Trend Direction (1=Up, -1=Down, 0=Neutral)                   |
//+------------------------------------------------------------------+
int GetTrendDirection(int handle)
{
    double kumo_a[1], kumo_b[1];

    // Buffer indices: 0=Tenkan, 1=Kijun, 2=Senkou A, 3=Senkou B, 4=Chikou
    if (CopyBuffer(handle, 2, 0, 1, kumo_a) <= 0 ||
        CopyBuffer(handle, 3, 0, 1, kumo_b) <= 0)
    {
        return(0);
    }

    if (kumo_a[0] > kumo_b[0]) return(1);   // Bullish (Senkou A above B)
    if (kumo_a[0] < kumo_b[0]) return(-1);  // Bearish (Senkou A below B)
    return(0);
}

//+------------------------------------------------------------------+
//| Get Entry Signal (1=Buy, -1=Sell, 0=None)                        |
//+------------------------------------------------------------------+
int GetEntrySignal(int handle)
{
    // Tenkan/Kijun Crossover + Price confirmation
    double tenkan_sen_buffer[2];
    double kijun_sen_buffer[2];
    double close_price[1];

    // Get current and previous values (indices 0 and 1)
    // Buffer indices: 0=Tenkan, 1=Kijun, 2=Senkou A, 3=Senkou B, 4=Chikou
    if (CopyBuffer(handle, 0, 0, 2, tenkan_sen_buffer) <= 0 ||
        CopyBuffer(handle, 1, 0, 2, kijun_sen_buffer) <= 0 ||
        CopyClose(_Symbol, _Period, 0, 1, close_price) <= 0)
    {
        return(0);
    }

    double tenkan_current = tenkan_sen_buffer[0];
    double tenkan_previous = tenkan_sen_buffer[1];
    double kijun_current = kijun_sen_buffer[0];
    double kijun_previous = kijun_sen_buffer[1];

    // Buy Signal: Tenkan crosses above Kijun AND close is above Kijun
    if (tenkan_previous <= kijun_previous && tenkan_current > kijun_current && close_price[0] > kijun_current)
    {
        return(1);
    }

    // Sell Signal: Tenkan crosses below Kijun AND close is below Kijun
    if (tenkan_previous >= kijun_previous && tenkan_current < kijun_current && close_price[0] < kijun_current)
    {
        return(-1);
    }

    return(0);
}

//+------------------------------------------------------------------+
//| Get Chikou Span Filter (1=Buy OK, -1=Sell OK, 0=Not OK)          |
//+------------------------------------------------------------------+
int GetChikouFilter(int handle)
{
    // Chikou Span is the close price shifted forward 26 periods
    // We check: is Chikou (current close shifted) above prices ahead?
    // Practical implementation: Chikou above price 26 periods ago = bullish

    double chikou_span[1];
    double price_ahead[1]; // Price that was 26 periods ahead (now current)

    // Get Chikou Span at current bar (buffer index 4)
    if (CopyBuffer(handle, 4, 0, 1, chikou_span) <= 0)
    {
        return(0);
    }

    // Get close price from 26 bars ago to compare
    if (CopyClose(_Symbol, _Period, KijunSen, 1, price_ahead) <= 0)
    {
        return(0);
    }

    // Chikou Span > Price 26 bars ago = Bullish (buy filter OK)
    if (chikou_span[0] > price_ahead[0])
    {
        return(1);
    }
    // Chikou Span < Price 26 bars ago = Bearish (sell filter OK)
    else if (chikou_span[0] < price_ahead[0])
    {
        return(-1);
    }

    return(0);
}

//+------------------------------------------------------------------+
//| Calculate Position Size based on Risk                             |
//+------------------------------------------------------------------+
double CalculatePositionSize(double entry_price, double stop_loss_price)
{
    if (FixedLotSize > 0)
    {
        return FixedLotSize;
    }

    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPercent / 100.0);
    double price_difference = MathAbs(entry_price - stop_loss_price);

    if (price_difference <= 0)
    {
        return 0.01; // Fallback minimum
    }

    double position_size = risk_amount / price_difference;

    // Get symbol lot step and limits
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

    // Round to lot step
    position_size = MathFloor(position_size / lot_step) * lot_step;

    // Ensure within limits
    if (position_size < min_lot) position_size = min_lot;
    if (position_size > max_lot) position_size = max_lot;

    return position_size;
}

//+------------------------------------------------------------------+
//| Trade Execution Function                                         |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE type, int magic)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.type = type;
    request.deviation = 10; // Slippage in points
    request.magic = magic;

    // Get current price
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double entry_price = (type == ORDER_TYPE_BUY) ? ask_price : bid_price;

    // Calculate Dynamic SL based on Kijun-Sen (buffer index 1)
    double kijun_current[1];
    double stop_loss = 0;

    if (CopyBuffer(ichimoku_handle, 1, 0, 1, kijun_current) <= 0)
    {
        Print("Failed to get Kijun-Sen for Dynamic SL. Aborting trade.");
        return;
    }

    if (type == ORDER_TYPE_BUY)
    {
        request.price = ask_price;
        // SL below Kijun-Sen
        stop_loss = kijun_current[0] - 5 * point_value; // 5 points buffer
    }
    else if (type == ORDER_TYPE_SELL)
    {
        request.price = bid_price;
        // SL above Kijun-Sen
        stop_loss = kijun_current[0] + 5 * point_value; // 5 points buffer
    }

    // Validate SL is not too close
    double min_sl_distance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point_value;
    double sl_distance = MathAbs(entry_price - stop_loss);

    if (sl_distance < min_sl_distance)
    {
        Print("SL too close to entry. Minimum required: ", min_sl_distance / point_value, " points. Aborting.");
        return;
    }

    request.sl = stop_loss;

    // Calculate Take Profit based on Risk:Reward ratio
    double risk_distance = MathAbs(entry_price - stop_loss);
    double tp_distance = risk_distance * RiskRewardRatio;
    double take_profit = 0;

    if (type == ORDER_TYPE_BUY)
    {
        take_profit = entry_price + tp_distance;
    }
    else if (type == ORDER_TYPE_SELL)
    {
        take_profit = entry_price - tp_distance;
    }

    request.tp = take_profit;

    // Calculate position size
    double volume = CalculatePositionSize(entry_price, stop_loss);
    if (volume <= 0)
    {
        Print("Invalid position size calculated. Aborting trade.");
        return;
    }

    request.volume = volume;

    // Send the request
    if (!OrderSend(request, result))
    {
        PrintFormat("OrderSend failed. Error: %d", GetLastError());
    }
    else
    {
        PrintFormat("Trade executed successfully. Type: %s, Entry: %f, SL: %f, TP: %f, Volume: %f",
                    (type == ORDER_TYPE_BUY ? "BUY" : "SELL"), request.price, request.sl, request.tp, request.volume);
    }
}

//+------------------------------------------------------------------+
//| Position Management (Break-Even and Trailing Stop)               |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong position_ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber)
        {
            continue;
        }

        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_sl = PositionGetDouble(POSITION_SL);
        double current_tp = PositionGetDouble(POSITION_TP);
        double current_price = (type == POSITION_TYPE_BUY) ?
            SymbolInfoDouble(_Symbol, SYMBOL_BID) :
            SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        double profit_pips = (type == POSITION_TYPE_BUY) ?
            (current_price - open_price) / point_value :
            (open_price - current_price) / point_value;

        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);

        request.action = TRADE_ACTION_SLTP;
        request.position = position_ticket;

        // --- 1. Break-Even Logic ---
        if (profit_pips >= BreakEvenPips && current_sl < open_price)
        {
            double new_sl = open_price;

            if (type == POSITION_TYPE_BUY && current_sl < new_sl)
            {
                request.sl = new_sl;
                if (!OrderSend(request, result))
                {
                    PrintFormat("Break-Even modification failed for #%I64u. Error: %d", position_ticket, GetLastError());
                }
                else
                {
                    PrintFormat("Break-Even activated for #%I64u to %f", position_ticket, new_sl);
                    current_sl = new_sl;
                }
            }
            else if (type == POSITION_TYPE_SELL && current_sl > new_sl)
            {
                request.sl = new_sl;
                if (!OrderSend(request, result))
                {
                    PrintFormat("Break-Even modification failed for #%I64u. Error: %d", position_ticket, GetLastError());
                }
                else
                {
                    PrintFormat("Break-Even activated for #%I64u to %f", position_ticket, new_sl);
                    current_sl = new_sl;
                }
            }
        }

        // --- 2. Trailing Stop Logic ---
        double min_profit_pips = TrailingStopPips;
        double min_profit_points = min_profit_pips * point_value;

        if (profit_pips >= min_profit_pips)
        {
            double new_sl = 0;

            if (type == POSITION_TYPE_BUY)
            {
                new_sl = current_price - min_profit_points;
                // Only modify if the new SL is higher than the current SL
                if (new_sl > current_sl)
                {
                    request.sl = new_sl;
                    request.tp = current_tp; // Keep existing TP
                    if (!OrderSend(request, result))
                    {
                        PrintFormat("Trailing Stop modification failed for #%I64u. Error: %d", position_ticket, GetLastError());
                    }
                    else
                    {
                        PrintFormat("Trailing Stop moved for #%I64u to %f", position_ticket, new_sl);
                    }
                }
            }
            else if (type == POSITION_TYPE_SELL)
            {
                new_sl = current_price + min_profit_points;
                // Only modify if the new SL is lower than the current SL
                if (new_sl < current_sl)
                {
                    request.sl = new_sl;
                    request.tp = current_tp; // Keep existing TP
                    if (!OrderSend(request, result))
                    {
                        PrintFormat("Trailing Stop modification failed for #%I64u. Error: %d", position_ticket, GetLastError());
                    }
                    else
                    {
                        PrintFormat("Trailing Stop moved for #%I64u to %f", position_ticket, new_sl);
                    }
                }
            }
        }
    }
}
//+------------------------------------------------------------------+
