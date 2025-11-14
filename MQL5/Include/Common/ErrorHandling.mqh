//+------------------------------------------------------------------+
//|                                               ErrorHandling.mqh |
//|                       Comprehensive Error Handling Utilities     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://github.com/yourrepo"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| CErrorHandler Class                                              |
//| Centralized error handling and logging                           |
//+------------------------------------------------------------------+
class CErrorHandler
{
private:
    int            m_lastError;
    string         m_lastErrorText;
    int            m_errorCount;
    datetime       m_lastErrorTime;

    string         ErrorCodeToString(int errorCode);

public:
                   CErrorHandler();
                  ~CErrorHandler();

    // Error Retrieval
    int            GetLastError();
    string         GetLastErrorText();
    void           ResetLastError();

    // Error Logging
    void           LogError(string location, string message = "");
    void           LogWarning(string location, string message);
    void           LogInfo(string location, string message);

    // Error Classification
    bool           IsRetriableError(int errorCode);
    bool           IsCriticalError(int errorCode);
    bool           IsConnectionError(int errorCode);

    // Error Statistics
    int            GetErrorCount() { return m_errorCount; }
    datetime       GetLastErrorTime() { return m_lastErrorTime; }

    // Deinit Reason
    string         GetDeinitReasonText(int reason);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CErrorHandler::CErrorHandler()
{
    m_lastError = 0;
    m_lastErrorText = "";
    m_errorCount = 0;
    m_lastErrorTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CErrorHandler::~CErrorHandler()
{
}

//+------------------------------------------------------------------+
//| Get last error code                                              |
//+------------------------------------------------------------------+
int CErrorHandler::GetLastError()
{
    m_lastError = ::GetLastError();
    if(m_lastError != 0)
    {
        m_lastErrorText = ErrorCodeToString(m_lastError);
        m_errorCount++;
        m_lastErrorTime = TimeCurrent();
    }
    return m_lastError;
}

//+------------------------------------------------------------------+
//| Get last error text                                              |
//+------------------------------------------------------------------+
string CErrorHandler::GetLastErrorText()
{
    if(m_lastErrorText == "")
    {
        GetLastError();
    }
    return m_lastErrorText;
}

//+------------------------------------------------------------------+
//| Reset last error                                                 |
//+------------------------------------------------------------------+
void CErrorHandler::ResetLastError()
{
    ResetLastError();
    m_lastError = 0;
    m_lastErrorText = "";
}

//+------------------------------------------------------------------+
//| Log error with location                                          |
//+------------------------------------------------------------------+
void CErrorHandler::LogError(string location, string message = "")
{
    int error = GetLastError();
    string errorText = ErrorCodeToString(error);

    if(message == "")
    {
        Print("ERROR [", location, "]: Code=", error, " - ", errorText);
    }
    else
    {
        Print("ERROR [", location, "]: ", message, " (Code=", error, " - ", errorText, ")");
    }
}

//+------------------------------------------------------------------+
//| Log warning                                                       |
//+------------------------------------------------------------------+
void CErrorHandler::LogWarning(string location, string message)
{
    Print("WARNING [", location, "]: ", message);
}

//+------------------------------------------------------------------+
//| Log info                                                          |
//+------------------------------------------------------------------+
void CErrorHandler::LogInfo(string location, string message)
{
    Print("INFO [", location, "]: ", message);
}

//+------------------------------------------------------------------+
//| Check if error is retriable                                      |
//+------------------------------------------------------------------+
bool CErrorHandler::IsRetriableError(int errorCode)
{
    switch(errorCode)
    {
        case ERR_NO_CONNECTION:
        case ERR_TOO_FREQUENT_REQUESTS:
        case ERR_REQUEST_TIMEOUT:
        case ERR_MARKET_CLOSED:
        case ERR_TRADE_TIMEOUT:
        case ERR_PRICE_CHANGED:
        case ERR_REQUOTE:
        case ERR_ORDER_LOCKED:
        case ERR_TRADE_DISABLED:
            return true;

        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Check if error is critical                                       |
//+------------------------------------------------------------------+
bool CErrorHandler::IsCriticalError(int errorCode)
{
    switch(errorCode)
    {
        case ERR_ACCOUNT_DISABLED:
        case ERR_INVALID_ACCOUNT:
        case ERR_NO_MEMORY:
        case ERR_MARKET_CLOSED:
        case ERR_TRADE_DISABLED:
            return true;

        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Check if error is connection-related                             |
//+------------------------------------------------------------------+
bool CErrorHandler::IsConnectionError(int errorCode)
{
    switch(errorCode)
    {
        case ERR_NO_CONNECTION:
        case ERR_REQUEST_TIMEOUT:
        case ERR_TRADE_TIMEOUT:
            return true;

        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Convert error code to descriptive string                         |
//+------------------------------------------------------------------+
string CErrorHandler::ErrorCodeToString(int errorCode)
{
    switch(errorCode)
    {
        // Trade server errors
        case ERR_NO_ERROR:                  return "No error";
        case ERR_NO_RESULT:                 return "No result";
        case ERR_COMMON_ERROR:              return "Common error";
        case ERR_INVALID_TRADE_PARAMETERS:  return "Invalid trade parameters";
        case ERR_SERVER_BUSY:               return "Server is busy";
        case ERR_OLD_VERSION:               return "Old terminal version";
        case ERR_NO_CONNECTION:             return "No connection to trade server";
        case ERR_NOT_ENOUGH_RIGHTS:         return "Not enough rights";
        case ERR_TOO_FREQUENT_REQUESTS:     return "Too frequent requests";
        case ERR_MALFUNCTIONAL_TRADE:       return "Malfunctional trade operation";
        case ERR_ACCOUNT_DISABLED:          return "Account disabled";
        case ERR_INVALID_ACCOUNT:           return "Invalid account";
        case ERR_TRADE_TIMEOUT:             return "Trade timeout";
        case ERR_INVALID_PRICE:             return "Invalid price";
        case ERR_INVALID_STOPS:             return "Invalid stops";
        case ERR_INVALID_TRADE_VOLUME:      return "Invalid trade volume";
        case ERR_MARKET_CLOSED:             return "Market is closed";
        case ERR_TRADE_DISABLED:            return "Trade is disabled";
        case ERR_NOT_ENOUGH_MONEY:          return "Not enough money";
        case ERR_PRICE_CHANGED:             return "Price changed";
        case ERR_OFF_QUOTES:                return "Off quotes";
        case ERR_BROKER_BUSY:               return "Broker is busy";
        case ERR_REQUOTE:                   return "Requote";
        case ERR_ORDER_LOCKED:              return "Order is locked";
        case ERR_LONG_POSITIONS_ONLY_ALLOWED: return "Long positions only allowed";
        case ERR_TOO_MANY_REQUESTS:         return "Too many requests";

        // File errors
        case ERR_FILE_NOT_EXIST:            return "File does not exist";
        case ERR_FILE_WRONG_HANDLE:         return "Wrong file handle";
        case ERR_FILE_WRONG_OPEN_METHOD:    return "Wrong file open method";
        case ERR_FILE_READ_ERROR:           return "File read error";
        case ERR_FILE_WRITE_ERROR:          return "File write error";
        case ERR_FILE_BIN_STRINGSIZE:       return "Binary file string size error";
        case ERR_FILE_INCOMPATIBLE:         return "Incompatible file";
        case ERR_FILE_IS_DIRECTORY:         return "File is directory";
        case ERR_FILE_NOT_FOUND:            return "File not found";
        case ERR_FILE_CANNOT_OPEN:          return "Cannot open file";
        case ERR_FILE_CANNOT_REWRITE:       return "Cannot rewrite file";
        case ERR_FILE_WRONG_DIRECTORYNAME:  return "Wrong directory name";
        case ERR_FILE_DIRECTORY_NOT_EXIST:  return "Directory does not exist";
        case ERR_FILE_NOT_TOWRITE:          return "File not ready to write";
        case ERR_FILE_NOT_TOREAD:           return "File not ready to read";

        // String errors
        case ERR_STRING_SMALL_BUFFER:       return "String buffer too small";
        case ERR_STRING_TOO_LONG:           return "String too long";
        case ERR_STRING_UNKNOWNTYPE:        return "Unknown string type";
        case ERR_STRING_BUFFER_OVERFLOW:    return "String buffer overflow";

        // Array errors
        case ERR_ARRAY_INVALID:             return "Invalid array";
        case ERR_ARRAY_ERROR:               return "Array error";
        case ERR_ARRAY_AS_PARAMETER_EXPECTED: return "Array expected as parameter";

        // Memory errors
        case ERR_NO_MEMORY:                 return "No memory for function call stack";
        case ERR_REST_API_INTERNAL_ERROR:   return "REST API internal error";

        // Indicator errors
        case ERR_INDICATOR_CANNOT_CREATE:   return "Cannot create indicator";
        case ERR_INDICATOR_NO_MEMORY:       return "Not enough memory for indicator";
        case ERR_INDICATOR_CANNOT_APPLY:    return "Cannot apply indicator";
        case ERR_INDICATOR_UNKNOWN_SYMBOL:  return "Unknown symbol for indicator";
        case ERR_INDICATOR_WRONG_PARAMETERS: return "Wrong indicator parameters";

        // Market info errors
        case ERR_MARKET_UNKNOWN_SYMBOL:     return "Unknown symbol";
        case ERR_MARKET_NOT_SELECTED:       return "Symbol not selected in MarketWatch";
        case ERR_MARKET_WRONG_PROPERTY:     return "Wrong property identifier";

        // History access errors
        case ERR_HISTORY_WILL_UPDATED:      return "History will be updated";
        case ERR_HISTORY_SMALL_BUFFER:      return "History buffer too small";
        case ERR_HISTORY_TIMEOUT:           return "History request timeout";
        case ERR_HISTORY_NOT_FOUND:         return "History not found";

        default:
            return "Unknown error (" + IntegerToString(errorCode) + ")";
    }
}

//+------------------------------------------------------------------+
//| Get deinit reason text                                           |
//+------------------------------------------------------------------+
string CErrorHandler::GetDeinitReasonText(int reason)
{
    switch(reason)
    {
        case REASON_PROGRAM:       return "EA stopped by ExpertRemove() function";
        case REASON_REMOVE:        return "Program removed from chart";
        case REASON_RECOMPILE:     return "Program recompiled";
        case REASON_CHARTCHANGE:   return "Symbol or timeframe changed";
        case REASON_CHARTCLOSE:    return "Chart closed";
        case REASON_PARAMETERS:    return "Input parameters changed";
        case REASON_ACCOUNT:       return "Account changed";
        case REASON_TEMPLATE:      return "Template changed";
        case REASON_INITFAILED:    return "OnInit() returned INIT_FAILED";
        case REASON_CLOSE:         return "Terminal closed";

        default:
            return "Unknown deinit reason (" + IntegerToString(reason) + ")";
    }
}
//+------------------------------------------------------------------+
