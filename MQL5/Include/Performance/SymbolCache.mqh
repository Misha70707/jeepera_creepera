//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Class CSymbolCache                                               |
//| Purpose: Cache symbol properties and tick data to avoid expensive|
//| API calls like SymbolInfoInteger during high-frequency checks.   |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;
   double            m_point;
   double            m_ask;
   double            m_bid;
   long              m_spread;
   bool              m_initialized;

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initialize cache for a symbol (call in OnInit)
   bool              Init(string symbol);

   // Update cached values from tick (call in OnTick)
   void              Update(const MqlTick &tick);

   // Get cached spread (Points) - 0(1) access vs SymbolInfoInteger overhead
   long              GetSpread(void) const { return m_spread; }

   // Get cached Point - 0(1) access
   double            GetPoint(void) const { return m_point; }

   // Get cached Ask price
   double            GetAsk(void) const { return m_ask; }

   // Get cached Bid price
   double            GetBid(void) const { return m_bid; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void) : m_point(0.0), m_ask(0.0), m_bid(0.0), m_spread(0), m_initialized(false)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialize cache for a symbol                                    |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;
   // Cache SymbolInfoDouble(..., SYMBOL_POINT) as it doesn't change
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   if(m_point == 0.0)
      return(false);

   m_initialized = true;
   return(true);
  }
//+------------------------------------------------------------------+
//| Update cached values from tick                                   |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   if(!m_initialized) return;

   m_ask = tick.ask;
   m_bid = tick.bid;

   // Manual calculation avoids SymbolInfoInteger overhead
   // Spread = (Ask - Bid) / Point
   if(m_point > 0)
      m_spread = (long)((m_ask - m_bid) / m_point + 0.5); // +0.5 for rounding
   else
      m_spread = 0;
  }
//+------------------------------------------------------------------+
