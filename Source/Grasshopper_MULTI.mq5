// ═══════════════════════════════════════════════════════════════════════
// GRASSHOPPER EXPERT ADVISOR v1.0 - MULTI-SYMBOL VERSION
// ═══════════════════════════════════════════════════════════════════════
// 
// Strategy: Multi-timeframe analysis + AUTOMATIC TRADING across MULTIPLE SYMBOLS
// Trade: EURUSD, GBPUSD, USDJPY, AUDUSD, NZDUSD, USDCAD, and more!
// 
// Author: Grasshopper Trading System
// Created: April 2026
// Purpose: Automated multi-symbol trading system
//
// ═══════════════════════════════════════════════════════════════════════

#property copyright "Grasshopper"
#property link      "https://grasshopper-trading.com"
#property version   "1.00"
#property strict
#property description "Multi-Symbol Automated Trading EA - Grasshopper System"

// Include necessary MT5 libraries
#include <Trade\Trade.mqh>

// Include our custom modules
#include "Include\MultiSymbolManager.mqh"

// ═══════════════════════════════════════════════════════════════════════
// EA INPUTS
// ═══════════════════════════════════════════════════════════════════════

input string    EA_NAME             = "Grasshopper Multi-Symbol EA";
input double    RiskPercentage      = 1.0;           // Risk % per trade
input double    MinRiskRewardRatio  = 1.5;           // Minimum R/R ratio
input int       MaxConcurrentTrades = 2;             // Max open trades per symbol
input int       MagicNumber         = 20260420;      // EA magic number
input int       SlippagePoints      = 10;            // Slippage tolerance

// Multi-Symbol Settings
input bool      Trade_EURUSD        = true;
input bool      Trade_GBPUSD        = true;
input bool      Trade_USDJPY        = true;
input bool      Trade_AUDUSD        = true;
input bool      Trade_NZDUSD        = true;
input bool      Trade_USDCAD        = true;
input bool      Trade_EURGBP        = true;
input bool      Trade_EURJPY        = true;

// ═══════════════════════════════════════════════════════════════════════
// GLOBAL VARIABLES
// ═══════════════════════════════════════════════════════════════════════

MultiSymbolManager  *multiManager;
bool                eaInitialized = false;
int                 lastAnalysisTime = 0;

// ═══════════════════════════════════════════════════════════════════════
// ON INIT
// ═══════════════════════════════════════════════════════════════════════

int OnInit() {
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " " + EA_NAME + " - Initializing... " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    
    // Initialize multi-symbol manager
    multiManager = new MultiSymbolManager(RiskPercentage, MinRiskRewardRatio, MaxConcurrentTrades, MagicNumber);
    
    // Add symbols based on input settings
    if (Trade_EURUSD)  multiManager.AddSymbol("EURUSD", true);
    if (Trade_GBPUSD)  multiManager.AddSymbol("GBPUSD", true);
    if (Trade_USDJPY)  multiManager.AddSymbol("USDJPY", true);
    if (Trade_AUDUSD)  multiManager.AddSymbol("AUDUSD", true);
    if (Trade_NZDUSD)  multiManager.AddSymbol("NZDUSD", true);
    if (Trade_USDCAD)  multiManager.AddSymbol("USDCAD", true);
    if (Trade_EURGBP)  multiManager.AddSymbol("EURGBP", true);
    if (Trade_EURJPY)  multiManager.AddSymbol("EURJPY", true);
    
    // Print initialization info
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " EA INITIALIZED " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    Print("Symbols trading: ", multiManager.GetSymbolCount());
    Print("Risk per trade: ", RiskPercentage, "%");
    Print("Min RR Ratio: ", MinRiskRewardRatio);
    Print(StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " [SUCCESS] Multi-Symbol EA initialized! " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + "\n");
    
    eaInitialized = true;
    return INIT_SUCCEEDED;
}

// ═══════════════════════════════════════════════════════════════════════
// ON TICK - MAIN ANALYSIS LOOP
// ═══════════════════════════════════════════════════════════════════════

void OnTick() {
    
    if (!eaInitialized) return;
    
    // Only analyze once per candle (check every 5 minutes)
    if (lastAnalysisTime == iTime(_Symbol, PERIOD_M5, 0)) return;
    lastAnalysisTime = iTime(_Symbol, PERIOD_M5, 0);
    
    // ═════════════════════════════════════════════════════════════════
    // ANALYZE ALL SYMBOLS AND EXECUTE TRADES
    // ═════════════════════════════════════════════════════════════════
    
    multiManager.AnalyzeAllSymbols();
}

// ═══════════════════════════════════════════════════════════════════════
// ON DEINIT
// ═══════════════════════════════════════════════════════════════════════

void OnDeinit(const int reason) {
    
    if (multiManager != NULL) {
        multiManager.Cleanup();
        delete multiManager;
    }
    
    Print("[INFO] Multi-Symbol EA stopped. Reason: ", GetDeInitReason(reason));
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
