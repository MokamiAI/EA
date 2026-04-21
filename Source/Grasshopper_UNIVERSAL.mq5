// ═══════════════════════════════════════════════════════════════════════
// GRASSHOPPER EXPERT ADVISOR v3.0 - UNIVERSAL SYMBOL VERSION
// ═══════════════════════════════════════════════════════════════════════
// 
// Strategy: Advanced Multi-Timeframe Confirmation + UNIVERSAL SYMBOLS
// Works with: Forex, Indices, Stocks, Commodities, Cryptocurrencies
// 
// Author: Grasshopper Trading System
// Created: April 2026
// Purpose: Trade ANY symbol with intelligent multi-timeframe confirmation
//
// ═══════════════════════════════════════════════════════════════════════

#property copyright "Grasshopper"
#property link      "https://grasshopper-trading.com"
#property version   "3.00"
#property strict
#property description "Universal Multi-Symbol Automated Trading EA - Works with Indices, Stocks, Commodities, Forex, Crypto"

// Include necessary MT5 libraries
#include <Trade\Trade.mqh>

// Include our custom modules
#include "Include\UniversalSymbolAdapter.mqh"
#include "Include\AdvancedConfirmation.mqh"
#include "Include\TradeExecutor.mqh"

// ═══════════════════════════════════════════════════════════════════════
// EA INPUTS
// ═══════════════════════════════════════════════════════════════════════

input string    EA_NAME             = "Grasshopper Universal EA";
input double    RiskPercentage      = 1.0;           // Risk % per trade
input double    MinRiskRewardRatio  = 1.5;           // Minimum R/R ratio
input int       MaxConcurrentTrades = 2;             // Max open trades
input int       MagicNumber         = 20260422;      // EA magic number
input int       SlippagePoints      = 10;            // Slippage tolerance
input int       MinConfluenceScore  = 50;            // Minimum confluence score
input int       MinTimeframeConfirms= 3;             // Minimum confirmations needed
input double    MaxSpreadPoints     = 5.0;           // Maximum acceptable spread

// ═══════════════════════════════════════════════════════════════════════
// GLOBAL VARIABLES
// ═══════════════════════════════════════════════════════════════════════

UniversalSymbolAdapter  *symbolAdapter;
AdvancedConfirmation    *advancedAnalyzer;
TradeExecutor           *executor;
CTrade                  tradeManager;
bool                    eaInitialized = false;
int                     lastAnalysisTime = 0;
SymbolInfo              currentSymbolInfo;

// ═══════════════════════════════════════════════════════════════════════
// ON INIT
// ═══════════════════════════════════════════════════════════════════════

int OnInit() {
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " " + EA_NAME + " - Initializing... " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    
    // Initialize symbol adapter
    symbolAdapter = new UniversalSymbolAdapter(_Symbol);
    currentSymbolInfo = symbolAdapter.GetSymbolInfo();
    
    // Check if symbol is tradeable
    if (!symbolAdapter.IsSymbolTradeable()) {
        Print("[ERROR] Symbol ", _Symbol, " is not tradeable on this broker!");
        return INIT_FAILED;
    }
    
    // Initialize modules
    advancedAnalyzer = new AdvancedConfirmation(_Symbol);
    executor = new TradeExecutor(_Symbol, RiskPercentage, MinRiskRewardRatio, MaxConcurrentTrades, MagicNumber);
    
    // Initialize trade manager
    tradeManager.SetExpertMagicNumber(MagicNumber);
    tradeManager.SetDeviationInPoints(SlippagePoints);
    
    // Print initialization info
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " EA INITIALIZED " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    Print("Symbol: ", _Symbol, " (", symbolAdapter.GetSymbolTypeName(), ")");
    Print("Risk per trade: ", RiskPercentage, "%");
    Print("Min RR Ratio: ", MinRiskRewardRatio);
    Print("Min Timeframe Confirmations: ", MinTimeframeConfirms, "/5");
    Print("Min Confluence Score: ", MinConfluenceScore);
    Print("Max Acceptable Spread: ", MaxSpreadPoints, " points");
    Print(StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " [SUCCESS] Universal EA initialized! " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + "\n");
    
    eaInitialized = true;
    return INIT_SUCCEEDED;
}

// ═══════════════════════════════════════════════════════════════════════
// ON TICK - MAIN ANALYSIS LOOP
// ═══════════════════════════════════════════════════════════════════════

void OnTick() {
    
    if (!eaInitialized) return;
    
    // Only analyze once per candle
    if (lastAnalysisTime == iTime(_Symbol, PERIOD_M5, 0)) return;
    lastAnalysisTime = iTime(_Symbol, PERIOD_M5, 0);
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK SPREAD
    // ═════════════════════════════════════════════════════════════════
    
    if (!symbolAdapter.IsSpreadAcceptable(MaxSpreadPoints)) {
        Print("[SKIP] Spread too high - waiting for better conditions");
        return;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ADVANCED MULTI-TIMEFRAME ANALYSIS
    // ═════════════════════════════════════════════════════════════════
    
    ConfirmationSignal signal = advancedAnalyzer.AnalyzeAllTimeframes();
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK IF SIGNAL MEETS MINIMUM REQUIREMENTS
    // ═════════════════════════════════════════════════════════════════
    
    if (!signal.canTrade) {
        return;
    }
    
    if (signal.totalConfirmations < MinTimeframeConfirms) {
        return;
    }
    
    if (signal.confluenceScore < MinConfluenceScore) {
        return;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ADJUST PARAMETERS FOR SYMBOL TYPE
    // ═════════════════════════════════════════════════════════════════
    
    double stop_loss = signal.stopLoss;
    double take_profit = signal.takeProfit;
    
    symbolAdapter.AdjustParametersForSymbolType(stop_loss, take_profit);
    
    // ═════════════════════════════════════════════════════════════════
    // CREATE AND EXECUTE TRADE
    // ═════════════════════════════════════════════════════════════════
    
    TradeSignal tradeSignal;
    tradeSignal.isValid = true;
    tradeSignal.direction = signal.direction;
    tradeSignal.entryPrice = signal.entryPrice;
    tradeSignal.stopLoss = stop_loss;
    tradeSignal.takeProfit1 = take_profit;
    tradeSignal.takeProfit2 = take_profit + (50 * Point());
    tradeSignal.confluenceScore = signal.confluenceScore;
    tradeSignal.reason = "Multi-timeframe confluence: D1+H4+H1 confirmed (" + 
                         symbolAdapter.GetSymbolTypeName() + ")";
    
    Print("\n[EXECUTING TRADE]");
    Print("[Symbol Type: ", symbolAdapter.GetSymbolTypeName(), "]");
    Print("[Confirmations: ", signal.totalConfirmations, "/5]");
    Print("[Confluence Score: ", signal.confluenceScore, "/100]");
    Print("[Direction: ", (signal.direction == 1 ? "BUY" : "SELL"), "]");
    Print("[Adjusted SL: ", tradeSignal.stopLoss, " | TP: ", tradeSignal.takeProfit1, "]");
    
    if (executor.ExecuteTrade(tradeSignal)) {
        Print("[SUCCESS] Trade executed automatically on ", _Symbol, "!");
    } else {
        Print("[FAILED] Trade execution failed on ", _Symbol);
    }
}

// ═══════════════════════════════════════════════════════════════════════
// ON DEINIT
// ═══════════════════════════════════════════════════════════════════════

void OnDeinit(const int reason) {
    
    if (symbolAdapter != NULL) delete symbolAdapter;
    if (advancedAnalyzer != NULL) {
        advancedAnalyzer.Cleanup();
        delete advancedAnalyzer;
    }
    if (executor != NULL) delete executor;
    
    Print("[INFO] Universal EA stopped on ", _Symbol, ". Reason: ", GetDeInitReason(reason));
}

// ═══════════════════════════════════════════════════════════════════════
// GET DEINIT REASON
// ═══════════════════════════════════════════════════════════════════════

string GetDeInitReason(int reason) {
    switch (reason) {
        case REASON_ACCOUNT: return "Account deleted";
        case REASON_RECOMPILE: return "Program recompiled";
        case REASON_CHARTCHANGE: return "Chart change";
        case REASON_CHARTCLOSE: return "Chart closed";
        case REASON_PARAMETERS: return "Parameters changed";
        case REASON_DAYFILTER: return "Day filter";
        case REASON_REMOVE: return "EA removed";
        case REASON_TEMPLATE: return "Template changed";
        case REASON_INITFAILED: return "OnInit failed";
        case REASON_CLOSE: return "Terminal closed";
        default: return "Unknown";
    }
}
