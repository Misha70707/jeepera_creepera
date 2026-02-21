//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                       Advanced Risk Management and Position Sizing |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| CRiskManager Class                                               |
//| Handles position sizing, risk calculations, and risk limits     |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    double         m_riskPercent;          // Risk per trade as % of balance
    double         m_maxLot;               // Maximum lot size allowed
    double         m_minLot;               // Minimum lot size allowed
    double         m_maxDailyLoss;         // Max daily loss in %
    double         m_maxDrawdown;          // Max drawdown in %
    double         m_dailyStartBalance;    // Balance at start of day
    datetime       m_lastDayCheck;         // Last day checked

    bool           m_useFixedLot;          // Use fixed lot instead of % risk
    double         m_fixedLot;             // Fixed lot size

    double         GetAccountBalance();
    double         GetAccountEquity();
    bool           CheckDailyReset();

public:
                   CRiskManager();
                  ~CRiskManager();

    // Configuration
    void           SetRiskPercent(double percent);
    void           SetMaxLot(double lot);
    void           SetMinLot(double lot);
    void           SetMaxDailyLoss(double percent);
    void           SetMaxDrawdown(double percent);
    void           SetFixedLot(double lot);
    void           UseFixedLot(bool use);

    // Position Sizing
    double         CalculateLotSize(string symbol, int stopLossPoints);
    double         CalculateLotSizeByRisk(string symbol, double riskAmount, int stopLossPoints);
    double         CalculateKellyLot(string symbol, double winRate, double avgWin, double avgLoss);
    double         CalculateOptimalF(string symbol, double largestLoss);

    // Risk Checks
    bool           IsTradeAllowed();
    bool           IsDailyLossExceeded();
    bool           IsDrawdownExceeded();
    bool           IsLotSizeValid(string symbol, double lot);
    double         GetCurrentDailyPnL();
    double         GetCurrentDrawdown();

    // Risk Metrics
    double         CalculateRiskRewardRatio(double entryPrice, double sl, double tp, ENUM_POSITION_TYPE type);
    double         CalculatePositionRisk(string symbol, double lot, int stopLossPoints);
    double         CalculateMaxPositionSize(string symbol);
    int            GetMaxPositionsAllowed();

    // Getters
    double         GetRiskPercent() { return m_riskPercent; }
    double         GetMaxLot() { return m_maxLot; }
    double         GetMinLot() { return m_minLot; }
    double         GetDailyStartBalance() { return m_dailyStartBalance; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
    m_riskPercent = 1.0;
    m_maxLot = 100.0;
    m_minLot = 0.01;
    m_maxDailyLoss = 5.0;
    m_maxDrawdown = 20.0;
    m_dailyStartBalance = GetAccountBalance();
    m_lastDayCheck = TimeCurrent();
    m_useFixedLot = false;
    m_fixedLot = 0.01;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
}

//+------------------------------------------------------------------+
//| Set risk per trade in percent                                    |
//+------------------------------------------------------------------+
void CRiskManager::SetRiskPercent(double percent)
{
    m_riskPercent = MathMax(0.1, MathMin(percent, 10.0)); // Limit 0.1% to 10%
}

//+------------------------------------------------------------------+
//| Set maximum lot size                                             |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxLot(double lot)
{
    m_maxLot = MathMax(0.01, lot);
}

//+------------------------------------------------------------------+
//| Set minimum lot size                                             |
//+------------------------------------------------------------------+
void CRiskManager::SetMinLot(double lot)
{
    m_minLot = MathMax(0.01, lot);
}

//+------------------------------------------------------------------+
//| Set maximum daily loss in percent                                |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxDailyLoss(double percent)
{
    m_maxDailyLoss = MathMax(0, MathMin(percent, 50.0)); // Limit to 50%
}

//+------------------------------------------------------------------+
//| Set maximum drawdown in percent                                  |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxDrawdown(double percent)
{
    m_maxDrawdown = MathMax(0, MathMin(percent, 50.0)); // Limit to 50%
}

//+------------------------------------------------------------------+
//| Set fixed lot size                                               |
//+------------------------------------------------------------------+
void CRiskManager::SetFixedLot(double lot)
{
    m_fixedLot = lot;
}

//+------------------------------------------------------------------+
//| Enable/disable fixed lot mode                                    |
//+------------------------------------------------------------------+
void CRiskManager::UseFixedLot(bool use)
{
    m_useFixedLot = use;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(string symbol, int stopLossPoints)
{
    // If using fixed lot, return it
    if(m_useFixedLot)
        return m_fixedLot;

    // Calculate risk amount in account currency
    double balance = GetAccountBalance();
    double riskAmount = balance * m_riskPercent / 100.0;

    return CalculateLotSizeByRisk(symbol, riskAmount, stopLossPoints);
}

//+------------------------------------------------------------------+
//| Calculate lot size for specific risk amount                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSizeByRisk(string symbol, double riskAmount, int stopLossPoints)
{
    if(stopLossPoints <= 0)
    {
        Print("ERROR: Invalid stop loss points");
        return 0;
    }

    // Get symbol properties
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

    if(tickValue == 0 || point == 0)
    {
        Print("ERROR: Invalid symbol properties");
        return 0;
    }

    // Calculate lot size
    double lotSize = riskAmount / (stopLossPoints * point / tickSize * tickValue);

    // Normalize lot size
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if(lotStep == 0)
        lotStep = 0.01;

    lotSize = MathFloor(lotSize / lotStep) * lotStep;

    // Apply configured limits
    lotSize = MathMax(m_minLot, MathMin(m_maxLot, lotSize));

    // Apply broker limits
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

    return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Calculate Kelly Criterion lot size                               |
//| W = Win rate (0-1), R = Avg win / Avg loss                      |
//| Kelly% = W - (1-W)/R                                             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateKellyLot(string symbol, double winRate, double avgWin, double avgLoss)
{
    if(avgLoss == 0 || winRate <= 0 || winRate >= 1)
        return m_minLot;

    double winLossRatio = avgWin / avgLoss;
    double kellyPercent = winRate - ((1 - winRate) / winLossRatio);

    // Use fractional Kelly (e.g., 0.25 Kelly) for safety
    kellyPercent = kellyPercent * 0.25;

    if(kellyPercent <= 0)
        return m_minLot;

    // Calculate lot based on Kelly percentage
    double balance = GetAccountBalance();
    double riskAmount = balance * kellyPercent;

    // Assume reasonable stop loss for calculation
    int stopLoss = 100; // points

    return CalculateLotSizeByRisk(symbol, riskAmount, stopLoss);
}

//+------------------------------------------------------------------+
//| Calculate Optimal F lot size                                     |
//| Optimal F = largest loss / largest loss                          |
//+------------------------------------------------------------------+
double CRiskManager::CalculateOptimalF(string symbol, double largestLoss)
{
    if(largestLoss == 0)
        return m_minLot;

    double balance = GetAccountBalance();
    double optimalF = balance / largestLoss;

    // Use conservative fraction
    optimalF = optimalF * 0.5;

    return MathMax(m_minLot, MathMin(m_maxLot, optimalF));
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on risk rules                  |
//+------------------------------------------------------------------+
bool CRiskManager::IsTradeAllowed()
{
    CheckDailyReset();

    if(IsDailyLossExceeded())
    {
        Print("WARNING: Daily loss limit exceeded. Trading disabled.");
        return false;
    }

    if(IsDrawdownExceeded())
    {
        Print("WARNING: Maximum drawdown exceeded. Trading disabled.");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Check if daily loss limit exceeded                               |
//+------------------------------------------------------------------+
bool CRiskManager::IsDailyLossExceeded()
{
    if(m_maxDailyLoss == 0)
        return false;

    double dailyPnL = GetCurrentDailyPnL();
    double lossPercent = (dailyPnL / m_dailyStartBalance) * 100.0;

    return (lossPercent < -m_maxDailyLoss);
}

//+------------------------------------------------------------------+
//| Check if maximum drawdown exceeded                               |
//+------------------------------------------------------------------+
bool CRiskManager::IsDrawdownExceeded()
{
    if(m_maxDrawdown == 0)
        return false;

    double drawdown = GetCurrentDrawdown();

    return (drawdown > m_maxDrawdown);
}

//+------------------------------------------------------------------+
//| Validate lot size                                                |
//+------------------------------------------------------------------+
bool CRiskManager::IsLotSizeValid(string symbol, double lot)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

    if(lot < minLot || lot > maxLot)
        return false;

    if(lot < m_minLot || lot > m_maxLot)
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Get current daily profit/loss                                    |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDailyPnL()
{
    CheckDailyReset();

    double currentBalance = GetAccountBalance();
    return currentBalance - m_dailyStartBalance;
}

//+------------------------------------------------------------------+
//| Get current drawdown percentage                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdown()
{
    double balance = GetAccountBalance();
    double equity = GetAccountEquity();

    if(balance == 0)
        return 0;

    double drawdown = ((balance - equity) / balance) * 100.0;

    return MathMax(0, drawdown);
}

//+------------------------------------------------------------------+
//| Calculate risk/reward ratio                                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskRewardRatio(double entryPrice, double sl, double tp, ENUM_POSITION_TYPE type)
{
    if(sl == 0 || tp == 0)
        return 0;

    double risk = 0;
    double reward = 0;

    if(type == POSITION_TYPE_BUY)
    {
        risk = entryPrice - sl;
        reward = tp - entryPrice;
    }
    else if(type == POSITION_TYPE_SELL)
    {
        risk = sl - entryPrice;
        reward = entryPrice - tp;
    }

    if(risk == 0)
        return 0;

    return reward / risk;
}

//+------------------------------------------------------------------+
//| Calculate position risk in account currency                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionRisk(string symbol, double lot, int stopLossPoints)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

    if(tickValue == 0 || point == 0 || tickSize == 0)
        return 0;

    double riskAmount = lot * (stopLossPoints * point / tickSize * tickValue);

    return riskAmount;
}

//+------------------------------------------------------------------+
//| Calculate maximum position size based on margin                  |
//+------------------------------------------------------------------+
double CRiskManager::CalculateMaxPositionSize(string symbol)
{
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double marginRequired = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL);

    if(marginRequired == 0)
        return 0;

    double maxLot = freeMargin / marginRequired;

    // Apply safety margin (use only 80% of available margin)
    maxLot = maxLot * 0.8;

    return MathMin(maxLot, m_maxLot);
}

//+------------------------------------------------------------------+
//| Get maximum number of positions allowed                          |
//+------------------------------------------------------------------+
int CRiskManager::GetMaxPositionsAllowed()
{
    // Conservative approach: limit based on risk
    // If risking 1% per trade, max 10 positions = 10% total risk
    int maxPositions = (int)(10.0 / m_riskPercent);

    return MathMax(1, MathMin(maxPositions, 20)); // Cap at 20
}

//+------------------------------------------------------------------+
//| Get account balance                                              |
//+------------------------------------------------------------------+
double CRiskManager::GetAccountBalance()
{
    return AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Get account equity                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetAccountEquity()
{
    return AccountInfoDouble(ACCOUNT_EQUITY);
}

//+------------------------------------------------------------------+
//| Check and reset daily counters                                   |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDailyReset()
{
    MqlDateTime currentTime, lastTime;
    TimeToStruct(TimeCurrent(), currentTime);
    TimeToStruct(m_lastDayCheck, lastTime);

    // Check if new day
    if(currentTime.day != lastTime.day)
    {
        m_dailyStartBalance = GetAccountBalance();
        m_lastDayCheck = TimeCurrent();
        Print("Daily reset: New balance = ", m_dailyStartBalance);
        return true;
    }

    return false;
}
//+------------------------------------------------------------------+
