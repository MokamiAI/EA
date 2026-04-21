# 🦗 GRASSHOPPER EA - VSCODE IMPLEMENTATION GUIDE

## Complete Setup Instructions for VS Code

---

## 1. PREREQUISITES

### Required Software
- **Visual Studio Code** (Latest)
- **C++ Tools**:
  - GCC/Clang compiler
  - CMake 3.15+
  - GNU Make (Windows: use MinGW)

### Installation Steps

**On Windows:**
```bash
# Install MinGW with CMake
# 1. Download from: https://www.mingw-w64.org/
# 2. Run installer, select gcc, g++, cmake
# 3. Add to PATH

# Verify installation
gcc --version
cmake --version
```

**On macOS:**
```bash
# Install Xcode tools
xcode-select --install

# Install CMake
brew install cmake
```

**On Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install build-essential cmake

# Fedora/RHEL
sudo dnf install gcc g++ cmake make
```

---

## 2. VS CODE SETUP

### Step 1: Open Project Folder

1. Open VS Code
2. **File → Open Folder**
3. Navigate to `Grasshopper_EA` directory
4. Click **Select Folder**

### Step 2: Install Recommended Extensions

VS Code will show a popup asking to install recommended extensions:

```
Recommended Extensions:
✓ C/C++ (Microsoft)
✓ CMake (Microsoft)
✓ CMake Tools (Microsoft)
✓ GitLens (if using Git)
✓ Prettier (for code formatting)
✓ Code Spell Checker
```

Click **Install All** or install individually:
- Press **Ctrl+Shift+X** (Extensions)
- Search for each name
- Click **Install**

### Step 3: Open Workspace

1. In VS Code, **File → Open Workspace from File**
2. Select `Grasshopper.code-workspace`
3. Workspace loads with pre-configured settings

---

## 3. BUILD SYSTEM SETUP

### Option A: CMake (Recommended)

**Step 1: Configure CMake**
```bash
# From VS Code terminal (Ctrl+`)
cd Grasshopper_EA
mkdir Build
cd Build
cmake ..
```

**Step 2: Build Project**
```bash
# From Build directory
cmake --build .
```

**Or use VS Code CMake Tools:**
- **Ctrl+Shift+P** → "CMake: Configure"
- **Ctrl+Shift+P** → "CMake: Build"
- **Ctrl+Shift+P** → "CMake: Run Tests"

### Option B: VS Code Tasks

Press **Ctrl+Shift+B** to see build tasks:

```
- Build All
- Build Tests  
- Run Tests
- Format Code
- Lint Code
```

Select one and it will execute.

---

## 4. PROJECT STRUCTURE WALKTHROUGH

### Source Code Organization

```
Grasshopper_EA/
├── Source/
│   ├── Grasshopper.mq5           ← Main EA entry point
│   └── Include/
│       ├── ChartData.mqh          ← ✅ OHLC data (IMPLEMENTED)
│       ├── TrendAnalyzer.mqh      ← ✅ Trend detection (IMPLEMENTED)
│       ├── ImpulseCorrection.mqh  ← Daily state (TODO)
│       ├── PatternRecognizer.mqh  ← 4H patterns (TODO)
│       ├── FibonacciLevels.mqh    ← Fibonacci (TODO)
│       ├── ElliottWave.mqh        ← Wave analysis (TODO)
│       ├── SupportResistance.mqh  ← 1H levels (TODO)
│       ├── SignalGenerator.mqh    ← 5M signals (TODO)
│       ├── RiskManager.mqh        ← Position sizing (TODO)
│       ├── OrderManager.mqh       ← Trade execution (TODO)
│       └── Utils.mqh              ← Helpers (TODO)
```

### Key Files Explained

| File | Purpose | Status |
|------|---------|--------|
| **Grasshopper.mq5** | Main EA - runs on MT5 | ✅ Ready |
| **ChartData.mqh** | Fetch OHLC data | ✅ Done |
| **TrendAnalyzer.mqh** | Weekly trend | ✅ Done |
| **Config/Settings.json** | EA parameters | ✅ Ready |
| **Tests/main_test.cpp** | Unit tests | ✅ Ready |
| **CMakeLists.txt** | Build configuration | ✅ Ready |

---

## 5. RUNNING TESTS IN VS CODE

### Method 1: Using CMake Tools (Easy)

1. **Ctrl+Shift+P** → Search "CMake: Run Tests"
2. Select and press **Enter**
3. Tests run in the terminal below

### Method 2: Using Build Task

1. **Ctrl+Shift+B** (or Ctrl+Shift+P → "Tasks: Run Build Task")
2. Select **"Run Tests"**
3. Output appears in terminal

### Method 3: Manual Command

1. Open terminal: **Ctrl+`**
2. Run:
```bash
cd Build
ctest --output-on-failure
```

### Expected Test Output

```
════════════════════════════════════════════════════════════════════════
TREND ANALYZER TEST SUITE
════════════════════════════════════════════════════════════════════════

[TEST] Bullish Trend Detection (Higher High + Higher Low)
  ✓ PASS: Detected bullish trend correctly

[TEST] Bearish Trend Detection (Lower High + Lower Low)
  ✓ PASS: Detected bearish trend correctly

...

════════════════════════════════════════════════════════════════════════
TEST SUMMARY
════════════════════════════════════════════════════════════════════════
Total Tests:  16
Passed:       16 ✓
Failed:       0 ✗

🦗 ALL TESTS PASSED! 🦗
```

---

## 6. CODE EDITING & INTELLISENSE

### IntelliSense Features

- **Auto-completion**: Start typing, suggestions appear
- **Go to definition**: **Ctrl+Click** on function
- **Find references**: **Ctrl+Shift+F** for global search
- **Rename symbol**: **Ctrl+H** then rename
- **Format code**: **Ctrl+Shift+F** to auto-format

### Useful Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+P** | Open file quickly |
| **Ctrl+F** | Find in current file |
| **Ctrl+H** | Find and replace |
| **Ctrl+/** | Toggle comment |
| **Ctrl+Shift+P** | Command palette |
| **F11** | Toggle fullscreen |
| **Ctrl+J** | Toggle terminal |
| **Ctrl+B** | Toggle sidebar |

---

## 7. DEBUGGING

### Set Up Debugger

1. **Run → Add Configuration**
2. Select **C++ (GDB/LLDB)**
3. Choose your compiler (gcc/clang)
4. **launch.json** creates automatically

### Debug Workflow

1. Set **breakpoint** by clicking line number (red dot appears)
2. Press **F5** or **Run → Start Debugging**
3. Execution pauses at breakpoint
4. Use debug panel to:
   - **Step Over** (F10) - Next line
   - **Step Into** (F11) - Enter function
   - **Step Out** (Shift+F11) - Exit function
   - **Continue** (F5) - Resume execution

### Debug Console

View variables and their values:
- **Variables** panel shows local variables
- **Watch** panel - add custom expressions
- **Debug Console** - evaluate expressions

---

## 8. IMPLEMENTING NEW MODULES

### Step-by-Step Process

**Example: Implementing FibonacciLevels.mqh**

### Step 1: Create the File

1. Right-click **Source/Include** folder
2. **New File** → name `FibonacciLevels.mqh`
3. Paste template:

```mql5
// ═══════════════════════════════════════════════════════════════════════
// FIBONACCILEVELS.MQH - Fibonacci Calculations
// ═══════════════════════════════════════════════════════════════════════

#ifndef __FIBONACCILEVELS_MQH__
#define __FIBONACCILEVELS_MQH__

struct FibonacciLevels {
    double level_0;
    double level_236;
    double level_382;
    double level_618;
    double level_100;
    double level_1618;
};

class FibonacciCalculator {
public:
    // TODO: Implement functions
};

#endif  // __FIBONACCILEVELS_MQH__
```

### Step 2: Write Unit Tests

1. Create **Tests/test_fibonacci.cpp**
2. Write test cases:

```cpp
void TestFibonacciCalculations() {
    TEST_START("Calculate Fibonacci Levels");
    // Your test code here
    ASSERT_EQ(actual, expected, "message");
}
```

### Step 3: Implement Functions

Follow the pattern in `ChartData.mqh` and `TrendAnalyzer.mqh`

### Step 4: Test Implementation

```bash
cd Build
cmake --build .
ctest --output-on-failure
```

---

## 9. WORKING WITH GIT (Optional)

### Initialize Repository

```bash
cd Grasshopper_EA
git init
git add .
git commit -m "Initial commit: Grasshopper EA project setup"
```

### Daily Workflow

```bash
# Check status
git status

# Add changes
git add Source/Include/YourModule.mqh

# Commit
git commit -m "Implement YourModule functionality"

# View history
git log --oneline
```

### Useful Git Commands

```bash
# Create feature branch
git checkout -b feature/implement-impulse-correction

# Switch branches
git checkout main

# Merge branch
git merge feature/implement-impulse-correction

# View differences
git diff
```

---

## 10. NEXT STEPS - IMMEDIATE

### This Session (1-2 hours)

- [ ] Complete VS Code setup
- [ ] Open `Grasshopper_EA` project
- [ ] Run the test suite (Ctrl+Shift+B → Run Tests)
- [ ] Explore ChartData.mqh code
- [ ] Explore TrendAnalyzer.mqh code
- [ ] Review test output

### Next Session (2-3 hours)

- [ ] Implement ImpulseCorrection.mqh
- [ ] Create test cases for new module
- [ ] Run all tests
- [ ] Review results

### Following Session (2-3 hours)

- [ ] Implement FibonacciLevels.mqh
- [ ] Implement PatternRecognizer.mqh
- [ ] Continue phase 1 implementation

---

## 11. TERMINAL COMMANDS QUICK REFERENCE

### Build Commands

```bash
# Configure with CMake
cmake -B Build -S .

# Build all
cmake --build Build

# Build only tests
cmake --build Build --target grasshopper_tests

# Clean build
rm -rf Build && cmake -B Build -S .
```

### Test Commands

```bash
# Run all tests
ctest --test-dir Build

# Run specific test
ctest --test-dir Build -R TrendAnalyzer

# Verbose output
ctest --test-dir Build --output-on-failure -V
```

### Code Quality

```bash
# Format code
clang-format -i Source/Include/*.mqh

# Check for issues
cppcheck Source/Include/
```

---

## 12. FILE EDITING TIPS

### Edit Includes

Always include dependencies in this order:

```mql5
#ifndef __MODULENAME_MQH__
#define __MODULENAME_MQH__

#include "ChartData.mqh"        // Base dependency first
#include "TrendAnalyzer.mqh"    // Then others

// Your code here

#endif  // __MODULENAME_MQH__
```

### Edit Main EA

The `Grasshopper.mq5` file includes all modules:

```mql5
#include "Include/ChartData.mqh"
#include "Include/TrendAnalyzer.mqh"
// ... etc
```

When you create a new module, add its include here.

---

## 13. TROUBLESHOOTING

### Build Fails: "Command not found: cmake"

**Solution:**
```bash
# Verify CMake installed
cmake --version

# If not found, reinstall:
# - Windows: MinGW installer
# - macOS: brew install cmake
# - Linux: apt-get install cmake
```

### Test Won't Run: "No tests found"

**Solution:**
```bash
# Rebuild
rm -rf Build
mkdir Build && cd Build
cmake ..
cmake --build .

# Run
ctest --output-on-failure
```

### IntelliSense Not Working

**Solution:**
1. **Ctrl+Shift+P** → "C/C++: Reset IntelliSense"
2. Wait for re-indexing
3. Restart VS Code if needed

### Include File Not Found

**Solution:**
1. Check `CMakeLists.txt` has correct include paths
2. Verify file exists in correct location
3. Check capitalization (case-sensitive on Linux)

---

## 14. USEFUL VS CODE EXTENSIONS

Beyond recommended extensions:

| Extension | Purpose |
|-----------|---------|
| **Clang-Format** | Auto-format code |
| **Todo Tree** | Highlight TODO comments |
| **Peacock** | Color code workspaces |
| **Better Comments** | Colorize comments |
| **Explorer Exclude** | Hide unwanted files |

---

## 15. FINAL CHECKLIST

Before coding the next module:

- [ ] VS Code installed and configured
- [ ] All extensions installed
- [ ] CMake can find compiler
- [ ] Project builds successfully
- [ ] Tests run and pass
- [ ] Can edit files in vs code
- [ ] IntelliSense works
- [ ] Terminal works in VS Code

---

## 🎓 Learning Path

1. **Understanding** (30 min)
   - Read ChartData.mqh
   - Read TrendAnalyzer.mqh
   - Understand function signatures

2. **Running Tests** (15 min)
   - Build project
   - Run tests
   - Review output

3. **Coding** (2-3 hours)
   - Implement new module
   - Create tests
   - Fix any issues

4. **Debugging** (30 min)
   - Set breakpoints
   - Step through code
   - Verify logic

---

## 📞 Quick Reference

**Build & Test:**
- **Ctrl+Shift+B** - Build
- **Ctrl+Shift+P** → "CMake: Run Tests" - Test

**Code Editing:**
- **Ctrl+P** - Open file
- **Ctrl+F** - Find
- **Ctrl+H** - Replace
- **Ctrl+/** - Comment/uncomment

**Debug:**
- **F5** - Start debugging
- **F10** - Step over
- **F11** - Step into

**Terminal:**
- **Ctrl+`** - Toggle terminal
- **Ctrl+Shift+`** - New terminal

---

## 🚀 You're Ready!

Your VS Code environment is fully set up. You can now:

✅ Edit MQL5 code with IntelliSense
✅ Build the project with CMake
✅ Run unit tests
✅ Debug code step-by-step
✅ Implement new modules
✅ Manage code with Git

**Start with reading ChartData.mqh, then implement your first new module!**

**Happy coding! 🦗**
