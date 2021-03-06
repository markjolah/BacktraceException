# BacktraceException - A C++ library for using GDB to capture exception backtraces
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017-2019
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.9 )
project(BacktraceException VERSION 0.2 LANGUAGES CXX)

option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_STATIC_LIBS "Build static libraries" ON)
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    option(BUILD_TESTING "Build testing framework" ON)
else()
    option(BUILD_TESTING "Build testing framework" OFF)
endif()
option(OPT_DOC "Build documentation" OFF)
option(OPT_EXAMPLES "Build examples (no installation)" OFF)
option(OPT_INSTALL_TESTING "Install testing executables" OFF)
option(OPT_EXPORT_BUILD_TREE "Configure the package so it is usable from the build tree.  Useful for development." OFF)

if (NOT BUILD_SHARED_LIBS AND NOT BUILD_STATIC_LIBS)
  set (BUILD_STATIC_LIBS ON) #Must build at least one of SHARED_ and STATIC_LIBS.  Default SHARED_
endif ()

message(STATUS "OPTION: BUILD_SHARED_LIBS: ${BUILD_SHARED_LIBS}")
message(STATUS "OPTION: BUILD_STATIC_LIBS: ${BUILD_STATIC_LIBS}")
message(STATUS "OPTION: BUILD_TESTING: ${BUILD_TESTING}")
message(STATUS "OPTION: OPT_DOC: ${OPT_DOC}")
message(STATUS "OPTION: OPT_EXAMPLES: ${OPT_EXAMPLES}")
message(STATUS "OPTION: OPT_INSTALL_TESTING: ${OPT_INSTALL_TESTING}")
message(STATUS "OPTION: OPT_EXPORT_BUILD_TREE: ${OPT_EXPORT_BUILD_TREE}")

#Add UcommonCmakeModules git subpreo to path.
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCMakeModules)

### Dependencies

### CFLAGS
include(ConfigureDebugBuilds) #Configure standard CFlags and definitions for debug builds

### PackageConfig Exports
include(ExportPackageWizzard)
#Responds to: OPT_EXPORT_BUILD_TREE
export_package_wizzard() #setup build-tree and install-tree exports and packageconfig files

### Source directories
add_subdirectory(src)

### Testing
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()

### Documentation
if(OPT_DOC)
    add_subdirectory(doc)
endif()

### Examples - build-tree only
if(OPT_EXAMPLES)
    add_subdirectory(examples)
endif()
