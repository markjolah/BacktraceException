# FindArmadillo.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# Recognized Components:
#  CXX11 - Add C++11 support
#  INT64 - 64-bit integer support for armadillo and BLAS/LAPACK
#  WRAPPER - Use the system armadillo wrapper armadillo.so
#  BLAS - Add BLAS support
#  LAPACK - Add LAPACK support
#  SuperLU - Add SuperLU support
#  OpenMP - Add openMP parallelization
#  HDF5 - Add HDF5 support
#
# Find TARGETS
#   Armadillo::Armadillo
#
#  Respected options:
#    OPT_EXTRA_DEBUG - Enable extra debugging support [very noisy]
#
# The armadillo library has several macro definitions that are critical to enabling or disabling
# various libraries and features, as well as C++11 compliance and integer sizing.  These include
# positive flags (e.g., ARMA_USE_BLAS) and negative flags (e.g., ARMA_DONT_USE_BLAS).  The negative
# flags override the positive.  To enable a two different libraries that use different Armadillo
# modules to work together in a larger application, the downstream libraries should use the negative
# flags as private to build their own library, but not to be exported to force other libraries that do
# use those dependencies to erroneously inherit the negative definition flags.  Positive flags however
# need to be set as public, since all further downstream libraries will need them set in order to use
# the advanced features of the importing library.  To enable proper downstream dependency compile
# definitions propagation, users should:
#  1. use find_package(Armadillo COMPONENTS ...) with only those components that are directly needed
#     by the library/program.  Other dependencies that use Armadillo and this find module will
#     re-check and possibly enable more components when they call find_dependency(Armadillo) from
#     their cmake package config file, using their own particular set of required components.
#  2. When adding a target dependent on armadillo do the following:
#       target_link_libraries(Foo PUBLIC Armadillo::Armadillo)
#       target_compile_definitions(Foo PRIVATE ARMADILLO_PRIVATE_COMPILE_DEFINITIONS)
#  3. When writing the PackageConfig.cmake template use find_dependency(Armadillo COMPONENTS ...)
#     with the same components specified as in step 1.
#
# Notes:
#  i.  Armadillo::Armadillo will not directly add Blas,Lapack, SuperLU, OpenMP, or HDF5 dependencies to the
#      interface link libraries if the WRAPPER component is not specfied.  This allows users to find and link
#      these target dependencies themselves potentially using customized find modules.  These libraries must
#      also match the integer type INT64 signature, and optionally other ARMA_ defines may need to be added to modify
#      the Blas symbol names to correctly match capitalization and trailing underscores.  One option is to use
#      the associated FindBLAS.cmake and FindLAPACK.cmake in UncommonCMakeModules which use pkg-config to make
#      proper IMPORTED targets Blas::Blas and Blas::BlasInt64, etc.
find_library(ARMADILLO_WRAPPER NAMES armadillo)
find_path(ARMADILLO_INCLUDE_DIR NAMES armadillo)

if(NOT ARMADILLO_FOUND AND ARMADILLO_INCLUDE_DIR)
    file(READ "${ARMADILLO_INCLUDE_DIR}/armadillo_bits/arma_version.hpp" ARMA_CONFIG)
    string(REGEX MATCH "#define[ \t]+ARMA_VERSION_MAJOR[ \t]+([0-9]+)" _VER ${ARMA_CONFIG})
    set(ARMADILLO_VERSION_MAJOR ${CMAKE_MATCH_1})
    string(REGEX MATCH "#define[ \t]+ARMA_VERSION_MINOR[ \t]+([0-9]+)" _VER ${ARMA_CONFIG})
    set(ARMADILLO_VERSION_MINOR ${CMAKE_MATCH_1})
    string(REGEX MATCH "#define[ \t]+ARMA_VERSION_PATCH[ \t]+([0-9]+)" _VER ${ARMA_CONFIG})
    set(ARMADILLO_VERSION_PATCH ${CMAKE_MATCH_1})
    set(ARMADILLO_VERSION_STRING ${ARMADILLO_VERSION_MAJOR}.${ARMADILLO_VERSION_MINOR}.${ARMADILLO_VERSION_PATCH})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Armadillo
  REQUIRED_VARS
    ARMADILLO_WRAPPER
    ARMADILLO_INCLUDE_DIR
  VERSION_VAR
    ARMADILLO_VERSION_STRING
)
mark_as_advanced(ARMADILLO_WRAPPER ARMADILLO_INCLUDE_DIR ARMADILLO_VERSION_STRING)

if(NOT TARGET Armadillo::Armadillo)
    #No other calls to find_package(Armadillo) set up the target and component lists
    add_library(Armadillo::Armadillo INTERFACE IMPORTED)
    if(${ARMADILLO_VERSION_STRING} VERSION_LESS 9999) #Re-enable once fixed in futrue armadillo
        target_compile_options(Armadillo::Armadillo INTERFACE -Wno-unused-local-typedefs) # Necessary for armadillo 9.200.6 warnings
    endif()
    target_include_directories(Armadillo::Armadillo INTERFACE ${ARMADILLO_INCLUDE_DIR})
    target_compile_definitions(Armadillo::Armadillo INTERFACE $<$<CONFIG:Debug>:ARMA_PRINT_ERRORS>)
    target_compile_definitions(Armadillo::Armadillo INTERFACE $<$<NOT:$<CONFIG:Debug>>:ARMA_NO_DEBUG>)
    if(OPT_EXTRA_DEBUG)
        target_compile_definitions(Armadillo::Armadillo INTERFACE $<$<CONFIG:Debug>:ARMA_EXTRA_DEBUG>)
    endif()

    set(ARMADILLO_ENABLED_COMPONENTS ${Armadillo_FIND_COMPONENTS})
    set(ARMADILLO_PRIVATE_COMPILE_DEFINITIONS)
else()
    #Check for components that must agree between multiple armadillo using dependencies
    foreach(_comp IN ITEMS CXX11 INT64)
        if((${_comp} IN_LIST Armadillo_FIND_COMPONENTS AND NOT ${_comp} IN_LIST ARMADILLO_ENABLED_COMPONENTS) OR
           (NOT ${_comp} IN_LIST Armadillo_FIND_COMPONENTS AND ${_comp} IN_LIST ARMADILLO_ENABLED_COMPONENTS))
            message(FATAL_ERROR "[FindArmadillo] Armadillo is initialized multiple times (by dependencies) with different values for Armadillo component ${_comp} All dependencies must agree on ${_comp} component flag for FindArmadillo.")
        endif()
    endforeach()
endif()

if(WRAPPER IN_LIST ARMADILLO_ENABLED_COMPONENTS)
    target_compile_definitions(Armadillo::Armadillo INTERFACE ARMA_USE_WRAPPER)
    target_link_libraries(Armadillo::Armadillo INTERFACE ${ARMADILLO_WRAPPER})
    list(REMOVE_ITEM ARMADILLO_PRIVATE_COMPILE_DEFINITIONS ARMA_DONT_USE_WRAPPER)
else()
    if(NOT ARMA_DONT_USE_WRAPPER IN_LIST ARMADILLO_PRIVATE_COMPILE_DEFINITIONS)
        list(APPEND ARMADILLO_PRIVATE_COMPILE_DEFINITIONS ARMA_DONT_USE_WRAPPER)
    endif()
endif()

foreach(_comp IN ITEMS BLAS LAPACK SUPERLU HDF5 OPENMP)
    if(${_comp} IN_LIST ARMADILLO_ENABLED_COMPONENTS)
        target_compile_definitions(Armadillo::Armadillo INTERFACE ARMA_USE_${_comp})
        list(REMOVE_ITEM ARMADILLO_PRIVATE_COMPILE_DEFINITIONS ARMA_DONT_USE_${_comp})
    else()
        list(APPEND ARMADILLO_PRIVATE_COMPILE_DEFINITIONS ARMA_DONT_USE_${_comp})
    endif()
endforeach()
unset(_comp)

if(LAPACK IN_LIST ARMADILLO_ENABLED_COMPONENTS)
    target_compile_definitions(Armadillo::Armadillo INTERFACE ARMA_USE_NEWARP) #Use Armadillo Built-in ARPACK
endif()
if(CXX11 IN_LIST ARMADILLO_ENABLED_COMPONENTS)
    target_compile_features(Armadillo::Armadillo INTERFACE cxx_std_11)
    target_compile_definitions(Armadillo::Armadillo INTERFACE ARMA_USE_CXX11)
endif()
if(INT64 IN_LIST ARMADILLO_ENABLED_COMPONENTS)
    target_compile_definitions(Armadillo::Armadillo INTERFACE ARMA_64BIT_WORD ARMA_BLAS_LONG_LONG)
endif()

set(ARMADILLO_ENABLED_COMPONENTS "${ARMADILLO_ENABLED_COMPONENTS}" CACHE STRING "Enabled Armadillo components." FORCE)
set(ARMADILLO_PRIVATE_COMPILE_DEFINITIONS "${ARMADILLO_PRIVATE_COMPILE_DEFINITIONS}" CACHE STRING "Enabled Armadillo components." FORCE)
mark_as_advanced(ARMADILLO_ENABLED_COMPONENTS ARMADILLO_PRIVATE_COMPILE_DEFINITIONS)
