// ═══════════════════════════════════════════════════════════════════════
// GRASSHOPPER EXPERT ADVISOR v3.0 - UNIVERSAL FINAL VERSION
// ═══════════════════════════════════════════════════════════════════════
// 
// Strategy: Advanced Multi-Timeframe Confirmation + Universal Symbols
// Works with: Forex, Indices (DAX, FTSE, etc), Stocks, Commodities, Crypto
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
#property description "Universal Multi-Symbol EA - Works with Forex, Indices (DAX), Stocks, Commodities, Crypto"

// Include necessary MT5 libraries
#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>

// ═══════════════════════════════════════════════════════════════════════
// EA INPUTS
// ═══════════════════════════════════════════════════════════════════════

input string    EA_NAME             = "Grasshopper Universal EA";
input double    RiskPercentage      = 1.0;           // Risk % per trade
input double    MinRiskRewardRatio  = 1.5;           // Minimum R/R ratio
input int       MaxConcurrentTrades = 2;             // Max open trades
input int       MagicNumber         = 20260425;      // EA magic number
input int       SlippagePoints      = 10;            // Slippage tolerance
input int       MinConfluenceScore  = 50;            // Minimum confluence (0-100)
input int       MinTimeframeConfirms= 3;             // Minimum confirmations (3-5)
input double    MaxSpreadPoints     = 5.0;           // Max acceptable spread
input bool      EnableAutoAdjust    = true;          // Auto-adjust for symbol type

// ═══════════════════════════════════════════════════════════════════════
// GLOBAL VARIABLES
// ═══════════════════════════════════════════════════════════════════════

CTrade                  tradeManager;
bool                    eaInitialized = false;
int                     lastAnalysisTime = 0;
double                  point_value;
int                     digits;
string                  symbol_type = "Unknown";

// ═══════════════════════════════════════════════════════════════════════
// ON INIT
// ═══════════════════════════════════════════════════════════════════════

int OnInit() {
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " " + EA_NAME + " - Initializing... " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    
    // Get symbol info
    point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Detect symbol type
    DetectSymbolType();
    
    // Validate symbol is tradeable
    if (!SymbolSelect(_Symbol, true)) {
        Print("[ERROR] Symbol ", _Symbol, " is not available!");
        return INIT_FAILED;
    }
    
    // Initialize trade manager
    tradeManager.SetExpertMagicNumber(MagicNumber);
    tradeManager.SetDeviationInPoints(SlippagePoints);
    
    // Print initialization info
    Print("\n" + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " EA INITIALIZED " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37));
    Print("Symbol: ", _Symbol);
    Print("Symbol Type: ", symbol_type);
    Print("Risk per trade: ", RiskPercentage, "%");
    Print("Min RR Ratio: ", MinRiskRewardRatio);
    Print("Min Confluence: ", MinConfluenceScore);
    Print("Auto Adjust: ", (EnableAutoAdjust ? "YES" : "NO"));
    Print(StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + " [SUCCESS] Universal EA ready! " + StringFormat("%c%c%c%c%c", 37, 37, 37, 37, 37) + "\n");
    
    eaInitialized = true;
    return INIT_SUCCEEDED;
}

// ═══════════════════════════════════════════════════════════════════════
// DETECT SYMBOL TYPE
// ═══════════════════════════════════════════════════════════════════════

void DetectSymbolType() {
    string upper_sym = StringToUpper(_Symbol);
    
    // INDICES
    if (upper_sym == "DAX" || upper_sym == "CAC" || upper_sym == "FTSE" || 
        upper_sym == "ASX" || upper_sym == "NIKKEI" || upper_sym == "HSI" ||
        upper_sym == "SENSEX" || upper_sym == "MIB" || upper_sym == "IBEX" ||
        StringFind(upper_sym, "SP500") >= 0 || StringFind(upper_sym, "NASDAQ") >= 0 ||
        StringFind(upper_sym, "DOW") >= 0 || StringFind(upper_sym, "NDX") >= 0) {
        symbol_type = "INDEX";
        return;
    }
    
    // COMMODITIES
    if (StringFind(upper_sym, "XAU") >= 0 || StringFind(upper_sym, "XAG") >= 0 ||
        StringFind(upper_sym, "OIL") >= 0 || StringFind(upper_sym, "GAS") >= 0 ||
        StringFind(upper_sym, "COPPER") >= 0 || StringFind(upper_sym, "WHEAT") >= 0) {
        symbol_type = "COMMODITY";
        return;
    }
    
    // CRYPTOCURRENCIES
    if (StringFind(upper_sym, "BTC") >= 0 || StringFind(upper_sym, "ETH") >= 0 ||
        StringFind(upper_sym, "DOGE") >= 0 || StringFind(upper_sym, "XRP") >= 0) {
        symbol_type = "CRYPTO";
        return;
    }
    
    // FOREX (6 chars with currency codes)
    if (StringLen(_Symbol) == 6) {
        symbol_type = "FOREX";
        return;
    }
    
    // DEFAULT: STOCK or FOREX
    symbol_type = "STOCK/FOREX";
}

// ═══════════════════════════════════════════════════════════════════════
// ON TICK - MAIN ANALYSIS LOOP
// ═══════════════════════════════════════════════════════════════════════

void OnTick() {
    
    if (!eaInitialized) return;
    
    // Only analyze once per candle (on M5)
    if (lastAnalysisTime == iTime(_Symbol, PERIOD_M5, 0)) return;
    lastAnalysisTime = iTime(_Symbol, PERIOD_M5, 0);
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK SPREAD
    // ═════════════════════════════════════════════════════════════════
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double spread = ask - bid;
    
    if (spread > MaxSpreadPoints * point_value) {
        return; // Spread too high, skip
    }
    
    // ═════════════════════════════════════════════════════════════════
    // MULTI-TIMEFRAME ANALYSIS
    // ═════════════════════════════════════════════════════════════════
    
    Print("\n[", TimeToString(TimeCurrent()), "] === ANALYZING ", _Symbol, " ===");
    
    // WEEKLY ANALYSIS
    double weeklyHigh = iHigh(_Symbol, PERIOD_W1, 0);
    double weeklyLow = iLow(_Symbol, PERIOD_W1, 0);
    double weeklyClose = iClose(_Symbol, PERIOD_W1, 0);
    
    int weeklyTrend = 0;  // 0=neutral, 1=up, -1=down
    if (weeklyClose > weeklyHigh) weeklyTrend = 1;
    else if (weeklyClose < weeklyLow) weeklyTrend = -1;
    
    Print("[W1] Weekly Close: ", weeklyClose, " | High: ", weeklyHigh, " | Low: ", weeklyLow);
    
    // DAILY ANALYSIS
    double dailyHigh = iHigh(_Symbol, PERIOD_D1, 0);
    double dailyLow = iLow(_Symbol, PERIOD_D1, 0);
    double dailyClose = iClose(_Symbol, PERIOD_D1, 0);
    
    int dailyTrend = 0;
    if (dailyClose > dailyHigh) dailyTrend = 1;
    else if (dailyClose < dailyLow) dailyTrend = -1;
    
    Print("[D1] Daily Close: ", dailyClose, " | High: ", dailyHigh, " | Low: ", dailyLow);
    
    // 4H ANALYSIS
    double h4High = iHigh(_Symbol, PERIOD_H4, 0);
    double h4Low = iLow(_Symbol, PERIOD_H4, 0);
    double h4Close = iClose(_Symbol, PERIOD_H4, 0);
    
    int h4Trend = 0;
    if (h4Close > h4High) h4Trend = 1;
    else if (h4Close < h4Low) h4Trend = -1;
    
    Print("[H4] 4H Close: ", h4Close, " | High: ", h4High, " | Low: ", h4Low);
    
    // 1H ANALYSIS
    double h1High = iHigh(_Symbol, PERIOD_H1, 0);
    double h1Low = iLow(_Symbol, PERIOD_H1, 0);
    double h1Close = iClose(_Symbol, PERIOD_H1, 0);
    
    int h1Trend = 0;
    if (h1Close > h1High) h1Trend = 1;
    else if (h1Close < h1Low) h1Trend = -1;
    
    Print("[H1] 1H Close: ", h1Close, " | High: ", h1High, " | Low: ", h1Low);
    
    // 5M ANALYSIS
    double m5High = iHigh(_Symbol, PERIOD_M5, 0);
    double m5Low = iLow(_Symbol, PERIOD_M5, 0);
    double m5Close = iClose(_Symbol, PERIOD_M5, 0);
    
    int m5Trend = 0;
    if (m5Close > m5High) m5Trend = 1;
    else if (m5Close < m5Low) m5Trend = -1;
    
    Print("[M5] 5M Close: ", m5Close, " | High: ", m5High, " | Low: ", m5Low);
    
    // ═════════════════════════════════════════════════════════════════
    // CONFLUENCE CALCULATION
    // ═════════════════════════════════════════════════════════════════
    
    int confirmations = 0;
    int confluenceScore = 0;
    int signal_direction = 0; // 1=BUY, -1=SELL
    
    // Check if all align (confluence)
    if (dailyTrend == h4Trend && h4Trend == h1Trend && h1Trend == m5Trend && dailyTrend != 0) {
        confirmations = 4; // Daily + 4H + 1H + 5M
        confluenceScore = 80;
        signal_direction = dailyTrend;
        
        Print("\n[STRONG SIGNAL] All 4 timeframes align!");
        Print("[Confirmations] ", confirmations, "/5");
        Print("[Confluence Score] ", confluenceScore, "/100");
        Print("[Direction] ", (signal_direction == 1 ? "BUY" : "SELL"));
    }
    else if (dailyTrend != 0 && h4Trend == h1Trend && h1Trend == dailyTrend) {
        confirmations = 3; // Daily + 4H + 1H
        confluenceScore = 65;
        signal_direction = dailyTrend;
        
        Print("\n[GOOD SIGNAL] Daily + 4H + 1H align");
        Print("[Confirmations] ", confirmations, "/5");
        Print("[Confluence Score] ", confluenceScore, "/100");
    }
    else if (dailyTrend != 0 && h4Trend == dailyTrend) {
        confirmations = 2;
        confluenceScore = 50;
        signal_direction = dailyTrend;
        Print("\n[WEAK SIGNAL] Daily + 4H align");
    }
    else {
        Print("\n[NO SIGNAL] Not enough confluence");
        return;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK REQUIREMENTS
    // ═════════════════════════════════════════════════════════════════
    
    if (confirmations < MinTimeframeConfirms) {
        Print("[SKIP] Not enough confirmations (", confirmations, " < ", MinTimeframeConfirms, ")");
        return;
    }
    
    if (confluenceScore < MinConfluenceScore) {
        Print("[SKIP] Confluence too low (", confluenceScore, " < ", MinConfluenceScore, ")");
        return;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ADJUST PARAMETERS FOR SYMBOL TYPE
    // ═════════════════════════════════════════════════════════════════
    
    double sl_pips = 50;
    double tp_pips = 100;
    
    if (EnableAutoAdjust) {
        if (symbol_type == "INDEX") {
            sl_pips = 35;  // 30% tighter
            tp_pips = 70;
            Print("[ADJUST] Index: Using tighter stops");
        }
        else if (symbol_type == "COMMODITY") {
            sl_pips = 65;  // 30% wider
            tp_pips = 130;
            Print("[ADJUST] Commodity: Using wider stops");
        }
        else if (symbol_type == "CRYPTO") {
            sl_pips = 75;  // 50% wider
            tp_pips = 150;
            Print("[ADJUST] Crypto: Using extra wide stops");
        }
        else if (symbol_type == "STOCK/FOREX") {
            sl_pips = 60;  // 20% wider
            tp_pips = 120;
            Print("[ADJUST] Stock: Using wider stops");
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // EXECUTE TRADE
    // ═════════════════════════════════════════════════════════════════
    
    if (signal_direction == 1) {
        // BUY SIGNAL
        double entry = ask;
        double stoploss = entry - (sl_pips * point_value);
        double takeprofit = entry + (tp_pips * point_value);
        
        double lot_size = CalculateLotSize(entry, stoploss);
        
        Print("\n[BUY ORDER]");
        Print("Entry: ", entry);
        Print("Stop Loss: ", stoploss);
        Print("Take Profit: ", takeprofit);
        Print("Lot Size: ", lot_size);
        
        if (tradeManager.Buy(lot_size, _Symbol, entry, stoploss, takeprofit, "Grasshopper Buy")) {
            Print("[SUCCESS] Buy order placed!");
        } else {
            Print("[FAILED] Buy order failed! Error: ", GetLastError());
        }
    }
    else if (signal_direction == -1) {
        // SELL SIGNAL
        double entry = bid;
        double stoploss = entry + (sl_pips * point_value);
        double takeprofit = entry - (tp_pips * point_value);
        
        double lot_size = CalculateLotSize(entry, stoploss);
        
        Print("\n[SELL ORDER]");
        Print("Entry: ", entry);
        Print("Stop Loss: ", stoploss);
        Print("Take Profit: ", takeprofit);
        Print("Lot Size: ", lot_size);
        
        if (tradeManager.Sell(lot_size, _Symbol, entry, stoploss, takeprofit, "Grasshopper Sell")) {
            Print("[SUCCESS] Sell order placed!");
        } else {
            Print("[FAILED] Sell order failed! Error: ", GetLastError());
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// CALCULATE LOT SIZE
// ═══════════════════════════════════════════════════════════════════════

double CalculateLotSize(double entry_price, double stop_loss) {
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPercentage / 100.0);
    
    double pips = MathAbs(entry_price - stop_loss) / point_value;
    if (pips == 0) pips = 1;
    
    double lot_size = risk_amount / (pips * 10.0);
    
    // Get symbol limits
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Normalize
    lot_size = MathRound(lot_size / lot_step) * lot_step;
    
    // Clamp to limits
    if (lot_size < min_lot) lot_size = min_lot;
    if (lot_size > max_lot) lot_size = max_lot;
    
    return lot_size;
}

// ═══════════════════════════════════════════════════════════════════════
// ON DEINIT
// ═══════════════════════════════════════════════════════════════════════

void OnDeinit(const int reason) {
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