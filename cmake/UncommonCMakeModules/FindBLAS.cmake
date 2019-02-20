# FindBLAS.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2019
# see file: LICENSE
#
# This is a modern Find Module replacement for the standard FindBLAS.cmake modules that produces IMPORTED targets for BLAS and CBLAS
# using pkg-config, and also identifying Static, threaded, and int64 target versions of BLAS and CBLAS, for a variety of implementations.
#
# The main problem with the built-in FindBLAS.cmake is that it uses the built-in FindPkgConfig.cmake which is not CMAKE_CROSSCOMPILING aware, and does not properly
# modify the PKG_CONFIG_LIBDIR, PKG_CONFIG_SYSROOT_DIR, and PKG_CONFIG_PATH as required.  See: e.g., https://autotools.io/pkgconfig/cross-compiling.html.
# Since modern linux distributions and cross-build sysroots normally have functioning pkg-config settings, it is best to use pkg-config as default if possible to
# correctly detect CFLAGS and library names, and correctly respect the usage on non-system root prefixes.
#
# Controlling variables:
#   OPT_DISABLE_PKG_CONFIG - If defined and true, disable the pkg-config based BLAS and BLAS searching and use the built-in FindBLAS.cmake and FindLAPCK.cmake.
#   CMAKE_SYSROOT - Used to initialize the pkg-config sysroot variables if cross-compiling
#   PKG_CONFIG_SUFFIX_INT64 - [default: "-int64"]
#   PKG_CONFIG_SUFFIX_THREADS - [default: "-threads"]
#
#   BLAS_PKG_CONFIG_NAMES - List of names to use in priority ordering of blas module pkg-config module names. [e.g., "blas;openblas;refblas"]
#
#  Optional overrides to further customize pkg-config names for Int64 and threads versions.
#   BLAS_THREADS_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
#   BLAS_INT64_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
#   BLAS_INT64_THREADS_PKG_CONFIG_NAMES - List of names to use in priority ordering of [int64] module pkg-config module names.
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
#   BLAS_INT64 - Enable finding of 64-bit integer targets
#   BLAS_INT32 - Accepted for compatibility.  Always enables 32-bit integer targets if available.
#   THREADS - Enable finding of threaded targets
#   STATIC - Enable finding of static targets
#   CBLAS - Find CBLAS targets also.
#
# Attempts to find the libraries and setting from pkg-config the following Imported TARGETS
# BLAS imported targets
#   BLAS::Blas                   - BLAS int32 shared libs
#   BLAS::BlasStatic             - BLAS int32 static libs
#   BLAS::BlasThreads            - BLAS int32 shared libs with threading
#   BLAS::BlasThreadsStatic      - BLAS int32 static libs with threading
#   BLAS::BlasInt64              - BLAS int64 shared libs
#   BLAS::BlasInt64Static        - BLAS int64 static libs
#   BLAS::BlasInt64Threads       - BLAS int64 shared libs with threading
#   BLAS::BlasInt64ThreadsStatic - BLAS int64 static libs with threading
#
# CBLAS imported targets [if C or CXX Language are enabled]
#   CBLAS::CBlas                   - CBLAS int32 shared libs
#   CBLAS::CBlasStatic             - CBLAS int32 static libs
#   CBLAS::CBlasThreads            - CBLAS int32 shared libs with threading
#   CBLAS::CBlasThreadsStatic      - CBLAS int32 static libs with threading
#   CBLAS::CBlasInt64              - CBLAS int64 shared libs
#   CBLAS::CBlasInt64Static        - CBLAS int64 static libs
#   CBLAS::CBlasInt64Threads       - CBLAS int64 shared libs with threading
#   CBLAS::CBlasInt64ThreadsStatic - CBLAS int64 static libs with threading
#
# For lib in: BLAS, BLAS_STATIC, BLAS_THREADS, BLAS_THREADS_STATIC, BLAS_INT64, BLAS_INT64_STATIC, BLAS_INT64_THREADS, BLAS_INT64_THREADS_STATIC
#   ${LIB}_FOUND - True if LIB was found.
#   ${LIB}_PKGCONFIG_FOUND - True if LIB was found via pkg-config.
#
include(${CMAKE_CURRENT_LIST_DIR}/MakePkgConfigTarget.cmake)

#Default BLAS names to search for in decreasing order of importance
if(NOT BLAS_PKG_CONFIG_NAMES)
    set(BLAS_PKG_CONFIG_NAMES blas openblas goto2 refblas blas-netlib blas-reference)
endif()

if(NOT CBLAS_PKG_CONFIG_NAMES)
    set(CBLAS_PKG_CONFIG_NAMES cblas openblas goto2 refcblas)
endif()

if(NOT PKG_CONFIG_SUFFIX_INT64)
    set(PKG_CONFIG_SUFFIX_INT64 "-int64")
endif()

if(NOT PKG_CONFIG_SUFFIX_THREADS)
    set(PKG_CONFIG_SUFFIX_THREADS "-threads")
endif()

if(NOT BLAS_USE_PKG_CONFIG)
    set(BLAS_USE_PKG_CONFIG False)
    if(NOT OPT_DISABLE_PKG_CONFIG)
        find_package(PkgConfig)
        if(PKG_CONFIG_FOUND AND EXISTS ${PKG_CONFIG_EXECUTABLE})
            set(BLAS_USE_PKG_CONFIG True)
        else()
            message(STATUS "[FindBLAS] pkg-config not found.  Disabling pkg-config based search.")
            find_package(BLAS)
        endif()
    endif()
endif()

#Create all the targets
set(_LIBS Blas)
get_property(_LANGS GLOBAL PROPERTY ENABLED_LANGUAGES)
if((CXX IN_LIST _LANGS OR C IN_LIST _LANGS) AND CBLAS IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
    list(APPEND _LIBS CBlas) #enable CBLAS
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
            #list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_THREADS} OUTPUT_VARIABLE ${_LIB}_THREADS_PKG_CONFIG_NAMES) #Requires cmake 3.12
            string(REGEX REPLACE "([^;]+)" "\\1${PKG_CONFIG_SUFFIX_THREADS}" ${_LIB}_THREADS_PKG_CONFIG_NAMES "${${_LIB}_PKG_CONFIG_NAMES}")
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Threads PCNAMES ${${_LIB}_THREADS_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_THREADS NAMESPACE ${_LIB} TARGET ${_lib}ThreadsStatic STATIC PCNAMES ${${_LIB}_THREADS_PKG_CONFIG_NAMES})
        endif()
    endif()

    #int64 shared/static
    if(BLAS_INT64 IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        if(NOT ${_LIB}_INT64_PKG_CONFIG_NAMES)
            #list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_INT64} OUTPUT_VARIABLE ${_LIB}_INT64_PKG_CONFIG_NAMES) #Requires cmake 3.12
            string(REGEX REPLACE "([^;]+)" "\\1${PKG_CONFIG_SUFFIX_INT64}" ${_LIB}_INT64_PKG_CONFIG_NAMES "${${_LIB}_PKG_CONFIG_NAMES}")
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_INT64 NAMESPACE ${_LIB} TARGET ${_lib}Int64 PCNAMES ${${_LIB}_INT64_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_INT64 NAMESPACE ${_LIB} TARGET ${_lib}Int64Static STATIC PCNAMES ${${_LIB}_INT64_PKG_CONFIG_NAMES})
        endif()
    endif()

    #int64 shared/static with threads
    if(BLAS_INT64 IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS AND THREADS IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        if(NOT ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES)
            #list(TRANSFORM ${_LIB}_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_INT64} OUTPUT_VARIABLE ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES) #Requires cmake 3.12
            #list(TRANSFORM ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES APPEND ${PKG_CONFIG_SUFFIX_THREADS}) #Requires cmake 3.12
            string(REGEX REPLACE "([^;]+)" "\\1${PKG_CONFIG_SUFFIX_INT64}${PKG_CONFIG_SUFFIX_THREADS}" ${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES "${${_LIB}_PKG_CONFIG_NAMES}")
        endif()
        make_pkg_config_target(VAR_NAME ${_LIB}_INT64_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Int64Threads PCNAMES ${${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES})
        if(STATIC IN_LIST ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
            make_pkg_config_target(VAR_NAME ${_LIB}_INT64_THREADS NAMESPACE ${_LIB} TARGET ${_lib}Int64ThreadsStatic STATIC PCNAMES ${${_LIB}_INT64_THREADS_PKG_CONFIG_NAMES})
        endif()
    endif()
endforeach()
unset(_LIBS)
unset(_lib)
unset(_LIB)
