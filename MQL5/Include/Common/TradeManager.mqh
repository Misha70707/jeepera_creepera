//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                     Robust Trade Execution and Management Class |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| CTradeManager Class                                              |
//| Handles all trade execution with proper error handling          |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
    CTrade         m_trade;
    ulong          m_magicNumber;
    string         m_comment;
    int            m_slippage;
    int            m_maxRetries;
    int            m_retryDelay;   // milliseconds

    bool           ExecuteWithRetry(bool (CTrade::*tradeFunc)(), int retries);
    void           LogTradeResult(string operation);

public:
                   CTradeManager();
                  ~CTradeManager();

    // Initialization
    bool           Init(ulong magicNumber, string comment = "");
    void           Deinit();

    // Configuration
    void           SetSlippage(int slippage);
    void           SetMaxRetries(int retries);
    void           SetFillType(ENUM_ORDER_TYPE_FILLING filling);
    void           SetDeviationInPoints(ulong deviation);

    // Position Management
    bool           Buy(string symbol, double volume, double sl = 0, double tp = 0);
    bool           Sell(string symbol, double volume, double sl = 0, double tp = 0);
    bool           ClosePosition(ulong ticket);
    bool           CloseAllPositions(string symbol = "");
    bool           ModifyPosition(ulong ticket, double sl, double tp);

    // Pending Orders
    bool           BuyLimit(string symbol, double volume, double price, double sl = 0, double tp = 0);
    bool           SellLimit(string symbol, double volume, double price, double sl = 0, double tp = 0);
    bool           BuyStop(string symbol, double volume, double price, double sl = 0, double tp = 0);
    bool           SellStop(string symbol, double volume, double price, double sl = 0, double tp = 0);
    bool           DeleteOrder(ulong ticket);
    bool           DeleteAllOrders(string symbol = "");

    // Position Queries
    bool           HasPosition(string symbol);
    ulong          GetPositionTicket(string symbol);
    int            CountPositions(string symbol = "");
    int            CountOrders(string symbol = "");
    double         GetPositionProfit(string symbol);
    double         GetTotalProfit();

    // Utility Functions
    double         CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, int points);
    double         CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, int points);
    double         NormalizeLot(string symbol, double lot);
    double         NormalizePrice(string symbol, double price);

    // Getters
    ulong          GetMagicNumber() { return m_magicNumber; }
    CTrade*        GetTradeObject() { return &m_trade; }
    uint           GetResultRetcode() { return m_trade.ResultRetcode(); }
    string         GetResultComment() { return m_trade.ResultComment(); }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
    m_magicNumber = 0;
    m_comment = "";
    m_slippage = 10;
    m_maxRetries = 3;
    m_retryDelay = 100;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
bool CTradeManager::Init(ulong magicNumber, string comment = "")
{
    m_magicNumber = magicNumber;
    m_comment = comment;

    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetDeviationInPoints(m_slippage);
    m_trade.SetTypeFilling(ORDER_FILLING_FOK);
    m_trade.SetAsyncMode(false);
    m_trade.LogLevel(LOG_LEVEL_ERRORS);

    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize trade manager                                       |
//+------------------------------------------------------------------+
void CTradeManager::Deinit()
{
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Set slippage in points                                           |
//+------------------------------------------------------------------+
void CTradeManager::SetSlippage(int slippage)
{
    m_slippage = slippage;
    m_trade.SetDeviationInPoints(slippage);
}

//+------------------------------------------------------------------+
//| Set maximum retry attempts                                       |
//+------------------------------------------------------------------+
void CTradeManager::SetMaxRetries(int retries)
{
    m_maxRetries = MathMax(1, retries);
}

//+------------------------------------------------------------------+
//| Set order fill type                                              |
//+------------------------------------------------------------------+
void CTradeManager::SetFillType(ENUM_ORDER_TYPE_FILLING filling)
{
    m_trade.SetTypeFilling(filling);
}

//+------------------------------------------------------------------+
//| Set deviation in points                                          |
//+------------------------------------------------------------------+
void CTradeManager::SetDeviationInPoints(ulong deviation)
{
    m_trade.SetDeviationInPoints(deviation);
}

//+------------------------------------------------------------------+
//| Open BUY position                                                |
//+------------------------------------------------------------------+
bool CTradeManager::Buy(string symbol, double volume, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.Buy(volume, symbol, 0, sl, tp, m_comment);
    LogTradeResult("BUY");

    return result;
}

//+------------------------------------------------------------------+
//| Open SELL position                                               |
//+------------------------------------------------------------------+
bool CTradeManager::Sell(string symbol, double volume, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.Sell(volume, symbol, 0, sl, tp, m_comment);
    LogTradeResult("SELL");

    return result;
}

//+------------------------------------------------------------------+
//| Close position by ticket                                         |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return false;

    bool result = m_trade.PositionClose(ticket);
    LogTradeResult("CLOSE");

    return result;
}

//+------------------------------------------------------------------+
//| Close all positions for symbol                                   |
//+------------------------------------------------------------------+
bool CTradeManager::CloseAllPositions(string symbol = "")
{
    bool allClosed = true;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;

        string posSymbol = PositionGetString(POSITION_SYMBOL);
        if(symbol != "" && posSymbol != symbol) continue;

        if(!ClosePosition(ticket))
            allClosed = false;
    }

    return allClosed;
}

//+------------------------------------------------------------------+
//| Modify position SL/TP                                            |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double sl, double tp)
{
    if(!PositionSelectByTicket(ticket))
        return false;

    string symbol = PositionGetString(POSITION_SYMBOL);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.PositionModify(ticket, sl, tp);
    LogTradeResult("MODIFY");

    return result;
}

//+------------------------------------------------------------------+
//| Place BUY LIMIT order                                            |
//+------------------------------------------------------------------+
bool CTradeManager::BuyLimit(string symbol, double volume, double price, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    price = NormalizePrice(symbol, price);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.BuyLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, m_comment);
    LogTradeResult("BUY LIMIT");

    return result;
}

//+------------------------------------------------------------------+
//| Place SELL LIMIT order                                           |
//+------------------------------------------------------------------+
bool CTradeManager::SellLimit(string symbol, double volume, double price, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    price = NormalizePrice(symbol, price);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.SellLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, m_comment);
    LogTradeResult("SELL LIMIT");

    return result;
}

//+------------------------------------------------------------------+
//| Place BUY STOP order                                             |
//+------------------------------------------------------------------+
bool CTradeManager::BuyStop(string symbol, double volume, double price, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    price = NormalizePrice(symbol, price);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.BuyStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, m_comment);
    LogTradeResult("BUY STOP");

    return result;
}

//+------------------------------------------------------------------+
//| Place SELL STOP order                                            |
//+------------------------------------------------------------------+
bool CTradeManager::SellStop(string symbol, double volume, double price, double sl = 0, double tp = 0)
{
    volume = NormalizeLot(symbol, volume);
    price = NormalizePrice(symbol, price);
    sl = NormalizePrice(symbol, sl);
    tp = NormalizePrice(symbol, tp);

    bool result = m_trade.SellStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, m_comment);
    LogTradeResult("SELL STOP");

    return result;
}

//+------------------------------------------------------------------+
//| Delete pending order                                             |
//+------------------------------------------------------------------+
bool CTradeManager::DeleteOrder(ulong ticket)
{
    bool result = m_trade.OrderDelete(ticket);
    LogTradeResult("DELETE ORDER");

    return result;
}

//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
bool CTradeManager::DeleteAllOrders(string symbol = "")
{
    bool allDeleted = true;

    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if(ticket == 0) continue;

        if(OrderGetInteger(ORDER_MAGIC) != m_magicNumber) continue;

        string ordSymbol = OrderGetString(ORDER_SYMBOL);
        if(symbol != "" && ordSymbol != symbol) continue;

        if(!DeleteOrder(ticket))
            allDeleted = false;
    }

    return allDeleted;
}

//+------------------------------------------------------------------+
//| Check if position exists for symbol                              |
//+------------------------------------------------------------------+
bool CTradeManager::HasPosition(string symbol)
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
           PositionGetString(POSITION_SYMBOL) == symbol)
            return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Get position ticket for symbol                                   |
//+------------------------------------------------------------------+
ulong CTradeManager::GetPositionTicket(string symbol)
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
           PositionGetString(POSITION_SYMBOL) == symbol)
            return ticket;
    }

    return 0;
}

//+------------------------------------------------------------------+
//| Count positions                                                   |
//+------------------------------------------------------------------+
int CTradeManager::CountPositions(string symbol = "")
{
    int count = 0;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;

        if(symbol == "" || PositionGetString(POSITION_SYMBOL) == symbol)
            count++;
    }

    return count;
}

//+------------------------------------------------------------------+
//| Count pending orders                                              |
//+------------------------------------------------------------------+
int CTradeManager::CountOrders(string symbol = "")
{
    int count = 0;

    for(int i = 0; i < OrdersTotal(); i++)
    {
        ulong ticket = OrderGetTicket(i);
        if(ticket == 0) continue;

        if(OrderGetInteger(ORDER_MAGIC) != m_magicNumber) continue;

        if(symbol == "" || OrderGetString(ORDER_SYMBOL) == symbol)
            count++;
    }

    return count;
}

//+------------------------------------------------------------------+
//| Get position profit for symbol                                   |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionProfit(string symbol)
{
    double profit = 0;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
           PositionGetString(POSITION_SYMBOL) == symbol)
        {
            profit += PositionGetDouble(POSITION_PROFIT);
        }
    }

    return profit;
}

//+------------------------------------------------------------------+
//| Get total profit across all positions                            |
//+------------------------------------------------------------------+
double CTradeManager::GetTotalProfit()
{
    double profit = 0;

    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        if(!PositionSelectByTicket(ticket)) continue;

        if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
            profit += PositionGetDouble(POSITION_PROFIT);
        }
    }

    return profit;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss price                                        |
//+------------------------------------------------------------------+
double CTradeManager::CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, int points)
{
    if(points <= 0)
        return 0;

    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double price = 0;

    if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
    {
        price = SymbolInfoDouble(symbol, SYMBOL_BID) - points * point;
    }
    else if(orderType == ORDER_TYPE_SELL || orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
    {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK) + points * point;
    }

    return NormalizePrice(symbol, price);
}

//+------------------------------------------------------------------+
//| Calculate Take Profit price                                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, int points)
{
    if(points <= 0)
        return 0;

    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double price = 0;

    if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
    {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK) + points * point;
    }
    else if(orderType == ORDER_TYPE_SELL || orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
    {
        price = SymbolInfoDouble(symbol, SYMBOL_BID) - points * point;
    }

    return NormalizePrice(symbol, price);
}

//+------------------------------------------------------------------+
//| Normalize lot size according to symbol specifications            |
//+------------------------------------------------------------------+
double CTradeManager::NormalizeLot(string symbol, double lot)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if(lotStep == 0)
        lotStep = 0.01;

    lot = MathFloor(lot / lotStep) * lotStep;
    lot = MathMax(minLot, MathMin(maxLot, lot));

    return NormalDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Normalize price according to symbol specifications               |
//+------------------------------------------------------------------+
double CTradeManager::NormalizePrice(string symbol, double price)
{
    if(price == 0)
        return 0;

    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tickSize == 0)
        tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);

    return MathRound(price / tickSize) * tickSize;
}

//+------------------------------------------------------------------+
//| Log trade result                                                  |
//+------------------------------------------------------------------+
void CTradeManager::LogTradeResult(string operation)
{
    if(m_trade.ResultRetcode() != TRADE_RETCODE_DONE)
    {
        Print("Trade operation ", operation, " failed: ",
              "RetCode=", m_trade.ResultRetcode(),
              " Comment=", m_trade.ResultComment());
    }
}
//+------------------------------------------------------------------+
