//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                  Copyright 2025, Bolt Performance|
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Bolt Performance"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Class for high-performance symbol data access                    |
//| Optimized to avoid slow SymbolInfoDouble/Integer calls in loops  |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;
   double            m_point;
   double            m_tick_value;
   double            m_tick_size;
   double            m_contract_size;
   double            m_ask;
   double            m_bid;
   double            m_spread;
   long              m_digits;

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initialize cache with symbol properties (call in OnInit)
   bool              Init(string symbol);

   // Update dynamic data (Ask, Bid, Spread) from tick (call in OnTick)
   void              Update(const MqlTick &tick);

   // Update TickValue specifically (for cross-currency pairs where it changes)
   bool              UpdateTickValue(void);

   // Fast accessors - inline for performance
   double            Point(void) const { return m_point; }
   double            TickValue(void) const { return m_tick_value; }
   double            TickSize(void) const { return m_tick_size; }
   double            ContractSize(void) const { return m_contract_size; }
   double            Ask(void) const { return m_ask; }
   double            Bid(void) const { return m_bid; }
   double            Spread(void) const { return m_spread; }
   long              Digits(void) const { return m_digits; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void)
   : m_symbol(NULL),
     m_point(0.0),
     m_tick_value(0.0),
     m_tick_size(0.0),
     m_contract_size(0.0),
     m_ask(0.0),
     m_bid(0.0),
     m_spread(0.0),
     m_digits(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialize cache with symbol properties                          |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;

   if(!SymbolInfoDouble(m_symbol, SYMBOL_POINT, m_point)) return false;
   if(!SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE, m_tick_value)) return false;
   if(!SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE, m_tick_size)) return false;
   if(!SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE, m_contract_size)) return false;
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, m_digits)) return false;

   return true;
  }
//+------------------------------------------------------------------+
//| Update dynamic data from tick                                    |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask = tick.ask;
   m_bid = tick.bid;

   // OPTIMIZATION: Manual spread calculation is significantly faster
   // than calling SymbolInfoInteger(m_symbol, SYMBOL_SPREAD)
   if(m_point > 0)
      m_spread = (m_ask - m_bid) / m_point;
   else
      m_spread = 0;
  }
//+------------------------------------------------------------------+
//| Update TickValue specifically                                    |
//+------------------------------------------------------------------+
bool CSymbolCache::UpdateTickValue(void)
  {
   return SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE, m_tick_value);
  }
//+------------------------------------------------------------------+
