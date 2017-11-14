# BacktraceException - A C++ library for using GDB to capture exception backtraces
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.0 )
project(BacktraceException VERSION 0.1 LANGUAGES CXX)

option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)

#Modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

# Compiler Definitions
if (WIN32)
    add_definitions( -DWIN32 )
elseif(UNIX AND NOT APPLE)
    add_definitions( -DLINUX )
endif()

set(GCC_WARN_FLAGS "-W -Wall -Wextra -Werror -Wno-unused-parameter")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_WARN_FLAGS}")

set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:DEBUG> $<$<NOT:$<CONFIG:Debug>>:NDEBUG>)

set(CMAKE_CXX_FLAGS_DEBUG "-ggdb -O2")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension") #Add debug postfix to libraries built in debug mode

include(PackageConfig) #Configure Package-Config and associated files for cmake exports

add_subdirectory(src)
