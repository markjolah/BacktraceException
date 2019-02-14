# FindGPerfTools.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2019
# see file: LICENSE
#
# Find the google profiler library and tcmalloc implementations
# Provides the GPerfTools::profiler imported target.


find_path(GPerfTools_INCLUDE_DIR NAMES pthread.h PATH_SUFFIXES gperftools)
find_library(GPerfTools_PROFILER_LIBRARY profiler)
find_library(GPerfTools_TCMALLOC_LIBRARY tcmalloc)
find_library(GPerfTools_TCMALLOC_MINIMAL_LIBRARY tcmalloc)
find_library(GPerfTools_TCMALLOC_DEBUG_LIBRARY tcmalloc)
find_library(GPerfTools_TCMALLOC_MINIMAL_DEBUG_LIBRARY tcmalloc_debug)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  GPerfTools
  REQUIRED_VARS
    GPerfTools_PROFILER_LIBRARY
    GPerfTools_INCLUDE_DIR
)

mark_as_advanced(GPerfTools_INCLUDE_DIR
                 GPerfTools_PROFILER_LIBRARY
                 GPerfTools_TCMALLOC_LIBRARY
                 GPerfTools_TCMALLOC_MINIMAL_LIBRARY
                 GPerfTools_TCMALLOC_DEBUG_LIBRARY
                 GPerfTools_TCMALLOC_MINIMAL_DEBUG_LIBRARY)

if(GPerfTools_FOUND AND GPerfTools_PROFILER_LIBRARY AND NOT TARGET GPerfTools::profiler)
    add_library(GPerfTools::profiler SHARED IMPORTED)
    set_target_properties(GPerfTools::profiler PROPERTIES IMPORTED_LOCATION ${GPerfTools_PROFILER_LIBRARY})
    set_property(TARGET GPerfTools::profiler APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${GPerfTools_INCLUDE_DIR})
endif()

if(GPerfTools_FOUND AND GPerfTools_TCMALLOC_LIBRARY AND NOT TARGET GPerfTools::tcmalloc)
    add_library(GPerfTools::tcmalloc SHARED IMPORTED)
    set_target_properties(GPerfTools::tcmalloc PROPERTIES IMPORTED_LOCATION ${GPerfTools_TCMALLOC_LIBRARY})
    set_property(TARGET GPerfTools::tcmalloc APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${GPerfTools_INCLUDE_DIR})
endif()
