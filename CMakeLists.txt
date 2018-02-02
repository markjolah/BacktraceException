# BacktraceException - A C++ library for using GDB to capture exception backtraces
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.3 )
project(BacktraceException VERSION 0.2 LANGUAGES CXX)
cmake_policy(SET CMP0054 NEW) #Don't derrefernce in if() statements
cmake_policy(SET CMP0022 NEW) #LINK_INTERFACE_LIBRARIES fix


option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)

#Modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

find_package(Boost REQUIRED COMPONENTS iostreams)


# Compiler Definitions
if (WIN32)
    add_definitions( -DWIN32 )
elseif(UNIX AND NOT APPLE)
    add_definitions( -DLINUX )
endif()

# CFLAGS ##
add_compile_options(-W -Wall -Wextra -Werror -Wno-unused-parameter)
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    add_definitions(-DDEBUG)
elseif()
    add_definitions(-DNDEBUG)
endif()
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")
set(CMAKE_CXX_FLAGS_DEBUG "-ggdb -O2")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-ggdb -O3")

include(PackageConfig) #Configure Package-Config and associated files for cmake exports

add_subdirectory(src)
