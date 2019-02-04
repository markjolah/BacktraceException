# FindLAPACK.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2019
# see file: LICENCE
#
# This is a modern Find Module replacement for the standard FindLAPACK.cmake modules that produces IMPORTED targets for LAPACK and LAPACKE
# using pkg-config, and also identifying Static, threaded, and int64 target versions of LAPACK and LAPACKE, for a variety of implementations.
#
# The main problem with the built-in FindLAPACK.cmake is that it uses the built-in FindPkgConfig.cmake which is not CMAKE_CROSSCOMPILING aware, and does not properly
# modify the PKG_CONFIG_LIBDIR, PKG_CONFIG_SYSROOT_DIR, and PKG_CONFIG_PATH as required.  See: e.g., https://autotools.io/pkgconfig/cross-compiling.html.
# Since modern linux distributions and cross-build sysroots normally have functioning pkg-config settings, it is best to use pkg-config as default if possible to
# correctly detect CFLAGS and library names, and correctly respect the usage on non-system root prefixes.
#
# Controlling variables:
#   OPT_DISABLE_PKG_CONFIG - If defined and true, disable the pkg-config based LAPACK and LAPACK searching and use the built-in FindLAPACK.cmake and FindLAPCK.cmake.
#   CMAKE_SYSROOT - Used to initialize the pkg-config sysroot variables if cross-compiling
#   PKG_CONFIG_SUFFIX_INT64 - [default: "-int64"]
#   PKG_CONFIG_SUFFIX_THREADS - [default: "-threads"]
#
#   LAPACK_PKG_CONFIG_NAMES - List of names to use in priority ordering of blas module pkg-config module names. [e.g., "blas;openblas;refblas"]
#
#  Optional overrides to further customize pkg-config names for Int64 and threads versions.
#   LAPACK_THREADS_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
#   LAPACK_INT64_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
#   LAPACK_INT64_THREADS_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
#
#   The following variables can be used to override the use of pkg_config.  If {LIB}_FOUND is not set, the other variables will be ignored, and pkg-config will be used.
#   {LIB}_FOUND
#   {LIB}_LIBRARIES
#   {LIB}_LINKER_FLAGS
#   {LIB}_LINKER_DIRS
#   {LIB}_INCLUDE_DIRS
#   {LIB}_COMPILE_DEFINITIONS
#   {LIB}_COMPILE_OPTIONS
#
# find_package COMPONENTS respected:
#   INT64 - Enable finding of 64-bit integer targets
#   THREADS - Enable finding of threaded targets
#   STATIC - Enable finding of static targets
#   LAPACKE - Find LAPACKE targets also.
#
# Attempts to find the libraries and setting from pkg-config the following Imported TARGETS
# LAPACK imported targets
#   LAPACK::LAPACK                   - LAPACK int32 shared libs
#   LAPACK::LAPACKStatic             - LAPACK int32 static libs
#   LAPACK::LAPACKThreads            - LAPACK int32 shared libs with threading
#   LAPACK::LAPACKThreadsStatic      - LAPACK int32 static libs with threading
#   LAPACK::LAPACKInt64              - LAPACK int64 shared libs
#   LAPACK::LAPACKInt64Static        - LAPACK int64 static libs
#   LAPACK::LAPACKInt64Threads       - LAPACK int64 shared libs with threading
#   LAPACK::LAPACKInt64ThreadsStatic - LAPACK int64 static libs with threading
#
# LAPACKE imported targets [if CXX Language is enabled]
#   LAPACKE::LAPACKE                   - LAPACKE int32 shared libs
#   LAPACKE::LAPACKEStatic             - LAPACKE int32 static libs
#   LAPACKE::LAPACKEThreads            - LAPACKE int32 shared libs with threading
#   LAPACKE::LAPACKEThreadsStatic      - LAPACKE int32 static libs with threading
#   LAPACKE::LAPACKEInt64              - LAPACKE int64 shared libs
#   LAPACKE::LAPACKEInt64Static        - LAPACKE int64 static libs
#   LAPACKE::LAPACKEInt64Threads       - LAPACKE int64 shared libs with threading
#   LAPACKE::LAPACKEInt64ThreadsStatic - LAPACKE int64 static libs with threading
#
# For lib in: LAPACK, LAPACK_STATIC, LAPACK_THREADS, LAPACK_THREADS_STATIC, LAPACK_INT64, LAPACK_INT64_STATIC, LAPACK_INT64_THREADS, LAPACK_INT64_THREADS_STATIC
#             LAPACKE, LAPACKE_STATIC, LAPACKE_THREADS, LAPACKE_THREADS_STATIC, LAPACKE_INT64, LAPACKE_INT64_STATIC, LAPACKE_INT64_THREADS, LAPACKE_INT64_THREADS_STATIC
#   ${LIB}_FOUND - True if LIB was found.
#   ${LIB}_PKGCONFIG_FOUND - True if LIB was found via pkg-config.
#
include(${CMAKE_CURRENT_LIST_DIR}/MakePkgConfigTarget.cmake)

#Default LAPACK names to search for in decreasing order of importance
if(NOT LAPACK_PKG_CONFIG_NAMES)
    set(LAPACK_PKG_CONFIG_NAMES lapack reflapack)
endif()

if(NOT LAPACKE_PKG_CONFIG_NAMES)
    set(LAPACKE_PKG_CONFIG_NAMES lapacke reflapacke)
endif()

if(NOT PKG_CONFIG_SUFFIX_INT64)
    set(PKG_CONFIG_SUFFIX_INT64 "-int64")
endif()

if(NOT PKG_CONFIG_SUFFIX_THREADS)
    set(PKG_CONFIG_SUFFIX_THREADS "-threads")
endif()

if(NOT LAPACK_USE_PKG_CONFIG)
    set(LAPACK_USE_PKG_CONFIG False)
    if(NOT OPT_DISABLE_PKG_CONFIG)
        find_package(PkgConfig)
        if(PKG_CONFIG_FOUND AND EXISTS ${PKG_CONFIG_EXECUTABLE})
            set(LAPACK_USE_PKG_CONFIG True)
        else()
            message(STATUS "[FindLAPACK] pkg-config not found.  Disabling pkg-config based search.")
            find_package(LAPACK)
        endif()
    endif()
endif()

#Create all the targets
set(_LIBS Lapack)
get_property(_LANGS GLOBAL PROPERTY ENABLED_LANGUAGES)
if(CXX IN_LIST _LANGS AND LAPACKE IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
    list(APPEND _LIBS Lapacke) #enable LAPACKE for C++
endif()
unset(_LANGS)
foreach(_lib IN LISTS _LIBS)
    string(TOUPPER ${_lib} _LIB)
    #int32 shared/static
    make_pkg_config_target(VAR_NAME ${_LIB} NAMESPACE ${_LIB} TARGET ${_lib} PCNAMES ${${_LIB}_PKG_CONFIG_NAMES})
    if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        make_pkg_config_target(VAR_NAME ${_LIB} NAMESPACE ${_LIB} TARGET ${_lib}Static STATIC PCNAMES ${${_LIB}_PKG_CONFIG_NAMES})
    endif()

    #int32 shared/static with threads
    if(THREADS IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        if(NOT ${_LIB}_THREADS_PKG_CONFIG_NAMES)
            list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_THREADS} OUTPUT_VARIABLE ${_LIB}_THREADS_PKG_CONFIG_NAMES)
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Threads PCNAMES ${${_LIB}_THREADS_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_THREADS NAMESPACE ${_LIB} TARGET ${_lib}ThreadsStatic STATIC PCNAMES ${${_LIB}_THREADS_PKG_CONFIG_NAMES})
        endif()
    endif()

    #int64 shared/static
    if(INT64 IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        if(NOT ${_LIB}_INT64_PKG_CONFIG_NAMES)
            list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_INT64} OUTPUT_VARIABLE ${_LIB}_INT64_PKG_CONFIG_NAMES)
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_INT64 NAMESPACE ${_LIB} TARGET ${_lib}Int64 PCNAMES ${${_LIB}_INT64_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_INT64 NAMESPACE ${_LIB} TARGET ${_lib}Int64Static STATIC PCNAMES ${${_LIB}_INT64_PKG_CONFIG_NAMES})
        endif()
    endif()

    #int64 shared/static with threads
    if(INT64 IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS AND THREADS IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        if(NOT ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES)
            list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_INT64} OUTPUT_VARIABLE ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES)
            list(TRANSFORM ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_THREADS})
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_INT64_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Int64Threads PCNAMES ${${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_INT64_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Int64ThreadsStatic STATIC PCNAMES ${${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES})
        endif()
    endif()
endforeach()
unset(_LIBS)
unset(_lib)
unset(_var_name)
