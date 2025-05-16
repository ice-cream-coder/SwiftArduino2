cmake_minimum_required(VERSION 3.15)

# Include AVR toolchain file before project() declaration
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/avr-nano.cmake)

# Check for generator compatibility with Swift
if(CMAKE_GENERATOR MATCHES "Xcode|Ninja")
    set(SWIFT_SUPPORTED TRUE)
    project(ArduinoExplorationSwift LANGUAGES C CXX ASM Swift)
else()
    set(SWIFT_SUPPORTED FALSE)
    project(ArduinoExplorationSwift LANGUAGES C CXX ASM)
    message(STATUS "Using a generator that doesn't support Swift: ${CMAKE_GENERATOR}")
    message(STATUS "Only AVR compilation will be enabled")
endif()

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define Arduino libraries path
set(ARDUINO_LIBRARIES_PATH "/Users/icecream/Documents/Arduino/libraries")
set(ARDUINO_CORE_PATH "/Users/icecream/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/cores/arduino")
set(ARDUINO_VARIANT_PATH "/Users/icecream/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/variants/standard")

# Add Arduino core include path
include_directories(${ARDUINO_CORE_PATH})

# Add AVR toolchain include path
include_directories(/Users/icecream/Library/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7/avr/include)

# Add Arduino board variant include path (for Nano with ATmega328p, often 'standard' variant)
include_directories(${ARDUINO_VARIANT_PATH})

# --- Compile Arduino Core --- 
file(GLOB_RECURSE CORE_C_FILES "${ARDUINO_CORE_PATH}/*.c")
file(GLOB_RECURSE CORE_CPP_FILES "${ARDUINO_CORE_PATH}/*.cpp")
file(GLOB_RECURSE CORE_S_FILES "${ARDUINO_CORE_PATH}/*.S")
list(APPEND CORE_FILES ${CORE_C_FILES} ${CORE_CPP_FILES} ${CORE_S_FILES})

add_library(arduino_core STATIC ${CORE_FILES})
target_include_directories(arduino_core PUBLIC
    ${ARDUINO_CORE_PATH}
    ${ARDUINO_VARIANT_PATH}
)
# Ensure CXX linker for mixed C/CXX sources
set_target_properties(arduino_core PROPERTIES LINKER_LANGUAGE CXX)

# Create an interface library for the header-only IRremote
add_library(irremote INTERFACE)

# Set the language for the irremote target
set_target_properties(irremote PROPERTIES
    LINKER_LANGUAGE CXX
)

# Include directories
target_include_directories(irremote INTERFACE
    ${ARDUINO_LIBRARIES_PATH}/IRremote/src
    ${ARDUINO_LIBRARIES_PATH}/IRremote/src/private
)

# Add a dummy C++ executable for testing AVR compilation
add_executable(DummyAVRTest dummy_avr_test.cpp)
target_link_libraries(DummyAVRTest PRIVATE irremote arduino_core)

# Set properties for the AVR executable
set_target_properties(DummyAVRTest PROPERTIES
    OUTPUT_NAME "DummyAVRTest"
)

# Generate .hex file for DummyAVRTest
add_avr_hex(DummyAVRTest)

# ---------------------------------------- #
# Swift support - separate from AVR builds #
# ---------------------------------------- #

# Only add Swift targets if we're using a compatible generator
if(SWIFT_SUPPORTED)
    # Create Swift module map for C++ interop
    set(CMAKE_Swift_MODULE_NAME "IRremote")
    set(CMAKE_Swift_MODULE_MAP "${CMAKE_CURRENT_BINARY_DIR}/module.modulemap")

    # Generate module map
    file(WRITE ${CMAKE_Swift_MODULE_MAP} "module IRremote {
        umbrella header \"${ARDUINO_LIBRARIES_PATH}/IRremote/src/IRremote.h\"
        export *
        module * { export * }
    }")

    # Copy module map to build directory
    configure_file(${CMAKE_SOURCE_DIR}/module.modulemap ${CMAKE_BINARY_DIR}/module.modulemap COPYONLY)

    # Add Swift executable (this will use the host compiler, not AVR)
    add_executable(SwiftIRTest main.swift)

    # Set Swift compiler flags for LLVM IR generation
    set_target_properties(SwiftIRTest PROPERTIES
        Swift_COMPILATION_MODE single-file
        Swift_IMPORT_PATHS "${CMAKE_CURRENT_BINARY_DIR}"
    )

    # Add Swift compile flags for LLVM IR generation
    target_compile_options(SwiftIRTest PRIVATE
        $<$<COMPILE_LANGUAGE:Swift>:
            -Xcc -fmodule-map-file=${CMAKE_BINARY_DIR}/module.modulemap
            -Xcc -I${ARDUINO_LIBRARIES_PATH}/IRremote/src
            -emit-ir
        >
    )

    # Add a custom target to further process the Swift IR for AVR
    add_custom_command(
        TARGET SwiftIRTest
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "SwiftIRTest compiled to LLVM IR. Next step: Process for AVR target."
        COMMENT "Swift IR generation completed"
    )
endif() 