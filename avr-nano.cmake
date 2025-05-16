# CMake Toolchain file for AVR (Arduino Nano - ATmega328P)

# Define the target system and processor
set(CMAKE_SYSTEM_NAME Generic) # Using "Generic" for bare-metal embedded systems
set(CMAKE_SYSTEM_PROCESSOR atmega328p)

# Path to the AVR GCC toolchain (adjust if your path is different)
set(AVR_GCC_TOOLCHAIN_PATH "/Users/icecream/Library/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7")

# Specify the cross-compilers
set(CMAKE_C_COMPILER "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-gcc")
set(CMAKE_CXX_COMPILER "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-g++")
set(CMAKE_ASM_COMPILER "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-gcc") # Use avr-gcc for .S files, not avr-as

# Specify other toolchain utilities
set(CMAKE_AR "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-ar" CACHE FILEPATH "Archiver")
set(CMAKE_OBJCOPY "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-objcopy" CACHE FILEPATH "Tool to copy object files")
set(CMAKE_OBJDUMP "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-objdump" CACHE FILEPATH "Tool to dump object files")
set(CMAKE_SIZE_TOOL "${AVR_GCC_TOOLCHAIN_PATH}/bin/avr-size" CACHE FILEPATH "Tool to display object size")

# Configure how CMake finds programs, libraries, and includes
# Search for programs only in the host system paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Search for libraries and headers only in the target system paths
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY) # For find_package

# CPU frequency for Arduino Nano (16MHz)
set(F_CPU "16000000UL" CACHE STRING "Target CPU Frequency")

# Common architectural flag (used by C, CXX, ASM, Linker)
set(AVR_ARCH_FLAG "-mmcu=${CMAKE_SYSTEM_PROCESSOR}")

# Make sure the device identifier is properly set (-mmcu and -DF_CPU)
# Define the specific AVR device for the toolchain
add_definitions(-DAVR -DF_CPU=${F_CPU} -D__AVR_ATmega328P__ -DARDUINO=10806 -DARDUINO_AVR_NANO -DARDUINO_ARCH_AVR)

# C compiler flags
set(CMAKE_C_FLAGS_INIT "${AVR_ARCH_FLAG} -Os -Wall -ffunction-sections -fdata-sections")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS_INIT}" CACHE STRING "C compiler flags")

# CXX compiler flags
set(CMAKE_CXX_FLAGS_INIT "${AVR_ARCH_FLAG} -Os -Wall -fno-exceptions -ffunction-sections -fdata-sections")
# Arduino core often uses gnu++11. IRremote might need C++17.
# avr-gcc 7.3.0 supports C++17. Your CMakeLists.txt requests CMAKE_CXX_STANDARD 17.
if(DEFINED CMAKE_CXX_STANDARD AND CMAKE_CXX_STANDARD EQUAL 17)
    set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} -std=gnu++17")
elif(DEFINED CMAKE_CXX_STANDARD AND CMAKE_CXX_STANDARD EQUAL 11) # Fallback or default
    set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} -std=gnu++11")
else() # Default if not set by project
    set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} -std=gnu++11")
endif()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS_INIT}" CACHE STRING "C++ compiler flags")

# Assembler flags 
# Use avr-gcc for assembly files to ensure proper preprocessing
set(CMAKE_ASM_FLAGS_INIT "${AVR_ARCH_FLAG} -x assembler-with-cpp")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS_INIT}" CACHE STRING "Assembler flags")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--gc-sections ${AVR_ARCH_FLAG}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_INIT}" CACHE STRING "Executable linker flags")

# Set CMAKE_TRY_COMPILE_TARGET_TYPE to avoid issues with compiler checks for executable
# if they expect a host executable. For embedded, checks often use static libraries.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Ensure we don't try to run the linker during compiler tests
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

# Add target to generate .hex files which can be flashed to the MCU
function(add_avr_hex TARGET)
    # Create a target to generate a .hex file
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom ${TARGET} ${TARGET}.hex
        COMMENT "Generating HEX file: ${TARGET}.hex"
    )
endfunction()

message(STATUS "-------------------------------------------------------------")
message(STATUS "AVR Toolchain File Loaded: Targeting Arduino Nano (atmega328p)")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "ASM Compiler: ${CMAKE_ASM_COMPILER}")
message(STATUS "Arch Flag: ${AVR_ARCH_FLAG}")
message(STATUS "C Flags: ${CMAKE_C_FLAGS}")
message(STATUS "CXX Flags: ${CMAKE_CXX_FLAGS}")
message(STATUS "ASM Flags: ${CMAKE_ASM_FLAGS}")
message(STATUS "Linker Flags: ${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "-------------------------------------------------------------") 