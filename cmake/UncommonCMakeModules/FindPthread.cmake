# FindPthread.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018-2019
# see file: LICENCE
#
# Find the Pthreads library
# Works on Linux and Win64 in cross-build environments.
# Provides the Pthread::Pthread imported target to link against which
# can provided IMPORTED_LOCATION properties which are not modified on the linker command line
# like like a simple aboslute path in PTHREAD_LIBRARY variable would be.  This functionality
# is mainly necessary for cross-builds on linux where pthreads is possibly found in a non-standard
# location relative to the CMAKE_FIND_ROOT_PATH.


find_path(Pthread_INCLUDE_DIR NAMES pthread.h PATH_SUFFIXES include)

if (WIN32)
    find_library(Pthread_LIBRARY libwinpthread.dll)
elseif(UNIX)
    find_library(Pthread_LIBRARY libpthread.so)
endif()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  Pthread
  REQUIRED_VARS
    Pthread_LIBRARY
    Pthread_INCLUDE_DIR
)

mark_as_advanced(Pthread_INCLUDE_DIR
                 Pthread_LIBRARY)

if(Pthread_FOUND AND NOT TARGET Pthread::Pthread)
    add_library(Pthread::Pthread UNKNOWN IMPORTED)
    set_target_properties(Pthread::Pthread PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES C
        IMPORTED_LOCATION ${Pthread_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES ${Pthread_INCLUDE_DIR})
endif()
