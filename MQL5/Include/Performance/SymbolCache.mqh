//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                   tweny_fo_seven_trees_ixty_five |
//|                                             Apache License 2.0   |
//+------------------------------------------------------------------+
#property copyright "tweny_fo_seven_trees_ixty_five"
#property link      "https://github.com/tweny_fo_seven_trees_ixty_five"
#property strict

//+------------------------------------------------------------------+
//| CSymbolCache Class                                               |
//| High-performance cache for Symbol properties to avoid overhead   |
//| of frequent SymbolInfoDouble/Integer calls in OnTick.            |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;       // Trading symbol
   double            m_point;        // Symbol Point value
   long              m_digits;       // Symbol Digits (MUST be long for SymbolInfoInteger)

   // Dynamic values
   double            m_ask;          // Current Ask price
   double            m_bid;          // Current Bid price
   long              m_volume;       // Current Volume
   long              m_time;         // Time of last tick

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initializes the cache with a symbol. Retrieves static properties.
   bool              Init(const string symbol);

   // Updates dynamic properties from an MqlTick struct
   void              Update(const MqlTick &tick);

   // Getters for static properties
   string            Symbol(void) const { return m_symbol; }
   double            Point(void) const  { return m_point; }
   long              Digits(void) const { return m_digits; }

   // Getters for dynamic properties
   double            Ask(void) const    { return m_ask; }
   double            Bid(void) const    { return m_bid; }
   long              Volume(void) const { return m_volume; }
   long              Time(void) const   { return m_time; }

   // DO NOT CACHE TickValue cross-currency statically. Fetch when needed.
   double            TickValue(void) const { return SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE); }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void) : m_symbol(""),
                                   m_point(0.0),
                                   m_digits(0),
                                   m_ask(0.0),
                                   m_bid(0.0),
                                   m_volume(0),
                                   m_time(0)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache(void)
  {
  }

//+------------------------------------------------------------------+
//| Init                                                             |
//| Retrieves and caches static symbol properties (Point, Digits).   |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(const string symbol)
  {
   m_symbol = symbol;

   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // CRITICAL: SymbolInfoInteger requires a long variable as the receiving parameter!
   // Passing an int will result in a compilation error due to strict reference type mismatch.
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, m_digits))
     {
      Print("Failed to get SYMBOL_DIGITS for ", m_symbol, " Error: ", GetLastError());
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Update                                                           |
//| Efficiently updates dynamic properties from an MqlTick struct    |
//| without the overhead of SymbolInfoDouble calls.                  |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask    = tick.ask;
   m_bid    = tick.bid;
   m_volume = tick.volume;
   m_time   = tick.time;
  }
//+------------------------------------------------------------------+
