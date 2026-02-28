//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                  tweny_fo_seven_trees_ixty_five  |
//|                                            Apache License 2.0    |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      "https://github.com/tweny_fo_seven_trees_ixty_five"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Class CSymbolCache                                               |
//| Purpose: High-performance caching of symbol properties to avoid  |
//|          costly MT5 API calls (SymbolInfoDouble/Integer) in      |
//|          the critical OnTick execution path.                     |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;

   // Static properties (cached once)
   double            m_point;
   long              m_digits; // Must be long for SymbolInfoInteger
   long              m_spread;
   long              m_trade_mode;

   // Dynamic properties (updated via tick)
   double            m_ask;
   double            m_bid;
   double            m_last;
   long              m_volume;
   datetime          m_time;

   bool              m_initialized;

public:
                     CSymbolCache();
                    ~CSymbolCache();

   // Initialize the cache with static properties
   bool              Init(const string symbol_name);

   // Fast update of dynamic properties using a single MqlTick struct
   // Significantly faster than multiple SymbolInfoDouble() calls
   void              Update(const MqlTick &tick);

   // --- Fast Accessors ---
   string            Name()   const { return m_symbol; }

   // Static getters
   double            Point()  const { return m_point; }
   long              Digits() const { return m_digits; }
   long              Spread() const { return m_spread; }
   long              TradeMode() const { return m_trade_mode; }

   // Dynamic getters
   double            Ask()    const { return m_ask; }
   double            Bid()    const { return m_bid; }
   double            Last()   const { return m_last; }
   long              Volume() const { return m_volume; }
   datetime          Time()   const { return m_time; }

   bool              IsInitialized() const { return m_initialized; }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache() :
   m_symbol(""),
   m_point(0),
   m_digits(0),
   m_spread(0),
   m_trade_mode(0),
   m_ask(0),
   m_bid(0),
   m_last(0),
   m_volume(0),
   m_time(0),
   m_initialized(false)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache()
  {
  }

//+------------------------------------------------------------------+
//| Initialize the cache with static properties                      |
//| Returns true if successful, false otherwise                      |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(const string symbol_name)
  {
   if(symbol_name == "") return false;

   m_symbol = symbol_name;

   // Cache static properties
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // IMPORTANT: SymbolInfoInteger requires a long reference
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, m_digits))
     {
      PrintFormat("CSymbolCache::Init failed to get SYMBOL_DIGITS for %s", m_symbol);
      return false;
     }

   SymbolInfoInteger(m_symbol, SYMBOL_SPREAD, m_spread);
   SymbolInfoInteger(m_symbol, SYMBOL_TRADE_MODE, m_trade_mode);

   m_initialized = true;
   return true;
  }

//+------------------------------------------------------------------+
//| Update dynamic properties from a tick                            |
//| Performance note: This avoids multiple SymbolInfoDouble calls    |
//| by utilizing a single pre-fetched tick struct.                   |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   if(!m_initialized) return;

   m_ask    = tick.ask;
   m_bid    = tick.bid;
   m_last   = tick.last;
   m_volume = (long)tick.volume;
   m_time   = tick.time;
  }
//+------------------------------------------------------------------+
