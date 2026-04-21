// ═══════════════════════════════════════════════════════════════════════
// MULTISYMBOLMANAGER.MQH - Multi-Symbol Trading Management
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Manage trading across multiple currency pairs simultaneously
// Features: Trade EURUSD, GBPUSD, USDJPY, AUDUSD, NZDUSD, and more!
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __MULTISYMBOLMANAGER_MQH__
#define __MULTISYMBOLMANAGER_MQH__

#include "ChartData.mqh"
#include "TrendAnalyzer.mqh"
#include "ImpulseCorrection.mqh"
#include "FibonacciLevels.mqh"
#include "PatternRecognizer.mqh"
#include "TradeExecutor.mqh"

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTED SYMBOLS
// ═══════════════════════════════════════════════════════════════════════

struct SymbolConfig {
    string symbol;
    bool enabled;
    double customRisk;  // Can override risk % per symbol
};

// ═══════════════════════════════════════════════════════════════════════
// MULTI-SYMBOL MANAGER CLASS
// ═══════════════════════════════════════════════════════════════════════

class MultiSymbolManager {
private:
    SymbolConfig symbols[20];
    int symbolCount;
    double defaultRisk;
    double minRiskRewardRatio;
    int maxConcurrentTrades;
    int magicNumber;
    
    // Analysis modules for each symbol
    ChartData *chartData[];
    TrendAnalyzer *trendAnalyzer[];
    ImpulseCorrection *impulseCorrection[];
    FibonacciLevels *fibonacciLevels[];
    PatternRecognizer *patternRecognizer[];
    TradeExecutor *executor[];
    
public:
    // Constructor
    MultiSymbolManager(double _risk, double _minRR, int _maxTrades, int _magic) {
        defaultRisk = _risk;
        minRiskRewardRatio = _minRR;
        maxConcurrentTrades = _maxTrades;
        magicNumber = _magic;
        symbolCount = 0;
        
        ArrayResize(chartData, 20);
        ArrayResize(trendAnalyzer, 20);
        ArrayResize(impulseCorrection, 20);
        ArrayResize(fibonacciLevels, 20);
        ArrayResize(patternRecognizer, 20);
        ArrayResize(executor, 20);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ADD SYMBOL FOR TRADING
    // ═════════════════════════════════════════════════════════════════
    void AddSymbol(string symbolName, bool enabled = true, double customRisk = -1) {
        
        if (symbolCount >= 20) {
            Print("[ERROR] Maximum 20 symbols allowed");
            return;
        }
        
        symbols[symbolCount].symbol = symbolName;
        symbols[symbolCount].enabled = enabled;
        symbols[symbolCount].customRisk = (customRisk < 0) ? defaultRisk : customRisk;
        
        // Initialize modules for this symbol
        chartData[symbolCount] = new ChartData();
        trendAnalyzer[symbolCount] = new TrendAnalyzer();
        impulseCorrection[symbolCount] = new ImpulseCorrection();
        fibonacciLevels[symbolCount] = new FibonacciLevels();
        patternRecognizer[symbolCount] = new PatternRecognizer();
        executor[symbolCount] = new TradeExecutor(
            symbolName, 
            symbols[symbolCount].customRisk,
            minRiskRewardRatio,
            maxConcurrentTrades,
            magicNumber + symbolCount  // Unique magic for each symbol
        );
        
        Print("[INFO] Symbol added: ", symbolName, " | Risk: ", symbols[symbolCount].customRisk, "%");
        symbolCount++;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ANALYZE ALL SYMBOLS
    // ═════════════════════════════════════════════════════════════════
    void AnalyzeAllSymbols() {
        
        Print("\n[", TimeToString(TimeCurrent()), "] ═══════════════════════════════════════════════");
        Print("[", TimeToString(TimeCurrent()), "] ANALYZING ALL SYMBOLS");
        Print("[", TimeToString(TimeCurrent()), "] ═══════════════════════════════════════════════\n");
        
        for (int i = 0; i < symbolCount; i++) {
            
            if (!symbols[i].enabled) {
                Print("[SKIP] Symbol ", symbols[i].symbol, " is disabled");
                continue;
            }
            
            Print("\n[ANALYSIS] === ", symbols[i].symbol, " ===");
            
            // Analyze this symbol
            AnalyzeSymbol(i);
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ANALYZE SINGLE SYMBOL
    // ═════════════════════════════════════════════════════════════════
    void AnalyzeSymbol(int index) {
        
        string sym = symbols[index].symbol;
        
        // Step 1: Weekly Analysis
        TrendAnalysis weeklyTrend = trendAnalyzer[index].AnalyzeTrend(sym, PERIOD_W1);
        
        if (weeklyTrend.direction == TREND_NEUTRAL) {
            Print("[", sym, "] Weekly trend not established - No trading");
            return;
        }
        
        Print("[", sym, "] Weekly trend: ", 
            (weeklyTrend.direction == TREND_BULLISH ? "BULLISH" : "BEARISH"),
            " | Strength: ", weeklyTrend.strength);
        
        // Step 2: Daily Analysis
        DailyState dailyState = impulseCorrection[index].DetectDailyState(sym, PERIOD_D1);
        
        Print("[", sym, "] Daily state: ", 
            (dailyState.state == IMPULSE ? "IMPULSE" : "CORRECTION"),
            " | Risk Mult: ", dailyState.riskMultiplier);
        
        // Step 3: 4H Analysis
        Pattern4H pattern = patternRecognizer[index].Recognize4HPattern(sym, PERIOD_H4, 2);
        
        if (pattern.type == PATTERN_NONE) {
            Print("[", sym, "] No clear 4H pattern - Waiting");
            return;
        }
        
        Print("[", sym, "] 4H Pattern: ", 
            (pattern.type == PATTERN_CONTINUATION ? "CONTINUATION" : "REVERSAL"));
        
        // Step 4: 1H Analysis
        double high1H = iHigh(sym, PERIOD_H1, 0);
        double low1H = iLow(sym, PERIOD_H1, 0);
        
        FibonacciLevels fibs = fibonacciLevels[index].CalculateFibonacci(
            high1H, low1H, 
            (weeklyTrend.direction == TREND_BULLISH)
        );
        
        Print("[", sym, "] Fib Levels: 38.2%=", fibs.level_382, " 61.8%=", fibs.level_618);
        
        // Step 5: Calculate Confluence & Generate Signal
        double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
        double bid = SymbolInfoDouble(sym, SYMBOL_BID);
        double current = (ask + bid) / 2.0;
        
        int confluenceScore = CalculateConfluenceScore(weeklyTrend, dailyState, pattern, fibs, current);
        
        Print("[", sym, "] Confluence Score: ", confluenceScore, "/100");
        
        // Step 6: Generate and Execute Trade if Conditions Met
        if (confluenceScore >= 60) {
            TradeSignal signal = GenerateTradeSignal(weeklyTrend, dailyState, pattern, fibs, ask, bid);
            
            if (signal.isValid) {
                Print("[SIGNAL] ", sym, " - Direction: ", 
                    (signal.direction == 1 ? "BUY" : "SELL"),
                    " | Confluence: ", confluenceScore);
                
                signal.confluenceScore = confluenceScore;
                
                if (executor[index].ExecuteTrade(signal)) {
                    Print("[SUCCESS] ", sym, " Trade executed!");
                }
            }
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CALCULATE CONFLUENCE SCORE
    // ═════════════════════════════════════════════════════════════════
    int CalculateConfluenceScore(TrendAnalysis &trend, DailyState &state, Pattern4H &pattern,
                                 FibonacciLevels &fibs, double current) {
        
        int score = 0;
        
        // Weekly trend: +30 points
        if (trend.direction != TREND_NEUTRAL) score += 30;
        if (trend.strength >= 4) score += 10;
        
        // Daily state: +25 points
        if (state.state == IMPULSE) score += 25;
        else if (state.state == CORRECTION) score += 15;
        
        // 4H pattern: +25 points
        if (pattern.type == PATTERN_CONTINUATION) score += 25;
        else if (pattern.type == PATTERN_REVERSAL) score += 15;
        
        // Fibonacci confirmation: +20 points
        if (fibs.near382 || fibs.near618) score += 20;
        
        return MathMin(score, 100);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GENERATE TRADE SIGNAL
    // ═════════════════════════════════════════════════════════════════
    TradeSignal GenerateTradeSignal(TrendAnalysis &trend, DailyState &state, Pattern4H &pattern,
                                    FibonacciLevels &fibs, double ask, double bid) {
        
        TradeSignal signal;
        signal.isValid = false;
        signal.entryPrice = 0;
        signal.stopLoss = 0;
        signal.takeProfit1 = 0;
        signal.takeProfit2 = 0;
        signal.lotSize = 0;
        signal.direction = 0;
        signal.reason = "";
        
        // Determine direction
        if (trend.direction == TREND_BULLISH && pattern.type == PATTERN_CONTINUATION) {
            signal.direction = 1;  // BUY
            signal.entryPrice = ask;
            signal.stopLoss = ask - (50 * Point());
            signal.takeProfit1 = ask + (75 * Point());
            signal.takeProfit2 = ask + (150 * Point());
            signal.reason = "Bullish trend + Continuation pattern";
            
        } else if (trend.direction == TREND_BEARISH && pattern.type == PATTERN_CONTINUATION) {
            signal.direction = -1;  // SELL
            signal.entryPrice = bid;
            signal.stopLoss = bid + (50 * Point());
            signal.takeProfit1 = bid - (75 * Point());
            signal.takeProfit2 = bid - (150 * Point());
            signal.reason = "Bearish trend + Continuation pattern";
        }
        
        if (signal.direction != 0) {
            signal.isValid = true;
        }
        
        return signal;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GET SYMBOL COUNT
    // ═════════════════════════════════════════════════════════════════
    int GetSymbolCount() {
        return symbolCount;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GET SYMBOL NAME
    // ═════════════════════════════════════════════════════════════════
    string GetSymbolName(int index) {
        if (index >= 0 && index < symbolCount) {
            return symbols[index].symbol;
        }
        return "";
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ENABLE/DISABLE SYMBOL
    // ═════════════════════════════════════════════════════════════════
    void SetSymbolEnabled(int index, bool enabled) {
        if (index >= 0 && index < symbolCount) {
            symbols[index].enabled = enabled;
            Print("[INFO] Symbol ", symbols[index].symbol, " ", 
                (enabled ? "ENABLED" : "DISABLED"));
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CLEANUP
    // ═════════════════════════════════════════════════════════════════
    void Cleanup() {
        for (int i = 0; i < symbolCount; i++) {
            if (chartData[i] != NULL) delete chartData[i];
            if (trendAnalyzer[i] != NULL) delete trendAnalyzer[i];
            if (impulseCorrection[i] != NULL) delete impulseCorrection[i];
            if (fibonacciLevels[i] != NULL) delete fibonacciLevels[i];
            if (patternRecognizer[i] != NULL) delete patternRecognizer[i];
            if (executor[i] != NULL) delete executor[i];
        }
    }
};

#endif
