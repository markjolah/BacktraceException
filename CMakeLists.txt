# BacktraceException - A C++ library for using GDB to capture exception backtraces
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017-2018
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.9 )
project(BacktraceException VERSION 0.2 LANGUAGES CXX)

option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)

if (NOT BUILD_SHARED_LIBS AND NOT BUILD_STATIC_LIBS)
  set (BUILD_STATIC_LIBS ON)
endif ()

message(STATUS "OPTION: BUILD_SHARED_LIBS: ${BUILD_SHARED_LIBS}")
message(STATUS "OPTION: BUILD_STATIC_LIBS: ${BUILD_STATIC_LIBS}")

#Modules
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

### Dependencies
find_package(Boost REQUIRED COMPONENTS iostreams)

# CFLAGS ##
add_compile_options($<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-O0>)
add_compile_options($<$<CONFIG:Debug>:-W>)
add_compile_options($<$<CONFIG:Debug>:-Wall>)
add_compile_options($<$<CONFIG:Debug>:-Wextra>)

set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")

### PackageConfig Exports
include(ExportPackageWizzard)
export_package_wizzard()

### Source directories
add_subdirectory(src)
