// ═══════════════════════════════════════════════════════════════════════
// PATTERNRECOGNIZER.MQH - 4-Hour Price Action Pattern Recognition
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Identify continuation and reversal patterns on 4H chart
//
// Patterns Recognized:
// - Continuation: Retracement that continues impulse direction
// - Reversal: Deep retracement that reverses direction
// - Consolidation: Tight range with low volatility
//
// Functions:
// - Recognize4HPattern() - Main analysis
// - ClassifyPattern() - Continuation vs Reversal
// - GetPatternConfidence() - Confidence level
// - FindPatternStart/End() - Pattern boundaries
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __PATTERNRECOGNIZER_MQH__
#define __PATTERNRECOGNIZER_MQH__

#include "ChartData.mqh"
#include "FibonacciLevels.mqh"

// ═══════════════════════════════════════════════════════════════════════
// PATTERN TYPE ENUM
// ═══════════════════════════════════════════════════════════════════════

enum PatternType {
    PATTERN_CONTINUATION = 1,      // Retracement < 61.8%, continues
    PATTERN_REVERSAL = -1,         // Retracement > 61.8%, reverses
    PATTERN_CONSOLIDATION = 0,     // Tight range, low volatility
    PATTERN_NONE = 2               // No clear pattern
};

// ═══════════════════════════════════════════════════════════════════════
// 4-HOUR PATTERN ANALYSIS RESULT
// ═══════════════════════════════════════════════════════════════════════

struct Pattern4H {
    PatternType type;                  // Pattern classification
    double impulseStart;               // Impulse beginning price
    double impulseEnd;                 // Impulse ending price
    double retraceStart;               // Retracement beginning
    double retraceEnd;                 // Retracement ending
    double retracePercentage;          // Retracement depth (0-1)
    int patternBars;                   // Bars in pattern
    double volatility;                 // Pattern volatility (ATR)
    int confidence;                    // Confidence 0-100%
    bool continuation;                 // Is continuation pattern
    bool reversal;                     // Is reversal pattern
    datetime patternStart;             // When pattern started
    datetime patternEnd;               // When pattern completed
    
    // Constructor
    Pattern4H() : type(PATTERN_NONE), impulseStart(0), impulseEnd(0),
                 retraceStart(0), retraceEnd(0), retracePercentage(0),
                 patternBars(0), volatility(0), confidence(0),
                 continuation(false), reversal(false),
                 patternStart(0), patternEnd(0) {}
};

// ═══════════════════════════════════════════════════════════════════════
// PATTERN RECOGNIZER CLASS
// ═══════════════════════════════════════════════════════════════════════

class PatternRecognizer {
private:
    ChartData chartData;
    FibonacciCalculator fibCalc;
    
public:
    // Constructor
    PatternRecognizer(string symbol = "EURUSD") 
        : chartData(symbol), fibCalc(symbol) {}
    
    // ─────────────────────────────────────────────────────────────────────
    // RECOGNIZE 4H PATTERN - Main Function
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Analyze 4H chart to recognize price action patterns
     * 
     * Process:
     * 1. Identify impulse (last strong move)
     * 2. Find retracement (pullback from impulse)
     * 3. Classify as continuation or reversal
     * 4. Calculate confidence
     * 
     * @return Pattern4H with complete analysis
     */
    Pattern4H Recognize4HPattern() {
        Pattern4H result;
        result.patternEnd = TimeCurrent();
        
        // ─────────────────────────────────────────────────────────────────
        // GET 4H CANDLES FOR ANALYSIS
        // ─────────────────────────────────────────────────────────────────
        
        Candle candles[20];
        chartData.GetCandleHistory(PERIOD_H4, 20, candles);
        
        if (candles[0].close == 0) {
            Print("[WARNING] Insufficient 4H data");
            return result;
        }
        
        // ─────────────────────────────────────────────────────────────────
        // IDENTIFY IMPULSE WAVE
        // ─────────────────────────────────────────────────────────────────
        
        int impulseStart = 0;
        int impulseEnd = 0;
        double impulseDistance = 0;
        bool isUptrendImpulse = false;
        
        // Look back for strong directional move
        for (int i = 5; i < 15; i++) {
            Candle c1 = candles[i];
            Candle c0 = candles[i - 1];
            
            if (c1.close == 0 || c0.close == 0) break;
            
            // Check for strong uptrend impulse
            if (c1.high > c0.high && c1.low > c0.low && c1.close > c1.open) {
                double move = c1.high - c0.low;
                if (move > impulseDistance) {
                    impulseDistance = move;
                    impulseStart = i;
                    impulseEnd = i - 1;
                    isUptrendImpulse = true;
                    result.impulseStart = c0.low;
                    result.impulseEnd = c1.high;
                }
            }
            // Check for strong downtrend impulse
            else if (c1.high < c0.high && c1.low < c0.low && c1.close < c1.open) {
                double move = c0.high - c1.low;
                if (move > impulseDistance) {
                    impulseDistance = move;
                    impulseStart = i;
                    impulseEnd = i - 1;
                    isUptrendImpulse = false;
                    result.impulseStart = c0.high;
                    result.impulseEnd = c1.low;
                }
            }
        }
        
        if (impulseDistance == 0) {
            result.type = PATTERN_NONE;
            Print("[INFO] No clear impulse wave identified");
            return result;
        }
        
        // ─────────────────────────────────────────────────────────────────
        // IDENTIFY RETRACEMENT
        // ─────────────────────────────────────────────────────────────────
        
        // Get current price for retracement calculation
        Candle current = candles[0];
        
        if (isUptrendImpulse) {
            // In uptrend: impulse low to high, then retracement down
            result.retraceStart = result.impulseEnd;
            result.retraceEnd = current.close;
            double retracedDistance = result.retraceStart - result.retraceEnd;
            result.retracePercentage = retracedDistance / impulseDistance;
        } else {
            // In downtrend: impulse high to low, then retracement up
            result.retraceStart = result.impulseEnd;
            result.retraceEnd = current.close;
            double retracedDistance = result.retraceEnd - result.retraceStart;
            result.retracePercentage = retracedDistance / impulseDistance;
        }
        
        // ─────────────────────────────────────────────────────────────────
        // CLASSIFY PATTERN
        // ─────────────────────────────────────────────────────────────────
        
        result = ClassifyPattern(result, isUptrendImpulse);
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE VOLATILITY
        // ─────────────────────────────────────────────────────────────────
        
        result.volatility = iATR(chartData.symbol, PERIOD_H4, 14, 0);
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE PATTERN BARS
        // ─────────────────────────────────────────────────────────────────
        
        result.patternBars = impulseStart + 1;  // Bars from impulse start to now
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE CONFIDENCE
        // ─────────────────────────────────────────────────────────────────
        
        result.confidence = CalculatePatternConfidence(result);
        
        return result;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CLASSIFY PATTERN
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Classify pattern as continuation, reversal, or consolidation
     */
    Pattern4H ClassifyPattern(Pattern4H pattern, bool isUptrend) {
        pattern.patternStart = TimeCurrent();
        
        // Shallow retracement (0-38.2%) = Strong continuation
        if (pattern.retracePercentage < 0.382) {
            pattern.type = PATTERN_CONTINUATION;
            pattern.continuation = true;
        }
        // Moderate retracement (38.2-61.8%) = Normal correction
        else if (pattern.retracePercentage < 0.618) {
            pattern.type = PATTERN_CONTINUATION;  // Still continues
            pattern.continuation = true;
        }
        // Deep retracement (61.8%+) = Potential reversal
        else if (pattern.retracePercentage >= 0.618) {
            pattern.type = PATTERN_REVERSAL;
            pattern.reversal = true;
        }
        
        return pattern;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CALCULATE PATTERN CONFIDENCE
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate confidence score (0-100%)
     * Based on pattern characteristics
     */
    int CalculatePatternConfidence(Pattern4H pattern) {
        int confidence = 50;  // Base confidence
        
        // Retracement depth affects confidence
        if (pattern.retracePercentage >= 0.382 && pattern.retracePercentage <= 0.618) {
            confidence += 20;  // Ideal retracement depth
        }
        
        // Pattern duration matters
        if (pattern.patternBars >= 5) {
            confidence += 15;  // Adequate formation time
        }
        
        // Continuation patterns more reliable
        if (pattern.continuation && pattern.retracePercentage < 0.5) {
            confidence += 15;  // Strong continuation pattern
        }
        
        // Cap at 100%
        if (confidence > 100) confidence = 100;
        if (confidence < 0) confidence = 0;
        
        return confidence;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // IS PATTERN CONFIRMED
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if pattern is confirmed (at minimum confidence level)
     */
    bool IsPatternConfirmed(Pattern4H pattern, int minConfidence = 60) {
        if (pattern.type == PATTERN_NONE) {
            return false;
        }
        
        if (pattern.confidence < minConfidence) {
            return false;
        }
        
        // Continuation patterns need moderate retracement
        if (pattern.continuation && pattern.retracePercentage > 0.786) {
            return false;
        }
        
        return true;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET NEXT PRICE LEVEL
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get expected next price level based on pattern
     * For continuation: Project impulse further
     * For reversal: Project in opposite direction
     */
    double GetNextPriceLevel(Pattern4H pattern) {
        double impulseRange = MathAbs(pattern.impulseEnd - pattern.impulseStart);
        
        if (pattern.continuation) {
            // Project impulse 1:1 or 1:1.618
            return pattern.impulseEnd + impulseRange;
        } else {
            // Reverse to opposite end
            return pattern.impulseStart;
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // IDENTIFY ENTRY ZONE
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Identify best entry zone based on pattern
     * Returns high and low of entry zone
     */
    void GetEntryZone(Pattern4H pattern, double& entryHigh, double& entryLow) {
        // Entry zone is typically at 61.8% retracement
        double levelDistance = MathAbs(pattern.retraceStart - pattern.retraceEnd);
        
        if (pattern.retracePercentage < 0.618) {
            // Price hasn't reached 61.8% yet, project to that level
            if (pattern.retraceStart > pattern.retraceEnd) {
                // Downtrend retracement
                double level618 = pattern.retraceStart - (levelDistance / 0.618 * 0.618);
                entryHigh = level618 + levelDistance * 0.1;
                entryLow = level618 - levelDistance * 0.1;
            } else {
                // Uptrend retracement
                double level618 = pattern.retraceStart + (levelDistance / 0.618 * 0.618);
                entryHigh = level618 + levelDistance * 0.1;
                entryLow = level618 - levelDistance * 0.1;
            }
        } else {
            // Price is at or beyond 61.8%, entry zone is current area
            entryHigh = MathMax(pattern.retraceEnd, pattern.impulseEnd);
            entryLow = MathMin(pattern.retraceEnd, pattern.impulseEnd);
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // PRINT PATTERN ANALYSIS (For debugging)
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Print pattern analysis to journal
     */
    void PrintPatternAnalysis(Pattern4H pattern) {
        Print("════════════════════════════════════════");
        Print("4H Pattern Analysis");
        Print("════════════════════════════════════════");
        
        if (pattern.type == PATTERN_CONTINUATION) {
            Print("Type: CONTINUATION");
        } else if (pattern.type == PATTERN_REVERSAL) {
            Print("Type: REVERSAL");
        } else if (pattern.type == PATTERN_CONSOLIDATION) {
            Print("Type: CONSOLIDATION");
        } else {
            Print("Type: NO PATTERN");
        }
        
        Print("────────────────────────────────────────");
        Print("Impulse: ", pattern.impulseStart, " to ", pattern.impulseEnd);
        Print("Retrace: ", pattern.retraceStart, " to ", pattern.retraceEnd);
        Print("Retrace %: ", (pattern.retracePercentage * 100), "%");
        Print("Pattern Bars: ", pattern.patternBars);
        Print("Confidence: ", pattern.confidence, "%");
        Print("════════════════════════════════════════");
    }
};

#endif  // __PATTERNRECOGNIZER_MQH__

// ═══════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE:
// ═══════════════════════════════════════════════════════════════════════
//
// PatternRecognizer recognizer("EURUSD");
//
// // Analyze 4H pattern
// Pattern4H pattern = recognizer.Recognize4HPattern();
// recognizer.PrintPatternAnalysis(pattern);
//
// if (recognizer.IsPatternConfirmed(pattern)) {
//     Print("✓ Pattern is CONFIRMED");
//     
//     if (pattern.continuation) {
//         Print("Expect continuation of impulse");
//         double nextLevel = recognizer.GetNextPriceLevel(pattern);
//         Print("Next target: ", nextLevel);
//     } else {
//         Print("Expect reversal");
//     }
// } else {
//     Print("✗ Pattern needs more confirmation");
// }
//
// // Get entry zone
// double high, low;
// recognizer.GetEntryZone(pattern, high, low);
// Print("Entry zone: ", low, " to ", high);
// ═══════════════════════════════════════════════════════════════════════
