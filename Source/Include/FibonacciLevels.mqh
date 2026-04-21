// ═══════════════════════════════════════════════════════════════════════
// FIBONACCILEVELS.MQH - Fibonacci Retracement & Extension Calculations
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Calculate Fibonacci retracement and extension levels
//
// Fibonacci Ratios:
// - 0.236 (23.6%)  - Weak support/resistance
// - 0.382 (38.2%)  - Moderate support
// - 0.618 (61.8%)  - Major support
// - 1.618 (161.8%) - Extension target
//
// Functions:
// - CalculateFibonacci() - Main calculation
// - GetFibonacciLevel() - Get specific level
// - IsPriceNearFibonacci() - Check price proximity
// - GetNextTarget() - Next expected Fibonacci level
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __FIBONACCILEVELS_MQH__
#define __FIBONACCILEVELS_MQH__

#include "ChartData.mqh"

// ═══════════════════════════════════════════════════════════════════════
// FIBONACCI LEVELS STRUCTURE
// ═══════════════════════════════════════════════════════════════════════

struct FibonacciLevels {
    double high;              // Impulse high
    double low;               // Impulse low
    double range;             // High - low
    
    // Retracement levels
    double level_236;         // 23.6% retracement
    double level_382;         // 38.2% retracement
    double level_618;         // 61.8% retracement
    
    // Extension levels
    double level_1618;        // 161.8% extension
    double level_2618;        // 261.8% extension
    double level_4236;        // 423.6% extension
    
    bool isUptrend;           // Direction of impulse
    datetime calculatedAt;    // When calculated
    
    // Constructor
    FibonacciLevels() : high(0), low(0), range(0),
                        level_236(0), level_382(0), level_618(0),
                        level_1618(0), level_2618(0), level_4236(0),
                        isUptrend(true), calculatedAt(0) {}
};

// ═══════════════════════════════════════════════════════════════════════
// FIBONACCI CALCULATOR CLASS
// ═══════════════════════════════════════════════════════════════════════

class FibonacciCalculator {
private:
    ChartData chartData;
    
public:
    // Constructor
    FibonacciCalculator(string symbol = "EURUSD") : chartData(symbol) {}
    
    // ─────────────────────────────────────────────────────────────────────
    // CALCULATE FIBONACCI LEVELS - Main Function
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate all Fibonacci levels from impulse range
     * 
     * @param highPrice - Impulse high
     * @param lowPrice - Impulse low
     * @param isUptrend - If true, low is base; if false, high is base
     * @return FibonacciLevels with all calculations
     */
    FibonacciLevels CalculateFibonacci(double highPrice, double lowPrice, bool isUptrend = true) {
        FibonacciLevels fib;
        fib.high = highPrice;
        fib.low = lowPrice;
        fib.isUptrend = isUptrend;
        fib.calculatedAt = TimeCurrent();
        
        // Validate inputs
        if (highPrice <= lowPrice) {
            Print("[ERROR] High price must be greater than low price");
            return fib;
        }
        
        fib.range = highPrice - lowPrice;
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE RETRACEMENT LEVELS (for identifying support)
        // ─────────────────────────────────────────────────────────────────
        
        if (isUptrend) {
            // In uptrend, retracements are from high down
            fib.level_236 = highPrice - (fib.range * 0.236);
            fib.level_382 = highPrice - (fib.range * 0.382);
            fib.level_618 = highPrice - (fib.range * 0.618);
        } else {
            // In downtrend, retracements are from low up
            fib.level_236 = lowPrice + (fib.range * 0.236);
            fib.level_382 = lowPrice + (fib.range * 0.382);
            fib.level_618 = lowPrice + (fib.range * 0.618);
        }
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE EXTENSION LEVELS (for identifying targets)
        // ─────────────────────────────────────────────────────────────────
        
        if (isUptrend) {
            // In uptrend, extensions are above high
            fib.level_1618 = highPrice + (fib.range * 0.618);
            fib.level_2618 = highPrice + (fib.range * 1.618);
            fib.level_4236 = highPrice + (fib.range * 2.618);
        } else {
            // In downtrend, extensions are below low
            fib.level_1618 = lowPrice - (fib.range * 0.618);
            fib.level_2618 = lowPrice - (fib.range * 1.618);
            fib.level_4236 = lowPrice - (fib.range * 2.618);
        }
        
        return fib;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET FIBONACCI LEVEL BY RATIO
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get Fibonacci level for specific ratio
     * 
     * @param ratio - Fibonacci ratio (0.236, 0.382, 0.618, 1.618, etc.)
     * @return Price level
     */
    double GetFibonacciLevel(FibonacciLevels fib, double ratio) {
        if (fib.isUptrend) {
            if (ratio < 1.0) {
                // Retracement
                return fib.high - (fib.range * ratio);
            } else {
                // Extension
                return fib.high + (fib.range * (ratio - 1.0));
            }
        } else {
            if (ratio < 1.0) {
                // Retracement
                return fib.low + (fib.range * ratio);
            } else {
                // Extension
                return fib.low - (fib.range * (ratio - 1.0));
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CHECK IF PRICE NEAR FIBONACCI LEVEL
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if price is near any Fibonacci level
     * 
     * @param currentPrice - Current market price
     * @param tolerancePips - Tolerance in pips
     * @return -1=none, 236, 382, 618, 1618, 2618, 4236
     */
    int IsPriceNearFibonacci(FibonacciLevels fib, double currentPrice, double tolerancePips = 5.0) {
        double point = chartData.GetPoint();
        double tolerance = tolerancePips * point;
        
        // Check retracement levels
        if (MathAbs(currentPrice - fib.level_236) <= tolerance) return 236;
        if (MathAbs(currentPrice - fib.level_382) <= tolerance) return 382;
        if (MathAbs(currentPrice - fib.level_618) <= tolerance) return 618;
        
        // Check extension levels
        if (MathAbs(currentPrice - fib.level_1618) <= tolerance) return 1618;
        if (MathAbs(currentPrice - fib.level_2618) <= tolerance) return 2618;
        if (MathAbs(currentPrice - fib.level_4236) <= tolerance) return 4236;
        
        return -1;  // Not near any level
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET NEAREST FIBONACCI LEVEL
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get nearest Fibonacci level to current price
     */
    double GetNearestLevel(FibonacciLevels fib, double currentPrice) {
        double distances[7];
        double levels[7];
        
        levels[0] = fib.level_236;
        levels[1] = fib.level_382;
        levels[2] = fib.level_618;
        levels[3] = fib.level_1618;
        levels[4] = fib.level_2618;
        levels[5] = fib.level_4236;
        
        for (int i = 0; i < 6; i++) {
            distances[i] = MathAbs(currentPrice - levels[i]);
        }
        
        int nearest = 0;
        for (int i = 1; i < 6; i++) {
            if (distances[i] < distances[nearest]) {
                nearest = i;
            }
        }
        
        return levels[nearest];
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // IDENTIFY RETRACEMENT PERCENTAGE
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate what percentage price has retraced
     * 
     * @param currentPrice - Current price
     * @return Percentage (0.0 to 1.0)
     */
    double GetRetracementPercentage(FibonacciLevels fib, double currentPrice) {
        if (fib.range == 0) return 0;
        
        if (fib.isUptrend) {
            // From high going down
            double distanceFromHigh = fib.high - currentPrice;
            return distanceFromHigh / fib.range;
        } else {
            // From low going up
            double distanceFromLow = currentPrice - fib.low;
            return distanceFromLow / fib.range;
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CLASSIFY RETRACEMENT DEPTH
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Classify retracement as shallow, moderate, or deep
     * 
     * @param retracementPercent - Retracement percentage (0-1)
     * @return "Shallow" (0-38%), "Moderate" (38-62%), "Deep" (62-100%)
     */
    string ClassifyRetracement(double retracementPercent) {
        if (retracementPercent < 0.38) {
            return "Shallow";      // Continuation likely
        }
        else if (retracementPercent < 0.62) {
            return "Moderate";     // Normal retracement
        }
        else {
            return "Deep";         // Potential reversal
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET NEXT PRICE TARGET
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate next expected price target
     * Based on Fibonacci extension after retracement
     */
    double GetNextTarget(FibonacciLevels fib) {
        // If price retracted to 61.8%, next target is 161.8% extension
        return fib.level_1618;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // VALIDATE FIBONACCI PATTERN
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if price action matches Fibonacci expectations
     * Returns confidence level (0-100%)
     */
    int ValidatePattern(FibonacciLevels fib, double currentPrice, double tolerancePips = 10.0) {
        double point = chartData.GetPoint();
        double tolerance = tolerancePips * point;
        
        // Count how many Fibonacci levels are within tolerance
        int nearLevelCount = 0;
        
        if (MathAbs(currentPrice - fib.level_236) <= tolerance) nearLevelCount++;
        if (MathAbs(currentPrice - fib.level_382) <= tolerance) nearLevelCount++;
        if (MathAbs(currentPrice - fib.level_618) <= tolerance) nearLevelCount++;
        if (MathAbs(currentPrice - fib.level_1618) <= tolerance) nearLevelCount++;
        
        // Confidence increases if price is near multiple levels
        return nearLevelCount * 25;  // 25% per level (max 100%)
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // PRINT FIBONACCI LEVELS (For debugging)
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Print all Fibonacci levels to journal
     */
    void PrintLevels(FibonacciLevels fib) {
        Print("════════════════════════════════════════");
        Print("Fibonacci Levels (Range: ", fib.range, ")");
        Print("════════════════════════════════════════");
        Print("High: ", fib.high, " | Low: ", fib.low);
        Print("────────────────────────────────────────");
        Print("Retracements:");
        Print("  23.6%: ", fib.level_236);
        Print("  38.2%: ", fib.level_382);
        Print("  61.8%: ", fib.level_618);
        Print("────────────────────────────────────────");
        Print("Extensions:");
        Print("  161.8%: ", fib.level_1618);
        Print("  261.8%: ", fib.level_2618);
        Print("  423.6%: ", fib.level_4236);
        Print("════════════════════════════════════════");
    }
};

#endif  // __FIBONACCILEVELS_MQH__

// ═══════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE:
// ═══════════════════════════════════════════════════════════════════════
//
// FibonacciCalculator fib("EURUSD");
//
// // Identify impulse range on 4H
// double impulseHigh = 1.1000;
// double impulseLow = 1.0500;
// bool isUptrend = true;
//
// // Calculate all levels
// FibonacciLevels levels = fib.CalculateFibonacci(impulseHigh, impulseLow, isUptrend);
// fib.PrintLevels(levels);  // See all levels
//
// // Check current price
// double currentPrice = 1.0809;
// int nearLevel = fib.IsPriceNearFibonacci(levels, currentPrice, 5.0);
// if (nearLevel > 0) {
//     Print("Price near Fibonacci level: ", nearLevel);
// }
//
// // Get next target
// double target = fib.GetNextTarget(levels);
// Print("Next target: ", target);
//
// // Classify retracement depth
// double retracPercent = fib.GetRetracementPercentage(levels, currentPrice);
// string classification = fib.ClassifyRetracement(retracPercent);
// Print("Retracement: ", retracPercent * 100, "% (", classification, ")");
// ═══════════════════════════════════════════════════════════════════════
