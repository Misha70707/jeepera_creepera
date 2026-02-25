//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                     Copyright 2024, Bolt Agency. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Bolt Agency."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| Class for caching symbol information to improve performance      |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;
   double            m_point;
   long              m_digits;
   double            m_ask;
   double            m_bid;
   double            m_spread;

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initialize cache with symbol name
   bool              Init(string symbol);

   // Update market data from tick
   void              Update(const MqlTick &tick);

   // Getters for cached values (inlined for performance)
   double            Ask(void) const { return m_ask; }
   double            Bid(void) const { return m_bid; }
   double            Spread(void) const { return m_spread; }
   double            Point(void) const { return m_point; }
   long              Digits(void) const { return m_digits; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void)
   : m_symbol(NULL),
     m_point(0.0),
     m_digits(0),
     m_ask(0.0),
     m_bid(0.0),
     m_spread(0.0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialize cache                                                 |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;

   // Cache static properties once
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   m_digits = SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   if(m_point == 0.0)
      return false;

   return true;
  }
//+------------------------------------------------------------------+
//| Update market data from tick                                     |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask = tick.ask;
   m_bid = tick.bid;

   // Calculate spread manually to avoid SymbolInfoInteger call
   // Spread is in points
   if(m_point > 0)
      m_spread = (m_ask - m_bid) / m_point;
   else
      m_spread = 0.0;
  }
//+------------------------------------------------------------------+
