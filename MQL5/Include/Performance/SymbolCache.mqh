//+------------------------------------------------------------------+
//|                                                  SymbolCache.mqh |
//|                                                             Bolt |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Bolt"
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| CSymbolCache - High performance symbol property caching          |
//| Replaces frequent API calls with fast memory access              |
//+------------------------------------------------------------------+
class CSymbolCache
  {
private:
   string            m_symbol;

   // Static properties (cached once)
   double            m_point;
   int               m_digits;
   double            m_volumeStep;
   double            m_volumeMin;
   double            m_volumeMax;
   double            m_contractSize;

   // Dynamic properties (updated per tick)
   double            m_ask;
   double            m_bid;
   double            m_last;
   datetime          m_time;
   long              m_timeMsc;

   bool              m_initialized;

public:
                     CSymbolCache(void);
                    ~CSymbolCache(void);

   // Initialize with symbol name - caches static properties
   bool              Init(string symbol);

   // Update dynamic properties from API (slower)
   bool              Refresh(void);

   // Update dynamic properties from existing tick (fastest)
   void              Update(const MqlTick &tick);

   // Fast accessors - inlined for performance
   double            Ask(void) const { return m_ask; }
   double            Bid(void) const { return m_bid; }
   double            Last(void) const { return m_last; }
   double            Spread(void) const { return (m_ask - m_bid); }
   double            SpreadPoints(void) const { return (m_ask - m_bid) / m_point; }

   datetime          Time(void) const { return m_time; }
   long              TimeMsc(void) const { return m_timeMsc; }

   double            Point(void) const { return m_point; }
   int               Digits(void) const { return m_digits; }
   double            VolumeStep(void) const { return m_volumeStep; }
   double            VolumeMin(void) const { return m_volumeMin; }
   double            VolumeMax(void) const { return m_volumeMax; }
   double            ContractSize(void) const { return m_contractSize; }

   string            Name(void) const { return m_symbol; }
   bool              IsInitialized(void) const { return m_initialized; }

   // Helper calculations using cached data
   double            NormalizePrice(double price) const;
   double            NormalizeVolume(double volume) const;
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolCache::CSymbolCache(void) :
   m_symbol(""),
   m_point(0.0),
   m_digits(0),
   m_initialized(false)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolCache::~CSymbolCache(void)
  {
  }
//+------------------------------------------------------------------+
//| Initialize and cache static properties                           |
//+------------------------------------------------------------------+
bool CSymbolCache::Init(string symbol)
  {
   m_symbol = symbol;

   if(!SymbolInfoDouble(m_symbol, SYMBOL_POINT, m_point)) return false;

   long digits = 0;
   if(!SymbolInfoInteger(m_symbol, SYMBOL_DIGITS, digits)) return false;
   m_digits = (int)digits;

   m_volumeStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   m_volumeMin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   m_volumeMax = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   m_contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   m_initialized = true;
   return true;
  }
//+------------------------------------------------------------------+
//| Update dynamic data from API                                     |
//+------------------------------------------------------------------+
bool CSymbolCache::Refresh(void)
  {
   MqlTick tick;
   if(!SymbolInfoTick(m_symbol, tick))
      return false;

   Update(tick);
   return true;
  }
//+------------------------------------------------------------------+
//| Update dynamic data from Tick (Zero API calls)                   |
//+------------------------------------------------------------------+
void CSymbolCache::Update(const MqlTick &tick)
  {
   m_ask = tick.ask;
   m_bid = tick.bid;
   m_last = tick.last;
   m_time = tick.time;
   m_timeMsc = tick.time_msc;
  }
//+------------------------------------------------------------------+
//| Normalize price to symbol digits                                 |
//+------------------------------------------------------------------+
double CSymbolCache::NormalizePrice(double price) const
  {
   return NormalizeDouble(price, m_digits);
  }
//+------------------------------------------------------------------+
//| Normalize volume to symbol volume step                           |
//+------------------------------------------------------------------+
double CSymbolCache::NormalizeVolume(double volume) const
  {
   if(m_volumeStep <= 0) return volume;

   double steps = volume / m_volumeStep;
   // Add epsilon for floating point stability
   steps = MathFloor(steps + 0.0000001);
   double vol = steps * m_volumeStep;

   if(vol < m_volumeMin) vol = m_volumeMin;
   if(vol > m_volumeMax) vol = m_volumeMax;

   return vol;
  }
//+------------------------------------------------------------------+
