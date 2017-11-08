# BacktraceException - A C++ library for using GDB to capture exception backtraces
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.0 )
project(BacktraceException VERSION 0.1 LANGUAGES CXX)

#Modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

# Compiler Definitions
if (WIN32)
    add_definitions( -DWIN32 )
elseif(UNIX AND NOT APPLE)
    add_definitions( -DLINUX )
endif()

set(GCC_WARN_FLAGS "-W -Wall -Wextra -Werror -Wno-unused-parameter")
set(GCC_STD_FLAGS "-std=c++11")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_WARN_FLAGS} ${GCC_STD_FLAGS}")

if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    add_definitions(-DDEBUG)
else()
    add_definitions(-DNDEBUG)
endif()
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")
set(CMAKE_CXX_FLAGS_DEBUG "-ggdb -O2")
#Release compiler options
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    set(BacktraceException_DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
else()
    set(BacktraceException_DEBUG_POSTFIX "")
endif()
message(STATUS "[BacktraceException] DebugPostfix: ${BacktraceException_DEBUG_POSTFIX}")

include(BacktraceException-PackageConfig) #Configure Package-Config and associated files for cmake exports

add_subdirectory(src)
