cmake_minimum_required(VERSION 3.15)
project(lumafix_core VERSION 1.2.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Public include directory
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Main shared library target for Dart FFI
add_library(lumafix_core SHARED
    src/lumafix_engine.cpp
)

target_include_directories(lumafix_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_definitions(lumafix_core PRIVATE LUMAFIX_BUILDING_DLL)

# Set library output properties
set_target_properties(lumafix_core PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

if(NOT ANDROID)
    # Native unit test runner
    add_executable(test_lumafix_engine
        tests/test_lumafix_engine.cpp
        src/lumafix_engine.cpp
    )

    target_include_directories(test_lumafix_engine PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    # Native standalone benchmark
    add_executable(bench_lumafix_engine
        benchmarks/bench_lumafix_engine.cpp
        src/lumafix_engine.cpp
    )

    target_include_directories(bench_lumafix_engine PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    enable_testing()
    add_test(NAME test_lumafix_engine COMMAND test_lumafix_engine)
endif()
