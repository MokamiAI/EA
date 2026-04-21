// ═══════════════════════════════════════════════════════════════════════
// CHARTDATA.MQH - OHLC Data Management Module
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Fetch and manage OHLC (Open, High, Low, Close) data
// for all required timeframes
//
// Functions:
// - GetCandle() - Get single candle for specific timeframe
// - GetCandleHistory() - Get array of candles
// - GetCurrentHigh() - Get current bar high
// - GetCurrentLow() - Get current bar low
// - IsNewBar() - Check if new bar formed
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __CHARTDATA_MQH__
#define __CHARTDATA_MQH__

// ═══════════════════════════════════════════════════════════════════════
// CANDLE DATA STRUCTURE
// ═══════════════════════════════════════════════════════════════════════

struct Candle {
    datetime time;      // Bar time
    double open;        // Opening price
    double high;        // Highest price
    double low;         // Lowest price
    double close;       // Closing price
    long volume;        // Volume
    
    // Constructor
    Candle() : time(0), open(0), high(0), low(0), close(0), volume(0) {}
};

// ═══════════════════════════════════════════════════════════════════════
// CHART DATA CLASS
// ═══════════════════════════════════════════════════════════════════════

class ChartData {
private:
    string symbol;
    datetime lastBarTime[5];  // Track bar times for each timeframe
    
public:
    // Constructor
    ChartData(string sym = "EURUSD") : symbol(sym) {
        ArrayInitialize(lastBarTime, 0);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET SINGLE CANDLE
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get a single candle from specified timeframe
     * 
     * @param tf - Timeframe (PERIOD_M5, PERIOD_H1, PERIOD_D1, etc.)
     * @param index - Bar index (0=current, 1=previous, etc.)
     * @return Candle structure with OHLC data
     */
    Candle GetCandle(ENUM_TIMEFRAMES tf, int index = 0) {
        Candle candle;
        
        // Validate inputs
        if (!SymbolSelect(symbol, true)) {
            Print("[ERROR] Symbol not found: ", symbol);
            return candle;
        }
        
        // Fetch OHLC data
        candle.time = iTime(symbol, tf, index);
        candle.open = iOpen(symbol, tf, index);
        candle.high = iHigh(symbol, tf, index);
        candle.low = iLow(symbol, tf, index);
        candle.close = iClose(symbol, tf, index);
        candle.volume = iVolume(symbol, tf, index);
        
        // Validate data
        if (candle.time == 0 || candle.close == 0) {
            Print("[WARNING] Invalid candle data for ", symbol, " at index ", index);
        }
        
        return candle;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET CANDLE HISTORY
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get array of candles from specified timeframe
     * 
     * @param tf - Timeframe
     * @param count - Number of candles to fetch
     * @return Array of Candle structures
     */
    void GetCandleHistory(ENUM_TIMEFRAMES tf, int count, Candle& result[]) {
        // Resize array
        ArrayResize(result, count);
        
        // Fetch candles in reverse order (0=current, 1=previous, etc.)
        for (int i = 0; i < count; i++) {
            result[i] = GetCandle(tf, i);
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET CURRENT HIGH/LOW
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get highest price in current bar
     */
    double GetCurrentHigh(ENUM_TIMEFRAMES tf) {
        return iHigh(symbol, tf, 0);
    }
    
    /**
     * Get lowest price in current bar
     */
    double GetCurrentLow(ENUM_TIMEFRAMES tf) {
        return iLow(symbol, tf, 0);
    }
    
    /**
     * Get current bid price
     */
    double GetBid() {
        return SymbolInfoDouble(symbol, SYMBOL_BID);
    }
    
    /**
     * Get current ask price
     */
    double GetAsk() {
        return SymbolInfoDouble(symbol, SYMBOL_ASK);
    }
    
    /**
     * Get current spread in pips
     */
    double GetSpreadPips() {
        double bid = GetBid();
        double ask = GetAsk();
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        return (ask - bid) / point;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CHECK NEW BAR
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if new bar has formed on specified timeframe
     * 
     * @param tf - Timeframe to check
     * @return true if new bar formed, false otherwise
     */
    bool IsNewBar(ENUM_TIMEFRAMES tf) {
        datetime currentBarTime = iTime(symbol, tf, 0);
        
        if (currentBarTime != lastBarTime[tf]) {
            lastBarTime[tf] = currentBarTime;
            return true;
        }
        
        return false;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET SYMBOL INFO
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get number of decimal places for symbol
     */
    int GetDigits() {
        return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    }
    
    /**
     * Get point size (0.0001 for 4-digit, 0.00001 for 5-digit)
     */
    double GetPoint() {
        return SymbolInfoDouble(symbol, SYMBOL_POINT);
    }
    
    /**
     * Get pip size (0.0001 for most pairs)
     */
    double GetPipSize() {
        return SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
    }
    
    /**
     * Get minimum lot size
     */
    double GetMinLot() {
        return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    }
    
    /**
     * Get maximum lot size
     */
    double GetMaxLot() {
        return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    }
    
    /**
     * Get lot step (0.01 for most brokers)
     */
    double GetLotStep() {
        return SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    }
};

#endif  // __CHARTDATA_MQH__

// ═══════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE:
// ═══════════════════════════════════════════════════════════════════════
//
// ChartData chart("EURUSD");
//
// // Get single candle
// Candle dailyCandle = chart.GetCandle(PERIOD_D1, 0);
// Print("Daily close: ", dailyCandle.close);
//
// // Get candle history
// Candle historyArray[];
// chart.GetCandleHistory(PERIOD_H1, 10, historyArray);
//
// // Check for new 5M bar
// if (chart.IsNewBar(PERIOD_M5)) {
//     Print("New 5-minute bar formed!");
// }
//
// // Get spread
// double spreadPips = chart.GetSpreadPips();
// if (spreadPips > 2.0) {
//     Print("Spread too high: ", spreadPips);
// }
// ═══════════════════════════════════════════════════════════════════════
