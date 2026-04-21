// ═══════════════════════════════════════════════════════════════════════
// TRENDANALYZER.MQH - Weekly Trend Detection Module
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Analyze weekly candles to determine trend direction
// 
// Strategy:
// - Higher High + Higher Low = BULLISH
// - Lower High + Lower Low = BEARISH
// - Unclear = NEUTRAL
//
// Functions:
// - AnalyzeTrend() - Determine weekly trend
// - GetTrendStrength() - Rate trend strength (1-5)
// - GetWeeklyExtremes() - Get weekly high and low
// - GetTrendChangeCount() - Count bars since trend change
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __TRENDANALYZER_MQH__
#define __TRENDANALYZER_MQH__

#include "ChartData.mqh"

// ═══════════════════════════════════════════════════════════════════════
// TREND DIRECTION ENUM
// ═══════════════════════════════════════════════════════════════════════

enum TrendDirection {
    TREND_BULLISH = 1,      // Higher Highs & Higher Lows (↑)
    TREND_BEARISH = -1,     // Lower Highs & Lower Lows (↓)
    TREND_NEUTRAL = 0       // No clear direction (↔)
};

// ═══════════════════════════════════════════════════════════════════════
// TREND ANALYSIS RESULT
// ═══════════════════════════════════════════════════════════════════════

struct TrendAnalysis {
    TrendDirection direction;      // Trend direction
    double lastHigh;              // Last candle high
    double lastLow;               // Last candle low
    double previousHigh;          // Previous candle high
    double previousLow;           // Previous candle low
    int strength;                 // Strength 1-5 (5=strongest)
    double momentum;              // ATR-based momentum
    datetime analysisTime;        // When analysis was done
    
    // Constructor
    TrendAnalysis() : direction(TREND_NEUTRAL), lastHigh(0), lastLow(0),
                     previousHigh(0), previousLow(0), strength(0),
                     momentum(0), analysisTime(0) {}
};

// ═══════════════════════════════════════════════════════════════════════
// TREND ANALYZER CLASS
// ═══════════════════════════════════════════════════════════════════════

class TrendAnalyzer {
private:
    ChartData chartData;
    
public:
    // Constructor
    TrendAnalyzer(string symbol = "EURUSD") : chartData(symbol) {}
    
    // ─────────────────────────────────────────────────────────────────────
    // ANALYZE TREND - Main Function
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Analyze weekly trend by comparing last 2 candles
     * 
     * Logic:
     * - Get last 2 weekly candles
     * - Compare highs and lows
     * - Determine trend direction
     * - Calculate strength and momentum
     * 
     * @return TrendAnalysis structure with complete trend info
     */
    TrendAnalysis AnalyzeTrend() {
        TrendAnalysis result;
        result.analysisTime = TimeCurrent();
        
        // Get last 2 weekly candles
        Candle candle0 = chartData.GetCandle(PERIOD_W1, 0);  // Current week
        Candle candle1 = chartData.GetCandle(PERIOD_W1, 1);  // Previous week
        
        // Validate data
        if (candle0.close == 0 || candle1.close == 0) {
            result.direction = TREND_NEUTRAL;
            Print("[WARNING] Insufficient weekly data for trend analysis");
            return result;
        }
        
        // Store current candle extremes
        result.lastHigh = candle0.high;
        result.lastLow = candle0.low;
        result.previousHigh = candle1.high;
        result.previousLow = candle1.low;
        
        // ─────────────────────────────────────────────────────────────────
        // DETERMINE TREND DIRECTION
        // ─────────────────────────────────────────────────────────────────
        
        bool currentHH = candle0.high > candle1.high;    // Current High > Previous High
        bool currentHL = candle0.low > candle1.low;      // Current Low > Previous Low
        bool currentLH = candle0.high < candle1.high;    // Current High < Previous High
        bool currentLL = candle0.low < candle1.low;      // Current Low < Previous Low
        
        if (currentHH && currentHL) {
            // Higher Highs AND Higher Lows = STRONG BULLISH
            result.direction = TREND_BULLISH;
        }
        else if (currentLH && currentLL) {
            // Lower Highs AND Lower Lows = STRONG BEARISH
            result.direction = TREND_BEARISH;
        }
        else {
            // Mixed signals = No clear trend
            result.direction = TREND_NEUTRAL;
        }
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE TREND STRENGTH (1-5)
        // ─────────────────────────────────────────────────────────────────
        result.strength = CalculateTrendStrength(candle0, candle1);
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE MOMENTUM
        // ─────────────────────────────────────────────────────────────────
        result.momentum = CalculateMomentum();
        
        return result;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CALCULATE TREND STRENGTH
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Rate trend strength from 1 (weak) to 5 (very strong)
     */
    int CalculateTrendStrength(Candle current, Candle previous) {
        int strength = 1;
        
        // Calculate candle body sizes
        double currentBody = MathAbs(current.close - current.open);
        double previousBody = MathAbs(previous.close - previous.open);
        
        // Calculate highs difference
        double highDiff = current.high - previous.high;
        
        // Calculate distance between candles
        double gapDistance = 0;
        if (current.low > previous.high) {
            gapDistance = current.low - previous.high;  // Bullish gap
        }
        else if (previous.low > current.high) {
            gapDistance = previous.low - current.high;  // Bearish gap
        }
        
        double point = chartData.GetPoint();
        double gapPips = gapDistance / point;
        
        // Scoring system
        if (currentBody > previousBody * 1.5) strength++;   // Large body (+1)
        if (highDiff > 100 * point) strength++;             // Large HH diff (+1)
        if (gapPips > 50) strength++;                       // Large gap (+1)
        if (currentBody > previousBody && currentBody > 200 * point) strength++;  // Both large (+1)
        
        // Cap at 5
        return MathMin(strength, 5);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CALCULATE MOMENTUM
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate momentum using ATR-based measurement
     */
    double CalculateMomentum() {
        // Get ATR for momentum measurement
        double atr = iATR(chartData.symbol, PERIOD_W1, 14, 0);
        
        if (atr == 0) {
            Print("[WARNING] ATR not available");
            return 0;
        }
        
        return atr;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET WEEKLY EXTREMES
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get current week's high and low
     */
    void GetWeeklyExtremes(double& high, double& low) {
        Candle weeklyCandle = chartData.GetCandle(PERIOD_W1, 0);
        high = weeklyCandle.high;
        low = weeklyCandle.low;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET TREND CONFIRMATION
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if trend is confirmed (not just 2 candles)
     * Look back more candles for additional confirmation
     */
    bool IsTrendConfirmed(TrendDirection direction, int barsBack = 5) {
        int confirmationCount = 0;
        
        for (int i = 0; i < barsBack; i++) {
            Candle current = chartData.GetCandle(PERIOD_W1, i);
            Candle previous = chartData.GetCandle(PERIOD_W1, i + 1);
            
            if (current.close == 0 || previous.close == 0) break;
            
            bool isHH = current.high >= previous.high;
            bool isHL = current.low >= previous.low;
            bool isLH = current.high <= previous.high;
            bool isLL = current.low <= previous.low;
            
            if (direction == TREND_BULLISH && isHH && isHL) {
                confirmationCount++;
            }
            else if (direction == TREND_BEARISH && isLH && isLL) {
                confirmationCount++;
            }
        }
        
        // Trend confirmed if at least 60% of candles follow the pattern
        return confirmationCount >= (barsBack / 2);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET TREND DURATION
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Count how many weekly candles continue the trend
     */
    int GetTrendDuration(TrendDirection direction) {
        int duration = 0;
        
        for (int i = 0; i < 100; i++) {
            Candle current = chartData.GetCandle(PERIOD_W1, i);
            Candle previous = chartData.GetCandle(PERIOD_W1, i + 1);
            
            if (current.close == 0 || previous.close == 0) break;
            
            bool isHH = current.high >= previous.high;
            bool isHL = current.low >= previous.low;
            bool isLH = current.high <= previous.high;
            bool isLL = current.low <= previous.low;
            
            if (direction == TREND_BULLISH && isHH && isHL) {
                duration++;
            }
            else if (direction == TREND_BEARISH && isLH && isLL) {
                duration++;
            }
            else {
                break;  // Trend broken
            }
        }
        
        return duration;
    }
};

#endif  // __TRENDANALYZER_MQH__

// ═══════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE:
// ═══════════════════════════════════════════════════════════════════════
//
// TrendAnalyzer trendAnalyzer("EURUSD");
//
// // Analyze weekly trend
// TrendAnalysis trend = trendAnalyzer.AnalyzeTrend();
//
// if (trend.direction == TREND_BULLISH) {
//     Print("Weekly trend is BULLISH");
//     Print("Strength: ", trend.strength, "/5");
//     Print("Momentum (ATR): ", trend.momentum);
// }
// else if (trend.direction == TREND_BEARISH) {
//     Print("Weekly trend is BEARISH");
// }
// else {
//     Print("Weekly trend is NEUTRAL - No trades");
// }
//
// // Check if trend is confirmed
// if (trendAnalyzer.IsTrendConfirmed(trend.direction)) {
//     Print("Trend is confirmed!");
// }
//
// // Get how long trend has been going
// int trendWeeks = trendAnalyzer.GetTrendDuration(trend.direction);
// Print("Trend duration: ", trendWeeks, " weeks");
// ═══════════════════════════════════════════════════════════════════════
