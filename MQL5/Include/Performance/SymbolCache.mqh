//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Class for caching symbol properties for performance optimization |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;
   double            m_point;
   int               m_digits;
   double            m_tick_size;
   double            m_contract_size;
   double            m_ask;
   double            m_bid;
   int               m_spread;
   bool              m_initialized;

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initialize with symbol
   bool              Init(string symbol);

   // Update market data from tick
   void              Update(const MqlTick &tick);

   // Fast accessors
   double            Ask() const { return m_ask; }
   double            Bid() const { return m_bid; }
   int               Spread() const { return m_spread; }
   double            Point() const { return m_point; }
   int               Digits() const { return m_digits; }
   double            TickSize() const { return m_tick_size; }
   double            ContractSize() const { return m_contract_size; }
   string            Symbol() const { return m_symbol; }
   bool              IsInitialized() const { return m_initialized; }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void) : m_initialized(false),
                                   m_point(0.0),
                                   m_digits(0),
                                   m_tick_size(0.0),
                                   m_contract_size(0.0),
                                   m_ask(0.0),
                                   m_bid(0.0),
                                   m_spread(0)
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

   if(!SymbolInfoDouble(m_symbol, SYMBOL_POINT, m_point))
      return false;

   long digits;
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, digits))
      return false;
   m_digits = (int)digits;

   if(!SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE, m_tick_size))
      return false;

   if(!SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE, m_contract_size))
      return false;

   m_initialized = true;
   return true;
  }
//+------------------------------------------------------------------+
//| Update dynamic properties from tick data                         |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask = tick.ask;
   m_bid = tick.bid;

   // Calculate spread efficiently without API call
   // Spread is usually in points
   if(m_point > 0)
      m_spread = (int)((m_ask - m_bid) / m_point + 0.5);
   else
      m_spread = 0;
  }
//+------------------------------------------------------------------+
