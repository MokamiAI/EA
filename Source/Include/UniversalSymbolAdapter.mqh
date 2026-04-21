// ═══════════════════════════════════════════════════════════════════════
// UNIVERSALSYMBOLADAPTER.MQH - Universal Symbol Support
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Support ANY symbol - Forex, Indices, Stocks, Commodities, Crypto
// Features: Auto-detect symbol type, adjust parameters, handle all markets
//
// ═══════════════════════════════════════════════════════════════════════

#ifndef __UNIVERSALSYMBOLADAPTER_MQH__
#define __UNIVERSALSYMBOLADAPTER_MQH__

// ═══════════════════════════════════════════════════════════════════════
// SYMBOL TYPE ENUMERATION
// ═══════════════════════════════════════════════════════════════════════

enum SymbolType {
    FOREX_PAIR,           // EURUSD, GBPUSD, etc.
    STOCK_INDEX,          // DAX, CAC40, FTSE, ASX200, etc.
    INDIVIDUAL_STOCK,     // APPLE, TESLA, GOOGLE, etc.
    COMMODITY,            // XAUUSD (Gold), XAGUSD (Silver), Oil, etc.
    CRYPTOCURRENCY,       // BTCUSD, ETHUSD, etc.
    UNKNOWN_SYMBOL
};

// ═══════════════════════════════════════════════════════════════════════
// SYMBOL INFO STRUCTURE
// ═══════════════════════════════════════════════════════════════════════

struct SymbolInfo {
    string symbol;
    SymbolType type;
    double spread;
    double pip_value;
    int decimal_places;
    double point;
    double contract_size;
    bool is_tradeable;
    string description;
};

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSAL SYMBOL ADAPTER CLASS
// ═══════════════════════════════════════════════════════════════════════

class UniversalSymbolAdapter {
private:
    SymbolInfo symbolInfo;
    
public:
    // Constructor
    UniversalSymbolAdapter(string _symbol) {
        symbolInfo.symbol = _symbol;
        symbolInfo.type = DetectSymbolType(_symbol);
        symbolInfo.is_tradeable = CheckIfTradeable(_symbol);
        symbolInfo.spread = GetSpread(_symbol);
        symbolInfo.point = SymbolInfoDouble(_symbol, SYMBOL_POINT);
        symbolInfo.decimal_places = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
        
        AnalyzeSymbol(_symbol);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // DETECT SYMBOL TYPE
    // ═════════════════════════════════════════════════════════════════
    SymbolType DetectSymbolType(string sym) {
        
        // Make uppercase for comparison
        string upper_sym = StringToUpper(sym);
        
        // FOREX PAIRS (6 characters, contains currency codes)
        if (StringLen(sym) == 6) {
            // Check for known currency pairs
            if (StringFind(upper_sym, "USD") >= 0 || 
                StringFind(upper_sym, "EUR") >= 0 || 
                StringFind(upper_sym, "GBP") >= 0 || 
                StringFind(upper_sym, "JPY") >= 0 || 
                StringFind(upper_sym, "CAD") >= 0 || 
                StringFind(upper_sym, "CHF") >= 0) {
                return FOREX_PAIR;
            }
        }
        
        // INDICES (usually 3-5 characters)
        if (StringLen(sym) >= 3 && StringLen(sym) <= 5) {
            if (upper_sym == "DAX" ||      // Germany DAX
                upper_sym == "CAC" ||      // France CAC40
                upper_sym == "FTSE" ||     // UK FTSE100
                upper_sym == "ASX" ||      // Australia ASX200
                upper_sym == "NIKKEI" ||   // Japan Nikkei
                upper_sym == "HSI" ||      // Hong Kong
                upper_sym == "SENSEX" ||   // India
                upper_sym == "MIB" ||      // Italy
                upper_sym == "IBEX") {     // Spain
                return STOCK_INDEX;
            }
        }
        
        // COMMODITIES (contains XAU, XAG, OIL, GAS, etc.)
        if (StringFind(upper_sym, "XAU") >= 0 ||    // Gold
            StringFind(upper_sym, "XAG") >= 0 ||    // Silver
            StringFind(upper_sym, "OIL") >= 0 ||    // Oil
            StringFind(upper_sym, "GAS") >= 0 ||    // Natural Gas
            StringFind(upper_sym, "COPPER") >= 0) { // Copper
            return COMMODITY;
        }
        
        // CRYPTOCURRENCIES
        if (StringFind(upper_sym, "BTC") >= 0 ||    // Bitcoin
            StringFind(upper_sym, "ETH") >= 0 ||    // Ethereum
            StringFind(upper_sym, "DOGE") >= 0 ||   // Dogecoin
            StringFind(upper_sym, "XRP") >= 0 ||    // Ripple
            StringFind(upper_sym, "ADA") >= 0) {    // Cardano
            return CRYPTOCURRENCY;
        }
        
        // INDIVIDUAL STOCKS (check if it's in market watch and is a stock)
        if (SymbolInfoInteger(sym, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED) {
            return INDIVIDUAL_STOCK;
        }
        
        return UNKNOWN_SYMBOL;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK IF SYMBOL IS TRADEABLE
    // ═════════════════════════════════════════════════════════════════
    bool CheckIfTradeable(string sym) {
        
        // Check if symbol exists in market watch
        if (!SymbolSelect(sym, true)) {
            Print("[WARNING] Symbol ", sym, " not found in Market Watch");
            return false;
        }
        
        // Check trading mode
        ENUM_SYMBOL_TRADE_MODE trade_mode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
        
        if (trade_mode == SYMBOL_TRADE_MODE_DISABLED) {
            Print("[WARNING] Symbol ", sym, " trading is disabled");
            return false;
        }
        
        // Check if we can buy and sell
        bool allow_buy = (bool)SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
        bool allow_sell = (bool)SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
        
        if (!allow_buy || !allow_sell) {
            Print("[WARNING] Symbol ", sym, " restricted trading mode");
            return false;
        }
        
        return true;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GET SPREAD
    // ═════════════════════════════════════════════════════════════════
    double GetSpread(string sym) {
        double bid = SymbolInfoDouble(sym, SYMBOL_BID);
        double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
        double spread = ask - bid;
        return spread;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ANALYZE SYMBOL CHARACTERISTICS
    // ═════════════════════════════════════════════════════════════════
    void AnalyzeSymbol(string sym) {
        
        Print("\n[SYMBOL ANALYSIS] ", sym);
        Print("════════════════════════════════════════════════════");
        
        // Type
        string type_str = "Unknown";
        switch (symbolInfo.type) {
            case FOREX_PAIR: type_str = "Forex Pair"; break;
            case STOCK_INDEX: type_str = "Stock Index"; break;
            case INDIVIDUAL_STOCK: type_str = "Individual Stock"; break;
            case COMMODITY: type_str = "Commodity"; break;
            case CRYPTOCURRENCY: type_str = "Cryptocurrency"; break;
        }
        Print("Type: ", type_str);
        
        // Tradeable
        Print("Tradeable: ", (symbolInfo.is_tradeable ? "YES" : "NO"));
        
        // Spread
        Print("Current Spread: ", symbolInfo.spread, " points");
        
        // Digits
        Print("Decimal Places: ", symbolInfo.decimal_places);
        
        // Point
        Print("Point Value: ", symbolInfo.point);
        
        // Minimum lot
        double min_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
        Print("Min Lot: ", min_lot, " | Max Lot: ", max_lot);
        
        // Contract size
        double contract_size = SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE);
        Print("Contract Size: ", contract_size);
        
        Print("════════════════════════════════════════════════════\n");
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GET SYMBOL INFO
    // ═════════════════════════════════════════════════════════════════
    SymbolInfo GetSymbolInfo() {
        return symbolInfo;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // IS SYMBOL TRADEABLE
    // ═════════════════════════════════════════════════════════════════
    bool IsSymbolTradeable() {
        return symbolInfo.is_tradeable;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // GET SYMBOL TYPE NAME
    // ═════════════════════════════════════════════════════════════════
    string GetSymbolTypeName() {
        switch (symbolInfo.type) {
            case FOREX_PAIR: return "Forex Pair";
            case STOCK_INDEX: return "Stock Index";
            case INDIVIDUAL_STOCK: return "Individual Stock";
            case COMMODITY: return "Commodity";
            case CRYPTOCURRENCY: return "Cryptocurrency";
            default: return "Unknown";
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // ADJUST PARAMETERS FOR SYMBOL TYPE
    // Indices and stocks have different spreads and volatility
    // ═════════════════════════════════════════════════════════════════
    void AdjustParametersForSymbolType(double &stop_loss_pips, double &take_profit_pips) {
        
        switch (symbolInfo.type) {
            case FOREX_PAIR:
                // Forex: Use standard parameters
                break;
                
            case STOCK_INDEX:
                // Indices: Adjust for lower volatility
                stop_loss_pips = stop_loss_pips * 0.7;      // 30% tighter
                take_profit_pips = take_profit_pips * 0.7;
                Print("[ADJUSTMENT] Index: Using tighter stops");
                break;
                
            case INDIVIDUAL_STOCK:
                // Stocks: Higher volatility, wider stops
                stop_loss_pips = stop_loss_pips * 1.2;      // 20% wider
                take_profit_pips = take_profit_pips * 1.2;
                Print("[ADJUSTMENT] Stock: Using wider targets");
                break;
                
            case COMMODITY:
                // Commodities: High volatility
                stop_loss_pips = stop_loss_pips * 1.3;      // 30% wider
                take_profit_pips = take_profit_pips * 1.3;
                Print("[ADJUSTMENT] Commodity: Using wider targets");
                break;
                
            case CRYPTOCURRENCY:
                // Crypto: Extreme volatility
                stop_loss_pips = stop_loss_pips * 1.5;      // 50% wider
                take_profit_pips = take_profit_pips * 1.5;
                Print("[ADJUSTMENT] Crypto: Using extra wide targets");
                break;
        }
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CHECK SPREAD IS ACCEPTABLE
    // ═════════════════════════════════════════════════════════════════
    bool IsSpreadAcceptable(double max_spread) {
        double current_spread = GetSpread(symbolInfo.symbol);
        
        if (current_spread > max_spread) {
            Print("[WARNING] Spread too high: ", current_spread, " > ", max_spread);
            return false;
        }
        
        return true;
    }
};

#endif
