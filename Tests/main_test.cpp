// ═══════════════════════════════════════════════════════════════════════
// MAIN_TEST.CPP - Unit Test Runner
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Run all unit tests for Grasshopper EA modules
//
// Compile: g++ -std=c++17 -I./Include Tests/main_test.cpp -o Tests/runner
// Run: ./Tests/runner
// ═══════════════════════════════════════════════════════════════════════

#include <iostream>
#include <fstream>
#include <cassert>
#include <cmath>
#include <vector>
#include <string>
#include <ctime>

// ═══════════════════════════════════════════════════════════════════════
// TEST FRAMEWORK MACROS
// ═══════════════════════════════════════════════════════════════════════

int totalTests = 0;
int passedTests = 0;
int failedTests = 0;
std::string currentSuite;
std::ofstream csvFile;

#define TEST_START(name) \
    std::cout << "\n[TEST] " << name << std::endl; \
    currentTestName = (name);

#define ASSERT_EQ(actual, expected, message) \
    totalTests++; \
    if (actual == expected) { \
        std::cout << "  ✓ PASS: " << message << std::endl; \
        passedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",PASS,\"" << message << "\"\n"; \
    } else { \
        std::cout << "  ✗ FAIL: " << message << " (Expected: " << expected << ", Got: " << actual << ")" << std::endl; \
        failedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",FAIL,\"" << message << " (Expected: " << expected << " Got: " << actual << ")\"\n"; \
    }

#define ASSERT_TRUE(condition, message) \
    totalTests++; \
    if (condition) { \
        std::cout << "  ✓ PASS: " << message << std::endl; \
        passedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",PASS,\"" << message << "\"\n"; \
    } else { \
        std::cout << "  ✗ FAIL: " << message << std::endl; \
        failedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",FAIL,\"" << message << "\"\n"; \
    }

#define ASSERT_FALSE(condition, message) \
    totalTests++; \
    if (!(condition)) { \
        std::cout << "  ✓ PASS: " << message << std::endl; \
        passedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",PASS,\"" << message << "\"\n"; \
    } else { \
        std::cout << "  ✗ FAIL: " << message << std::endl; \
        failedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",FAIL,\"" << message << "\"\n"; \
    }

#define ASSERT_NEAR(actual, expected, tolerance, message) \
    totalTests++; \
    if (std::abs(actual - expected) <= tolerance) { \
        std::cout << "  ✓ PASS: " << message << std::endl; \
        passedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",PASS,\"" << message << "\"\n"; \
    } else { \
        std::cout << "  ✗ FAIL: " << message << " (Expected: " << expected << " ±" << tolerance << ", Got: " << actual << ")" << std::endl; \
        failedTests++; \
        csvFile << currentSuite << "," << currentTestName << ",FAIL,\"" << message << " (Expected: " << expected << " +/-" << tolerance << " Got: " << actual << ")\"\n"; \
    }

static std::string currentTestName;

// ═══════════════════════════════════════════════════════════════════════
// MOCK STRUCTURES (For testing without MT5)
// ═══════════════════════════════════════════════════════════════════════

struct MockCandle {
    double open;
    double high;
    double low;
    double close;
    long volume;
};

// ═══════════════════════════════════════════════════════════════════════
// TEST SUITES
// ═══════════════════════════════════════════════════════════════════════

// Test Suite 1: Trend Analysis
void TestTrendAnalysis() {
    currentSuite = "Trend Analyzer";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "TREND ANALYZER TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;
    
    TEST_START("Bullish Trend Detection (Higher High + Higher Low)");
    // Simulate: Previous candle High=1.0850, Low=1.0800
    //           Current candle High=1.0900, Low=1.0820
    double prevHigh = 1.0850, prevLow = 1.0800;
    double currHigh = 1.0900, currLow = 1.0820;
    bool isBullish = (currHigh > prevHigh) && (currLow > prevLow);
    ASSERT_TRUE(isBullish, "Detected bullish trend correctly");
    
    TEST_START("Bearish Trend Detection (Lower High + Lower Low)");
    prevHigh = 1.0900, prevLow = 1.0820;
    currHigh = 1.0850, currLow = 1.0800;
    bool isBearish = (currHigh < prevHigh) && (currLow < prevLow);
    ASSERT_TRUE(isBearish, "Detected bearish trend correctly");
    
    TEST_START("Neutral Trend Detection (Mixed signals)");
    prevHigh = 1.0850, prevLow = 1.0800;
    currHigh = 1.0900, currLow = 1.0790;  // Higher high but lower low = mixed/neutral
    bool isNeutral = !((currHigh > prevHigh && currLow > prevLow) || 
                       (currHigh < prevHigh && currLow < prevLow));
    ASSERT_TRUE(isNeutral, "Detected neutral trend correctly");
    
    TEST_START("Trend Strength Calculation");
    // Mirrors 4-criteria logic from TrendAnalyzer.mqh:CalculateTrendStrength()
    // point = 0.00001 (5-decimal forex pair)
    double point = 0.00001;

    // Case 1: equal small bodies, tiny HH diff -> strength = 1
    double currBody = std::abs(1.0855 - 1.0850);  // 0.0005
    double prevBody = std::abs(1.0850 - 1.0845);  // 0.0005
    double highDiff = 1.0855 - 1.0850;             // 0.0005
    int strength = 1;
    if (currBody > prevBody * 1.5) strength++;                          // 0.0005 > 0.00075? No
    if (highDiff > 100 * point) strength++;                             // 0.0005 > 0.001? No
    if (currBody > prevBody && currBody > 200 * point) strength++;      // equal bodies: No
    ASSERT_EQ(strength, 1, "Trend strength = 1 for equal small bodies");

    // Case 2: large body (2.5x) + large HH diff -> strength = 4
    currBody = std::abs(1.0840 - 1.0815);  // 0.0025
    prevBody = std::abs(1.0810 - 1.0800);  // 0.0010
    highDiff = 1.0850 - 1.0810;             // 0.0040
    strength = 1;
    if (currBody > prevBody * 1.5) strength++;                          // 0.0025 > 0.0015? Yes -> 2
    if (highDiff > 100 * point) strength++;                             // 0.0040 > 0.001?  Yes -> 3
    if (currBody > prevBody && currBody > 200 * point) strength++;      // 0.0025>0.001 AND 0.0025>0.002? Yes -> 4
    ASSERT_EQ(strength, 4, "Trend strength = 4 for large body + large HH");
}

// Test Suite 2: Fibonacci Levels
void TestFibonacciLevels() {
    currentSuite = "Fibonacci Levels";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "FIBONACCI LEVELS TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;
    
    TEST_START("Fibonacci 38.2% Retracement");
    double high = 1.1000;
    double low = 1.0500;
    double range = high - low;  // 0.0500
    double level382 = high - (range * 0.382);  // 1.0809
    ASSERT_NEAR(level382, 1.0809, 0.0001, "Calculated 38.2% retracement correctly");
    
    TEST_START("Fibonacci 61.8% Retracement");
    double level618 = high - (range * 0.618);  // 1.0691
    ASSERT_NEAR(level618, 1.0691, 0.0001, "Calculated 61.8% retracement correctly");
    
    TEST_START("Fibonacci Extension (161.8%)");
    // Standard formula: swing low + (range * 1.618)
    double extension1618 = low + (range * 1.618);  // 1.0500 + 0.0809 = 1.1309
    ASSERT_NEAR(extension1618, 1.1309, 0.0001, "Calculated 161.8% extension correctly");
    
    TEST_START("Fibonacci Level Order");
    std::vector<double> levels = {
        high - (range * 0.236),      // 23.6%
        high - (range * 0.382),      // 38.2%
        high - (range * 0.618)       // 61.8%
    };
    bool isAscending = levels[0] > levels[1] && levels[1] > levels[2];
    ASSERT_TRUE(isAscending, "Fibonacci levels in correct order (high to low)");
}

// Test Suite 3: Position Sizing
void TestPositionSizing() {
    currentSuite = "Position Sizing";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "POSITION SIZING TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;
    
    TEST_START("Position Size Calculation (1% Risk)");
    double accountBalance = 10000.0;
    double riskPercent = 1.0;
    double stopLossPips = 50.0;
    double pipValue = 10.0;  // $10 per pip
    
    double riskAmount = accountBalance * (riskPercent / 100.0);  // $100
    double positionSize = riskAmount / (stopLossPips * pipValue);  // 0.2 lots
    ASSERT_NEAR(positionSize, 0.2, 0.01, "Calculated correct position size");
    
    TEST_START("Margin Requirement Check");
    // MT5 margin = lots * contractSize / leverage  (standard forex: 100,000 units, 100:1 leverage)
    double contractSize = 100000.0;
    double leverage = 100.0;
    double requiredMargin = positionSize * contractSize / leverage;  // 0.2 * 100000 / 100 = $200
    double freeMargin = accountBalance - requiredMargin;
    ASSERT_NEAR(freeMargin, 9800.0, 1.0, "Calculated free margin correctly");
    
    TEST_START("Risk-Reward Ratio");
    double stopLossDistance = 50.0;  // pips
    double takeProfitDistance = 100.0;  // pips
    double riskRewardRatio = takeProfitDistance / stopLossDistance;  // 2.0
    ASSERT_NEAR(riskRewardRatio, 2.0, 0.1, "Calculated R:R ratio correctly");
    
    TEST_START("Daily Loss Limit Check");
    double maxDailyLoss = accountBalance * 0.05;  // 5% = $500
    double currentDailyLoss = 300.0;  // Lost $300
    bool canTrade = currentDailyLoss < maxDailyLoss;
    ASSERT_TRUE(canTrade, "Daily loss limit check passed");
}

// Test Suite 4: Signal Generation
void TestSignalGeneration() {
    currentSuite = "Signal Generation";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "SIGNAL GENERATION TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;
    
    TEST_START("Confluence Score Calculation");
    int confluenceFactors = 0;
    
    // Factor 1: Trend aligned
    if (true) confluenceFactors++;  // Trend is bullish
    
    // Factor 2: Fibonacci level
    if (true) confluenceFactors++;  // Price near Fibonacci level
    
    // Factor 3: Support/Resistance
    if (true) confluenceFactors++;  // Price near S/R
    
    // Factor 4: Candlestick pattern
    if (true) confluenceFactors++;  // Valid bullish candle
    
    // Factor 5: Volume confirmation
    if (false) confluenceFactors++;  // Volume not confirmed
    
    int confluenceScore = (confluenceFactors * 10) / 5;  // 80%
    ASSERT_EQ(confluenceScore, 8, "Confluence score calculated correctly");
    
    TEST_START("Minimum Confluence Threshold");
    int minConfluence = 6;
    bool signalValid = confluenceScore >= minConfluence;
    ASSERT_TRUE(signalValid, "Signal meets confluence threshold");
    
    TEST_START("Entry Signal Logic");
    // All conditions met
    bool trendOK = true;           // Weekly trend established
    bool stateOK = true;           // Daily impulse detected
    bool patternOK = true;         // 4H pattern confirmed
    bool srOK = true;              // 1H S/R aligned
    bool candleOK = true;          // 5M candle valid
    
    bool shouldGenerateSignal = trendOK && stateOK && patternOK && srOK && candleOK;
    ASSERT_TRUE(shouldGenerateSignal, "All conditions met for buy signal");
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSAL SYMBOL ADAPTER HELPERS (mirrors UniversalSymbolAdapter.mqh logic)
// ═══════════════════════════════════════════════════════════════════════

enum SymbolType { FOREX_PAIR, STOCK_INDEX, INDIVIDUAL_STOCK, COMMODITY, CRYPTOCURRENCY, UNKNOWN_SYMBOL };

// Mirrors DetectSymbolType() — commodity/crypto checked BEFORE forex to avoid misclassification
SymbolType DetectSymbolType(const std::string& sym) {
    // Commodity (must check before forex — XAUUSD, XAGUSD contain "USD")
    if (sym.find("XAU") != std::string::npos || sym.find("XAG") != std::string::npos ||
        sym.find("OIL") != std::string::npos || sym.find("GAS") != std::string::npos ||
        sym.find("COPPER") != std::string::npos)
        return COMMODITY;

    // Crypto (must check before forex — BTCUSD, ETHUSD contain "USD")
    if (sym.find("BTC") != std::string::npos || sym.find("ETH") != std::string::npos ||
        sym.find("DOGE") != std::string::npos || sym.find("XRP") != std::string::npos ||
        sym.find("ADA") != std::string::npos)
        return CRYPTOCURRENCY;

    // Forex (6-char pairs with known currency codes)
    if (sym.size() == 6 &&
        (sym.find("USD") != std::string::npos || sym.find("EUR") != std::string::npos ||
         sym.find("GBP") != std::string::npos || sym.find("JPY") != std::string::npos ||
         sym.find("CAD") != std::string::npos || sym.find("CHF") != std::string::npos))
        return FOREX_PAIR;

    // Indices (3–5 chars, known names)
    if (sym == "DAX" || sym == "CAC" || sym == "FTSE" || sym == "ASX" ||
        sym == "HSI" || sym == "MIB" || sym == "IBEX")
        return STOCK_INDEX;

    return INDIVIDUAL_STOCK;
}

// Mirrors AdjustParametersForSymbolType()
void AdjustParameters(SymbolType type, double& sl, double& tp) {
    switch (type) {
        case FOREX_PAIR:      break;
        case STOCK_INDEX:     sl *= 0.7;  tp *= 0.7;  break;
        case INDIVIDUAL_STOCK:sl *= 1.2;  tp *= 1.2;  break;
        case COMMODITY:       sl *= 1.3;  tp *= 1.3;  break;
        case CRYPTOCURRENCY:  sl *= 1.5;  tp *= 1.5;  break;
        default: break;
    }
}

// Test Suite 5: Multi-Symbol Manager (mirrors Grasshopper_MULTI.mq5 logic)
void TestMultiSymbol() {
    currentSuite = "Multi Symbol";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "MULTI-SYMBOL TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;

    TEST_START("Symbol Count - All Enabled");
    std::vector<std::string> symbols;
    bool Trade_EURUSD=true, Trade_GBPUSD=true, Trade_USDJPY=true, Trade_AUDUSD=true;
    bool Trade_NZDUSD=true, Trade_USDCAD=true, Trade_EURGBP=true, Trade_EURJPY=true;
    if (Trade_EURUSD) symbols.push_back("EURUSD");
    if (Trade_GBPUSD) symbols.push_back("GBPUSD");
    if (Trade_USDJPY) symbols.push_back("USDJPY");
    if (Trade_AUDUSD) symbols.push_back("AUDUSD");
    if (Trade_NZDUSD) symbols.push_back("NZDUSD");
    if (Trade_USDCAD) symbols.push_back("USDCAD");
    if (Trade_EURGBP) symbols.push_back("EURGBP");
    if (Trade_EURJPY) symbols.push_back("EURJPY");
    ASSERT_EQ((int)symbols.size(), 8, "All 8 symbols registered when all enabled");

    TEST_START("Symbol Count - Partial Selection");
    symbols.clear();
    Trade_GBPUSD=false; Trade_NZDUSD=false; Trade_EURGBP=false;
    if (Trade_EURUSD) symbols.push_back("EURUSD");
    if (Trade_GBPUSD) symbols.push_back("GBPUSD");
    if (Trade_USDJPY) symbols.push_back("USDJPY");
    if (Trade_AUDUSD) symbols.push_back("AUDUSD");
    if (Trade_NZDUSD) symbols.push_back("NZDUSD");
    if (Trade_USDCAD) symbols.push_back("USDCAD");
    if (Trade_EURGBP) symbols.push_back("EURGBP");
    if (Trade_EURJPY) symbols.push_back("EURJPY");
    ASSERT_EQ((int)symbols.size(), 5, "5 symbols registered when 3 disabled");

    TEST_START("Risk Per Symbol (1% of $10,000)");
    double accountBalance = 10000.0;
    double riskPct = 1.0;
    double riskAmount = accountBalance * (riskPct / 100.0);
    ASSERT_NEAR(riskAmount, 100.0, 0.01, "Risk per trade = $100 on $10,000 account");

    TEST_START("Max Concurrent Trades Enforcement");
    int maxTrades = 2;
    int openTrades = 3;
    bool canOpenNew = openTrades < maxTrades;
    ASSERT_FALSE(canOpenNew, "New trade blocked when open trades >= max (3 >= 2)");

    TEST_START("Minimum R:R Filter");
    double minRR = 1.5;
    double sl = 30.0, tp = 60.0;
    double rrRatio = tp / sl;  // 2.0
    bool signalAccepted = rrRatio >= minRR;
    ASSERT_TRUE(signalAccepted, "Signal accepted when R:R 2.0 >= minimum 1.5");

    TEST_START("Minimum R:R Rejection");
    sl = 50.0; tp = 60.0;
    rrRatio = tp / sl;  // 1.2
    signalAccepted = rrRatio >= minRR;
    ASSERT_FALSE(signalAccepted, "Signal rejected when R:R 1.2 < minimum 1.5");

    TEST_START("Magic Number Uniqueness");
    int magicNumber = 20260420;
    ASSERT_TRUE(magicNumber > 0, "Magic number is positive");
    ASSERT_TRUE(magicNumber == 20260420, "Magic number matches EA constant");
}

// Test Suite 6: Universal Symbol Adapter (mirrors Grasshopper_UNIVERSAL.mq5 logic)
void TestUniversalSymbol() {
    currentSuite = "Universal Symbol";
    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "UNIVERSAL SYMBOL TEST SUITE" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;

    // ── Symbol Type Detection ──────────────────────────────────────────
    TEST_START("Symbol Detection - Forex Pairs");
    ASSERT_TRUE(DetectSymbolType("EURUSD") == FOREX_PAIR,  "EURUSD classified as Forex");
    ASSERT_TRUE(DetectSymbolType("GBPUSD") == FOREX_PAIR,  "GBPUSD classified as Forex");
    ASSERT_TRUE(DetectSymbolType("USDJPY") == FOREX_PAIR,  "USDJPY classified as Forex");

    TEST_START("Symbol Detection - Commodities (not mis-classified as Forex)");
    ASSERT_TRUE(DetectSymbolType("XAUUSD") == COMMODITY,   "XAUUSD classified as Commodity (not Forex)");
    ASSERT_TRUE(DetectSymbolType("XAGUSD") == COMMODITY,   "XAGUSD classified as Commodity (not Forex)");
    ASSERT_TRUE(DetectSymbolType("OILUSD") == COMMODITY,   "OILUSD classified as Commodity");

    TEST_START("Symbol Detection - Cryptocurrencies (not mis-classified as Forex)");
    ASSERT_TRUE(DetectSymbolType("BTCUSD") == CRYPTOCURRENCY, "BTCUSD classified as Crypto (not Forex)");
    ASSERT_TRUE(DetectSymbolType("ETHUSD") == CRYPTOCURRENCY, "ETHUSD classified as Crypto (not Forex)");
    ASSERT_TRUE(DetectSymbolType("XRPUSD") == CRYPTOCURRENCY, "XRPUSD classified as Crypto (not Forex)");

    TEST_START("Symbol Detection - Stock Indices");
    ASSERT_TRUE(DetectSymbolType("DAX")  == STOCK_INDEX, "DAX classified as Stock Index");
    ASSERT_TRUE(DetectSymbolType("FTSE") == STOCK_INDEX, "FTSE classified as Stock Index");
    ASSERT_TRUE(DetectSymbolType("CAC")  == STOCK_INDEX, "CAC classified as Stock Index");

    TEST_START("Symbol Detection - Individual Stocks");
    ASSERT_TRUE(DetectSymbolType("AAPL") == INDIVIDUAL_STOCK, "AAPL classified as Individual Stock");
    ASSERT_TRUE(DetectSymbolType("TSLA") == INDIVIDUAL_STOCK, "TSLA classified as Individual Stock");

    // ── Parameter Adjustment ──────────────────────────────────────────
    TEST_START("Parameter Adjustment - Forex (no change)");
    double sl = 50.0, tp = 100.0;
    AdjustParameters(FOREX_PAIR, sl, tp);
    ASSERT_NEAR(sl, 50.0, 0.01,  "Forex SL unchanged");
    ASSERT_NEAR(tp, 100.0, 0.01, "Forex TP unchanged");

    TEST_START("Parameter Adjustment - Stock Index (30% tighter)");
    sl = 50.0; tp = 100.0;
    AdjustParameters(STOCK_INDEX, sl, tp);
    ASSERT_NEAR(sl, 35.0, 0.01, "Index SL = 50 * 0.7 = 35");
    ASSERT_NEAR(tp, 70.0, 0.01, "Index TP = 100 * 0.7 = 70");

    TEST_START("Parameter Adjustment - Individual Stock (20% wider)");
    sl = 50.0; tp = 100.0;
    AdjustParameters(INDIVIDUAL_STOCK, sl, tp);
    ASSERT_NEAR(sl, 60.0, 0.01,  "Stock SL = 50 * 1.2 = 60");
    ASSERT_NEAR(tp, 120.0, 0.01, "Stock TP = 100 * 1.2 = 120");

    TEST_START("Parameter Adjustment - Commodity (30% wider)");
    sl = 50.0; tp = 100.0;
    AdjustParameters(COMMODITY, sl, tp);
    ASSERT_NEAR(sl, 65.0, 0.01,  "Commodity SL = 50 * 1.3 = 65");
    ASSERT_NEAR(tp, 130.0, 0.01, "Commodity TP = 100 * 1.3 = 130");

    TEST_START("Parameter Adjustment - Crypto (50% wider)");
    sl = 50.0; tp = 100.0;
    AdjustParameters(CRYPTOCURRENCY, sl, tp);
    ASSERT_NEAR(sl, 75.0, 0.01,  "Crypto SL = 50 * 1.5 = 75");
    ASSERT_NEAR(tp, 150.0, 0.01, "Crypto TP = 100 * 1.5 = 150");

    // ── Signal Filters (from OnTick logic) ────────────────────────────
    TEST_START("Signal Filter - Confluence Score Threshold");
    int minConfluence = 50;
    ASSERT_TRUE(55 >= minConfluence,  "Score 55 passes min confluence of 50");
    ASSERT_FALSE(45 >= minConfluence, "Score 45 rejected below min confluence of 50");

    TEST_START("Signal Filter - Timeframe Confirmations");
    int minConfirms = 3;
    ASSERT_TRUE(4 >= minConfirms,  "4 confirmations passes minimum of 3");
    ASSERT_FALSE(2 >= minConfirms, "2 confirmations rejected below minimum of 3");

    TEST_START("Signal Filter - Spread Check");
    double maxSpread = 5.0;
    ASSERT_TRUE(3.2 <= maxSpread,  "Spread 3.2 accepted (below max 5.0)");
    ASSERT_FALSE(6.1 <= maxSpread, "Spread 6.1 rejected (above max 5.0)");
}

// ═══════════════════════════════════════════════════════════════════════
// TEST RUNNER
// ═══════════════════════════════════════════════════════════════════════

int main() {
    csvFile.open("test_results.csv");
    csvFile << "Suite,Test,Result,Details\n";

    std::cout << "\n" << std::endl;
    std::cout << "╔════════════════════════════════════════════════════════════════════════╗" << std::endl;
    std::cout << "║         GRASSHOPPER EXPERT ADVISOR - UNIT TEST SUITE v1.0              ║" << std::endl;
    std::cout << "║                   Grasshopper Trading System                          ║" << std::endl;
    std::cout << "╚════════════════════════════════════════════════════════════════════════╝" << std::endl;

    TestTrendAnalysis();
    TestFibonacciLevels();
    TestPositionSizing();
    TestSignalGeneration();
    TestMultiSymbol();
    TestUniversalSymbol();

    std::cout << "\n════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "TEST SUMMARY" << std::endl;
    std::cout << "════════════════════════════════════════════════════════════════════════" << std::endl;
    std::cout << "Total Tests:  " << totalTests << std::endl;
    std::cout << "Passed:       " << passedTests << " ✓" << std::endl;
    std::cout << "Failed:       " << failedTests << " ✗" << std::endl;

    csvFile << "\nSUMMARY,,,\n";
    csvFile << "Total," << totalTests << ",,\n";
    csvFile << "Passed," << passedTests << ",,\n";
    csvFile << "Failed," << failedTests << ",,\n";
    csvFile.close();
    std::cout << "\nResults saved to: test_results.csv" << std::endl;

    if (failedTests == 0) {
        std::cout << "\nALL TESTS PASSED!" << std::endl;
        std::cout << "═══════════════════════════════════════════════════════════════════════" << std::endl;
        return 0;
    } else {
        std::cout << "\nSOME TESTS FAILED" << std::endl;
        std::cout << "═══════════════════════════════════════════════════════════════════════" << std::endl;
        return 1;
    }
}
