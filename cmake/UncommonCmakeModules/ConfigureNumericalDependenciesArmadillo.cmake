# ConfigureNumericalPackages.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# Configure Armadillo, OpenMP, LAPACK, Blas, Pthreads for x-platform parallel numerical packages
# with optional integration into matlab
#

#Enable Inter-proceedural optimization
include(ConfigureIPO)

# Armadillo
find_package(Armadillo REQUIRED)
add_definitions(-DARMA_USE_CXX11)
add_definitions(-DARMA_DONT_USE_WRAPPER)
add_definitions(-DARMA_BLAS_LONG)
add_definitions(-DARMA_DONT_USE_OPENMP) #We want to control the use of openMP at a higher-grained level
add_definitions(-DARMA_DONT_USE_HDF5)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_PRINT_ERRORS>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<NOT:$<CONFIG:Debug>>:ARMA_NO_DEBUG>)
if(OPT_EXTRA_DEBUG)
    set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_EXTRA_DEBUG>)
endif()

# OpenMP
find_package(OpenMP REQUIRED)

# LAPACK & BLAS
find_package(LAPACK REQUIRED)
find_package(BLAS REQUIRED)

# Pthreads
if (WIN32)
    find_library(PTHREAD_LIBRARY libwinpthread.dll REQUIRED)
elseif(UNIX)
    find_library(PTHREAD_LIBRARY libpthread.so REQUIRED)
endif()
#message(STATUS "Found Pthread Libarary: ${PTHREAD_LIBRARY}")
