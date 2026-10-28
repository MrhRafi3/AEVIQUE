cmake_minimum_required(VERSION 3.15)
project(aevique_core VERSION 1.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Public include directory
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Main shared library target for Dart FFI
add_library(aevique_core SHARED
    src/aevique_engine.cpp
)

target_include_directories(aevique_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_definitions(aevique_core PRIVATE AEVIQUE_BUILDING_DLL)

# Set library output properties
set_target_properties(aevique_core PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

if(NOT ANDROID)
    # Native unit test runner
    add_executable(test_aevique_engine
        tests/test_aevique_engine.cpp
        src/aevique_engine.cpp
    )

    target_include_directories(test_aevique_engine PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    # Native standalone benchmark
    add_executable(bench_aevique_engine
        benchmarks/bench_aevique_engine.cpp
        src/aevique_engine.cpp
    )

    target_include_directories(bench_aevique_engine PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    enable_testing()
    add_test(NAME test_aevique_engine COMMAND test_aevique_engine)
endif()
