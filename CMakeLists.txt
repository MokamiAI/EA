cmake_minimum_required(VERSION 3.15)
project(Grasshopper_EA VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the include directories
include_directories(${CMAKE_SOURCE_DIR}/Source/Include)
include_directories(${CMAKE_SOURCE_DIR}/Tests)

# MQL5 EA Source Files (only implemented modules)
set(SOURCE_FILES
    Source/Include/ChartData.mqh
    Source/Include/TrendAnalyzer.mqh
    Source/Include/ImpulseCorrection.mqh
    Source/Include/PatternRecognizer.mqh
    Source/Include/FibonacciLevels.mqh
)

# Test Files (only implemented tests)
set(TEST_FILES
)

# Create main executable for testing
add_executable(grasshopper_tests
    Tests/main_test.cpp
    ${TEST_FILES}
)

# Create library for core modules
add_library(grasshopper_core INTERFACE
    ${SOURCE_FILES}
)

target_include_directories(grasshopper_core INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/Include
)

# Unit tests
enable_testing()
add_test(NAME GrasshopperTests COMMAND grasshopper_tests)

# Custom targets
add_custom_target(format
    COMMAND clang-format -i ${SOURCE_FILES} ${TEST_FILES}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

add_custom_target(lint
    COMMAND cppcheck --enable=all ${SOURCE_FILES} ${TEST_FILES}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Build output directory
set_target_properties(grasshopper_tests PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

message(STATUS "Grasshopper EA Project - v${PROJECT_VERSION}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
