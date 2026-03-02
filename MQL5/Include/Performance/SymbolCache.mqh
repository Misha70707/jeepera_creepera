//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                   tweny_fo_seven_trees_ixty_five |
//|                                        Apache License 2.0        |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      ""

//+------------------------------------------------------------------+
//| CSymbolCache: Performance utility to reduce SymbolInfo calls     |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;
   double            m_point;
   long              m_digits; // Must be long for SymbolInfoInteger
   double            m_ask;
   double            m_bid;

public:
                     CSymbolCache();
                    ~CSymbolCache();

   // Initialize static properties
   bool              Init(string symbol);

   // Update dynamic properties via MqlTick
   void              Update(const MqlTick &tick);

   // Getters for static properties
   string            Symbol() const { return m_symbol; }
   double            Point() const { return m_point; }
   long              Digits() const { return m_digits; }

   // Getters for dynamic properties
   double            Ask() const { return m_ask; }
   double            Bid() const { return m_bid; }

   // Note: TickValue is deliberately NOT cached here.
   // Caching TickValue in long-lived classes for cross-currency
   // pairs is a performance anti-pattern as it changes dynamically
   // with conversion rates. Retrieve it fresh.
   double            TickValue() const { return SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE); }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache() : m_symbol(""), m_point(0.0), m_digits(0), m_ask(0.0), m_bid(0.0)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache()
  {
  }

//+------------------------------------------------------------------+
//| Initialize static symbol properties                              |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;

   // Cache static properties
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // Use long to avoid compilation error due to reference type mismatch
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, m_digits))
     {
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Update dynamic properties from tick data                         |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   // Fast update of price data without SymbolInfoDouble overhead
   m_ask = tick.ask;
   m_bid = tick.bid;
  }
