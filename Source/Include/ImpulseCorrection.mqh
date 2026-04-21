// ═══════════════════════════════════════════════════════════════════════
// IMPULSECORRECTION.MQH - Daily Impulse/Correction Detection
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Identify if daily price action is in impulse (strong move)
// or correction (retracement) state
//
// Impulse: Strong directional candles with momentum
// Correction: Tight range, consolidation, lower momentum
//
// Functions:
// - DetectDailyState() - Main function
// - CalculateMomentum() - ATR-based momentum
// - ImpulseConfirmed() - Verify impulse state
// - CorrectionConfirmed() - Verify correction state
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __IMPULSECORRECTION_MQH__
#define __IMPULSECORRECTION_MQH__

#include "ChartData.mqh"

// ═══════════════════════════════════════════════════════════════════════
// PRICE STATE ENUM
// ═══════════════════════════════════════════════════════════════════════

enum PriceState {
    STATE_IMPULSE = 1,      // Strong directional move
    STATE_CORRECTION = -1,  // Retracement/consolidation
    STATE_UNKNOWN = 0       // Insufficient data
};

// ═══════════════════════════════════════════════════════════════════════
// DAILY STATE RESULT
// ═══════════════════════════════════════════════════════════════════════

struct DailyState {
    PriceState state;               // Current state
    double momentum;                // ATR-based momentum
    double momentumThreshold;       // Threshold for impulse
    int barsSinceStateChange;       // Bars in current state
    double averageCandleBody;       // Avg candle size
    double averageCandle Range;     // Avg candle range
    bool momentumConfirmed;         // Is momentum confirmed
    datetime analysisTime;          // When analyzed
    
    // Constructor
    DailyState() : state(STATE_UNKNOWN), momentum(0), momentumThreshold(0),
                  barsSinceStateChange(0), averageCandleBody(0),
                  averageCandleRange(0), momentumConfirmed(false),
                  analysisTime(0) {}
};

// ═══════════════════════════════════════════════════════════════════════
// IMPULSE/CORRECTION ANALYZER CLASS
// ═══════════════════════════════════════════════════════════════════════

class ImpulseCorrectionAnalyzer {
private:
    ChartData chartData;
    int lastStateChangeBar;
    PriceState lastState;
    
public:
    // Constructor
    ImpulseCorrectionAnalyzer(string symbol = "EURUSD") 
        : chartData(symbol), lastStateChangeBar(0), lastState(STATE_UNKNOWN) {}
    
    // ─────────────────────────────────────────────────────────────────────
    // DETECT DAILY STATE - Main Function
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Detect if daily price action is in impulse or correction
     * 
     * Logic:
     * - Calculate ATR for momentum measurement
     * - Get last 5-10 daily candles
     * - Analyze candle bodies and ranges
     * - Determine state based on momentum threshold
     * 
     * @param momentumMultiplier - ATR multiplier threshold (default 1.5)
     * @return DailyState with current state info
     */
    DailyState DetectDailyState(double momentumMultiplier = 1.5) {
        DailyState result;
        result.analysisTime = TimeCurrent();
        
        // ─────────────────────────────────────────────────────────────────
        // CALCULATE MOMENTUM
        // ─────────────────────────────────────────────────────────────────
        
        double atr = iATR(chartData.symbol, PERIOD_D1, 14, 0);
        double eMA20 = iMA(chartData.symbol, PERIOD_D1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
        
        if (atr <= 0) {
            result.state = STATE_UNKNOWN;
            Print("[WARNING] ATR not available for daily analysis");
            return result;
        }
        
        result.momentum = atr;
        result.momentumThreshold = atr * momentumMultiplier;
        
        // ─────────────────────────────────────────────────────────────────
        // ANALYZE LAST 10 DAILY CANDLES
        // ─────────────────────────────────────────────────────────────────
        
        int analysisBarCount = 10;
        double totalBody = 0;
        double totalRange = 0;
        int strongCandleCount = 0;
        int weakCandleCount = 0;
        
        for (int i = 0; i < analysisBarCount; i++) {
            Candle candle = chartData.GetCandle(PERIOD_D1, i);
            
            if (candle.close == 0) break;
            
            // Calculate candle characteristics
            double body = MathAbs(candle.close - candle.open);
            double range = candle.high - candle.low;
            double wickSize = 0;
            
            // Calculate wick sizes
            if (candle.close > candle.open) {
                // Bullish candle
                double upperWick = candle.high - candle.close;
                double lowerWick = candle.open - candle.low;
                wickSize = MathMax(upperWick, lowerWick);
            } else {
                // Bearish candle
                double upperWick = candle.high - candle.open;
                double lowerWick = candle.close - candle.low;
                wickSize = MathMax(upperWick, lowerWick);
            }
            
            totalBody += body;
            totalRange += range;
            
            // ─────────────────────────────────────────────────────────────
            // CLASSIFY CANDLE
            // ─────────────────────────────────────────────────────────────
            
            // Strong candle: Large body, small wicks, good direction
            if (body > atr * 0.8 && wickSize < body * 0.3) {
                strongCandleCount++;
            }
            // Weak candle: Small body, large wicks, indecision
            else if (body < atr * 0.4 || wickSize > body) {
                weakCandleCount++;
            }
        }
        
        result.averageCandleBody = totalBody / analysisBarCount;
        result.averageCandleRange = totalRange / analysisBarCount;
        
        // ─────────────────────────────────────────────────────────────────
        // DETERMINE STATE
        // ─────────────────────────────────────────────────────────────────
        
        // Impulse: Strong candles dominate, momentum confirmed
        if (strongCandleCount >= 6 && result.momentum > atr) {
            result.state = STATE_IMPULSE;
            result.momentumConfirmed = true;
        }
        // Correction: Weak candles dominate, low momentum
        else if (weakCandleCount >= 6 || result.averageCandleBody < atr * 0.5) {
            result.state = STATE_CORRECTION;
            result.momentumConfirmed = false;
        }
        // Uncertain
        else {
            result.state = STATE_UNKNOWN;
            result.momentumConfirmed = false;
        }
        
        // ─────────────────────────────────────────────────────────────────
        // TRACK STATE DURATION
        // ─────────────────────────────────────────────────────────────────
        
        if (result.state != lastState) {
            lastStateChangeBar = 0;
            lastState = result.state;
        } else {
            lastStateChangeBar++;
        }
        
        result.barsSinceStateChange = lastStateChangeBar;
        
        return result;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // IMPULSE CONFIRMATION
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Verify impulse state is confirmed
     * Multiple conditions must be met
     */
    bool ImpulseConfirmed(DailyState state, int confirmationBars = 3) {
        if (state.state != STATE_IMPULSE) {
            return false;
        }
        
        // Impulse must last at least 3 bars
        if (state.barsSinceStateChange < confirmationBars) {
            return false;
        }
        
        // Momentum must be confirmed
        if (!state.momentumConfirmed) {
            return false;
        }
        
        // Average candle body must be substantial
        if (state.averageCandleBody < state.momentum * 0.5) {
            return false;
        }
        
        return true;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // CORRECTION CONFIRMATION
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Verify correction state is confirmed
     */
    bool CorrectionConfirmed(DailyState state, int confirmationBars = 3) {
        if (state.state != STATE_CORRECTION) {
            return false;
        }
        
        // Correction must last at least 3 bars
        if (state.barsSinceStateChange < confirmationBars) {
            return false;
        }
        
        // Average candle body must be small
        if (state.averageCandleBody > state.momentum * 0.7) {
            return false;
        }
        
        // Range must be tight
        if (state.averageCandleRange > state.momentum * 1.5) {
            return false;
        }
        
        return true;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // STATE TRANSITION CHECK
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Check if state is transitioning
     * Returns true if state just changed
     */
    bool IsStateTransitioning(DailyState state, int bars = 1) {
        return state.barsSinceStateChange <= bars;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET EXPECTED MOVE
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Calculate expected move based on state
     * Impulse = larger move expected
     * Correction = smaller move expected
     */
    double GetExpectedMove(DailyState state) {
        if (state.state == STATE_IMPULSE) {
            return state.momentum * 1.5;  // Expect 1.5x ATR move
        } else if (state.state == STATE_CORRECTION) {
            return state.momentum * 0.5;  // Expect 0.5x ATR move
        } else {
            return state.momentum;        // Standard ATR move
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // GET RISK MULTIPLIER
    // ─────────────────────────────────────────────────────────────────────
    
    /**
     * Get risk multiplier based on state
     * Use for position sizing adjustments
     */
    double GetRiskMultiplier(DailyState state) {
        // In impulse: High confidence, can risk more
        if (state.state == STATE_IMPULSE && state.momentumConfirmed) {
            return 1.5;  // 150% of normal risk
        }
        // In correction: Low confidence, risk less
        else if (state.state == STATE_CORRECTION) {
            return 0.75;  // 75% of normal risk
        }
        // Uncertain: Minimal risk
        else {
            return 0.5;   // 50% of normal risk
        }
    }
};

#endif  // __IMPULSECORRECTION_MQH__

// ═══════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE:
// ═══════════════════════════════════════════════════════════════════════
//
// ImpulseCorrectionAnalyzer analyzer("EURUSD");
//
// // Detect daily state
// DailyState dailyState = analyzer.DetectDailyState();
//
// if (dailyState.state == STATE_IMPULSE) {
//     Print("Daily is in IMPULSE");
//     Print("Momentum: ", dailyState.momentum);
//     Print("Avg candle body: ", dailyState.averageCandleBody);
//     
//     if (analyzer.ImpulseConfirmed(dailyState)) {
//         Print("✓ Impulse is CONFIRMED");
//         double expectedMove = analyzer.GetExpectedMove(dailyState);
//         Print("Expected move: ", expectedMove);
//     }
// }
// else if (dailyState.state == STATE_CORRECTION) {
//     Print("Daily is in CORRECTION");
//     double riskMult = analyzer.GetRiskMultiplier(dailyState);
//     Print("Risk multiplier: ", riskMult);  // Reduce position size
// }
// else {
//     Print("Daily state UNKNOWN - No trading");
// }
// ═══════════════════════════════════════════════════════════════════════
