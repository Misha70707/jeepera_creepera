//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                   Copyright 2025, Top Secret     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Top Secret"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| CSymbolCache: High-performance symbol property access            |
//| Caches static properties in Init() and updates dynamic properties|
//| via Update(MqlTick&) to avoid SymbolInfoDouble overhead.         |
//| NOTE: Intentionally avoids caching TickValue as it changes       |
//|       dynamically for cross-currency pairs.                      |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;       // Symbol name

   // Static properties cached during initialization
   double            m_point;        // Point size
   int               m_digits;       // Number of digits
   long              m_spread;       // Spread (can be dynamic, but often cached if fixed)
   double            m_contract_size;// Contract size

   // Dynamic properties updated via MqlTick
   double            m_ask;          // Ask price
   double            m_bid;          // Bid price
   long              m_time;         // Last tick time

public:
                     CSymbolCache();
                    ~CSymbolCache();

   // Initializes the cache with static properties for a symbol
   bool              Init(string symbol);

   // Updates dynamic properties from a tick
   void              Update(const MqlTick &tick);

   // Getters for static properties
   string            Symbol(void) const { return m_symbol; }
   double            Point(void) const { return m_point; }
   int               Digits(void) const { return m_digits; }
   long              Spread(void) const { return m_spread; }
   double            ContractSize(void) const { return m_contract_size; }

   // Getters for dynamic properties
   double            Ask(void) const { return m_ask; }
   double            Bid(void) const { return m_bid; }
   long              Time(void) const { return m_time; }

   // NOTE: TickValue is intentionally NOT cached here because it
   // changes dynamically with conversion rates. Retrieve it fresh
   // when needed using SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE).
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache() : m_symbol(""), m_point(0), m_digits(0), m_spread(0), m_contract_size(0), m_ask(0), m_bid(0), m_time(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache()
  {
  }
//+------------------------------------------------------------------+
//| Initialize static properties                                     |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;

   // Cache static properties
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // Note: SymbolInfoInteger requires a long variable as receiving parameter.
   // Using int will cause a compilation error due to reference type mismatch.
   long digits_val;
   if(SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, digits_val))
      m_digits = (int)digits_val;
   else
      m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   SymbolInfoInteger(m_symbol, SYMBOL_SPREAD, m_spread);
   m_contract_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   return true;
  }
//+------------------------------------------------------------------+
//| Update dynamic properties from tick                              |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask = tick.ask;
   m_bid = tick.bid;
   m_time = tick.time;
  }
//+------------------------------------------------------------------+
