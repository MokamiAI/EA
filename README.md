# 🦗 GRASSHOPPER EXPERT ADVISOR - PROJECT ROOT

## Project Overview

Complete source code repository for the **Grasshopper Expert Advisor** - a professional MetaTrader 5 EA using multi-timeframe price action pattern analysis.

```
WEEKLY → DAILY → 4H → 1H → 5M
(Bias)  (State) (Patterns) (S/R) (Entry)
```

---

## 📁 Project Structure

```
Grasshopper_EA/
├── Source/                      # MQL5 Source Code
│   ├── Grasshopper.mq5         # Main EA file
│   └── Include/                # Header files (modules)
│       ├── ChartData.mqh        # ✅ OHLC data management
│       ├── TrendAnalyzer.mqh    # ✅ Weekly trend detection
│       ├── ImpulseCorrection.mqh # 📝 Daily impulse/correction
│       ├── PatternRecognizer.mqh # 📝 4H pattern recognition
│       ├── FibonacciLevels.mqh  # 📝 Fibonacci calculations
│       ├── ElliottWave.mqh      # 📝 Elliott Wave analysis
│       ├── SupportResistance.mqh # 📝 1H S/R detection
│       ├── SignalGenerator.mqh  # 📝 5M entry signals
│       ├── RiskManager.mqh      # 📝 Position sizing
│       ├── OrderManager.mqh     # 📝 Trade execution
│       └── Utils.mqh            # 📝 Helper functions
│
├── Tests/                       # Unit Tests
│   ├── main_test.cpp           # Test runner
│   ├── test_trend_analyzer.cpp  # 📝 Trend tests
│   ├── test_fibonacci.cpp       # 📝 Fibonacci tests
│   ├── test_position_sizing.cpp # 📝 Risk tests
│   └── test_signal_generation.cpp # 📝 Signal tests
│
├── Config/                      # Configuration Files
│   ├── Settings.json           # EA parameters
│   └── Brokers.json            # Broker-specific configs
│
├── Backtest/                    # Backtest Data & Results
│   ├── EURUSD_2024.csv         # Historical data
│   └── results/                # Backtest results
│
├── Logs/                        # Trading Logs
│   ├── trades.log              # Trade records
│   └── errors.log              # Error logs
│
├── Docs/                        # Additional Documentation
│   └── IMPLEMENTATION_GUIDE.md  # Step-by-step guide
│
├── Build/                       # Build Output
│   └── (CMake output)
│
├── Grasshopper.code-workspace  # VS Code workspace
├── CMakeLists.txt              # CMake build config
├── .gitignore                  # Git ignore rules
└── README.md                   # This file

Legend:
✅ = Implemented
📝 = To be implemented
```

---

## 🚀 Quick Start

### 1. Prerequisites

**Required:**
- Visual Studio Code
- C++ Development Tools (for testing)
- CMake 3.15+
- Git (optional)

**Optional:**
- MetaTrader 5 (for live trading)
- Python (for backtesting scripts)

### 2. Setup in VS Code

**Step 1: Open the Workspace**
```bash
code Grasshopper.code-workspace
```

**Step 2: Install Recommended Extensions**
VS Code will suggest:
- C/C++ Tools
- CMake Tools
- GitLens
- Code Spell Checker

**Step 3: Configure Build**
```bash
# From project root
mkdir Build
cd Build
cmake ..
cmake --build .
```

### 3. Run Tests

```bash
# Build tests
cd Build
cmake --build . --target grasshopper_tests

# Run tests
ctest
# or directly:
./bin/grasshopper_tests
```

### 4. VS Code Configuration

The workspace is pre-configured with:
- C++ IntelliSense
- Include paths for all modules
- Build tasks
- Debug configurations
- Test framework integration

**Press Ctrl+Shift+B** to build
**Press Ctrl+Shift+D** to debug

---

## 📚 Documentation Files

Outside this folder (in outputs):
- **00_READ_ME_FIRST.md** - Start here
- **EA_DEVELOPMENT_STRATEGY.md** - Complete strategy specs
- **EA_TECHNICAL_ARCHITECTURE.md** - Technical details
- **MT5_INTEGRATION_SETUP.md** - MT5 setup guide
- **QUICK_REFERENCE_GUIDE.md** - Visual references
- **DOCUMENT_INDEX.md** - Navigation guide

---

## 🔨 Building the Project

### Option 1: CMake (Recommended for Testing)

```bash
# Create build directory
mkdir Build && cd Build

# Configure
cmake .. -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build .

# Test
ctest --output-on-failure
```

### Option 2: VS Code Build Tasks

**Ctrl+Shift+B** → Select build task
- **Build All**
- **Build Tests**
- **Run Tests**
- **Format Code**
- **Lint Code**

### Option 3: Direct MQL5 Compilation

Copy `Source/Grasshopper.mq5` to:
```
C:\Users\[Username]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Experts\Grasshopper\
```

Then compile in MT5 MetaEditor.

---

## 📋 Implementation Progress

### Phase 1: Core Analysis Engine (Weeks 1-2)
- [x] ChartData.mqh - Fetch OHLC data
- [x] TrendAnalyzer.mqh - Weekly trend detection
- [ ] ImpulseCorrection.mqh - Daily impulse/correction
- [ ] PatternRecognizer.mqh - 4H pattern recognition
- [ ] FibonacciLevels.mqh - Fibonacci calculations
- [ ] ElliottWave.mqh - Elliott Wave analysis

### Phase 2: Signal Generation (Week 3)
- [ ] SupportResistance.mqh - 1H S/R detection
- [ ] SignalGenerator.mqh - 5M entry signals
- [ ] Confluence checker

### Phase 3: Trade Management (Week 4)
- [ ] RiskManager.mqh - Position sizing
- [ ] OrderManager.mqh - Order execution
- [ ] Stop/TP management

### Phase 4: MT5 Integration (Weeks 5-6)
- [ ] MT5 API connection
- [ ] Real-time data fetching
- [ ] Order execution

### Phase 5: Testing (Weeks 7-8)
- [ ] Unit tests for all modules
- [ ] Integration tests
- [ ] Backtest framework

### Phase 6: Live Trading (Week 9+)
- [ ] Paper trading
- [ ] Live trading with small positions

---

## 🧪 Testing

### Unit Tests (In Tests/ folder)

```bash
# Run all tests
ctest

# Run specific test
ctest -R TrendAnalyzer

# Verbose output
ctest --output-on-failure -V
```

### Types of Tests

1. **Unit Tests** - Individual module functions
2. **Integration Tests** - Module interactions
3. **Backtest Tests** - Historical data validation
4. **Live Tests** - Paper trading validation

---

## 🛠️ Development Workflow

### Daily Development

1. **Write Code** - Edit .mqh files in Source/Include/
2. **Write Tests** - Add tests in Tests/
3. **Build & Test** - Ctrl+Shift+B then run tests
4. **Commit** - `git commit -m "Add feature"`
5. **Deploy** - Copy to MT5 when ready

### Code Style

- Follow MQL5 conventions
- Use detailed comments
- Include usage examples
- Keep functions focused (single responsibility)
- Use structs for complex data

### Naming Conventions

- **Classes**: PascalCase (ChartData, TrendAnalyzer)
- **Functions**: PascalCase (GetCandle, AnalyzeTrend)
- **Variables**: camelCase (chartData, lastBarTime)
- **Constants**: UPPER_SNAKE_CASE (PERIOD_M5, MAX_TRADES)
- **Enums**: PascalCase (TrendDirection, SignalType)

---

## 📊 Current Implementation Status

```
Module                  Status      % Complete   Next Step
─────────────────────────────────────────────────────────────
ChartData              ✅ DONE      100%         Use in other modules
TrendAnalyzer          ✅ DONE      100%         Test with real data
ImpulseCorrection      📝 TODO      0%           Implement daily analysis
PatternRecognizer      📝 TODO      0%           4H pattern logic
FibonacciLevels        📝 TODO      0%           Fibonacci calculations
ElliottWave            📝 TODO      0%           Wave identification
SupportResistance      📝 TODO      0%           1H S/R detection
SignalGenerator        📝 TODO      0%           Entry signal logic
RiskManager            📝 TODO      0%           Position sizing
OrderManager           📝 TODO      0%           Trade execution
Utils                  📝 TODO      0%           Helper functions
───────────────────────────────────────────────────────────
TOTAL                              ~18%
```

---

## 🐛 Known Issues

None yet - First modules just completed!

---

## 📝 Module Implementation Order

Recommended order for implementation:

1. ✅ **ChartData** - Foundation for all other modules
2. ✅ **TrendAnalyzer** - Uses ChartData
3. **ImpulseCorrection** - Uses ChartData
4. **FibonacciLevels** - Standalone
5. **PatternRecognizer** - Uses ChartData, Fibonacci
6. **ElliottWave** - Uses ChartData
7. **SupportResistance** - Uses ChartData
8. **SignalGenerator** - Uses all above
9. **RiskManager** - Standalone
10. **OrderManager** - Uses all trading modules
11. **Utils** - Used by all modules

---

## 📖 How to Test Modules

Each module has a usage example at the bottom. To test:

```mql5
// Create instance
ChartData chart("EURUSD");

// Call functions
Candle candle = chart.GetCandle(PERIOD_M5, 0);

// Verify results
if (candle.close > 0) {
    Print("✓ Test passed");
} else {
    Print("✗ Test failed");
}
```

---

## 🎯 Next Steps

### Immediate (This Week)
1. [ ] Review ChartData module code
2. [ ] Review TrendAnalyzer module code
3. [ ] Test both modules manually
4. [ ] Create unit tests for both

### Next Week
1. [ ] Implement ImpulseCorrection module
2. [ ] Implement FibonacciLevels module
3. [ ] Create tests for new modules
4. [ ] Review MT5 structure

### Following Week
1. [ ] Implement remaining modules
2. [ ] Create integration tests
3. [ ] Test complete signal flow
4. [ ] Prepare for MT5 deployment

---

## 📞 Module Contact (Functions Available)

### ChartData.mqh
- `GetCandle(timeframe, index)` - Get OHLC data
- `GetCandleHistory(timeframe, count)` - Get array of candles
- `GetCurrentHigh/Low(timeframe)` - Current extremes
- `GetBid/Ask()` - Current prices
- `IsNewBar(timeframe)` - Check for new bar
- `GetDigits/Point/PipSize` - Symbol info

### TrendAnalyzer.mqh
- `AnalyzeTrend()` - Main trend analysis
- `CalculateTrendStrength()` - Rate strength 1-5
- `IsTrendConfirmed()` - Verify trend
- `GetTrendDuration()` - How long trend active
- `GetWeeklyExtremes()` - Weekly high/low

---

## ⚙️ Configuration

### Settings.json (Config/ folder)
```json
{
  "Strategy": {
    "RiskPerTrade": 1.0,
    "MinRiskReward": 1.5,
    "MaxConcurrentTrades": 2
  },
  "Timeframes": {
    "Weekly": "W1",
    "Daily": "D1",
    "4Hour": "H4",
    "1Hour": "H1",
    "5Minute": "M5"
  }
}
```

---

## 🤝 Contributing

To add new functionality:

1. Create new .mqh file in Source/Include/
2. Include existing modules if needed
3. Follow naming conventions
4. Add detailed comments and examples
5. Create tests in Tests/
6. Update this README with progress

---

## 📄 License

This project is proprietary and confidential.

---

## 🎓 Learning Resources

- **MQL5 Documentation**: https://docs.mql4.com/
- **Strategy Docs**: See Docs/ folder
- **Technical Architecture**: EA_TECHNICAL_ARCHITECTURE.md
- **Implementation Guide**: IMPLEMENTATION_GUIDE.md

---

## ✨ Key Features

- ✅ Multi-timeframe analysis
- ✅ Modular architecture
- ✅ Unit test framework
- ✅ Complete documentation
- ✅ VS Code integration
- ✅ CMake build system
- ✅ Professional code structure

---

## 🚀 Status

**Current Version:** 1.0.0 (In Development)
**Last Updated:** April 20, 2026
**Next Milestone:** Phase 1 completion (Week 2)

---

**Start with 00_READ_ME_FIRST.md in the parent Docs folder.**

**Happy coding! 🦗**
