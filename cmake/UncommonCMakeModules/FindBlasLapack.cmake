# FindBlasLapack.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2019
# see file: LICENCE
#
# This is a modern Find Module for BLAS and LAPACK libraries.  This is a replacement for the standard FindBLAS.cmake and FindLAPACK.cmake modules,
# they can be used as the primary or secondary sources for the libraries.  To allow simultaneous existence with the standard FindBLAS and FindLAPACK modules we use
# the separate BLASLAPACK "find_package" namespace.
#
# The main problem with the built-in FindBLAS.cmake is that it uses the built in FindPkgConfig.cmake which is not CMAKE_CROSSCOMPILING aware, and does not properly
# modify the PKG_CONFIG_LIBDIR and PKG_CONFIG_SYSROOT_DIR, PKG_CONFIG_PATH as required.  See: e.g., https://autotools.io/pkgconfig/cross-compiling.html.
#
# Since modern linux distributions and cross-build sysroots normally have functioning pkg-config settings, it is best to use pkg-config as default if possible to
# correctly detect CFLAGS and library names, and correctly respect the usage on non-system root prefixes.  This leads to a more robust method is much more robust
# than the built-in FindBLAS.cmake
#
# Additional, we provide properly scoped Imported Targets for BLAS and Lapack and for the Int64 variant if found.
#
# Controlling variables:
#   OPT_DISABLE_BLAS_LAPACK_PKG_CONFIG - If defined and true, disable the pkg-config based BLAS and LAPACK searching and use the built-in FindBLAS.cmake and FindLAPCK.cmake.
#   CMAKE_SYSROOT - Used to initialize the pkg-config sysroot variables if cross-compiling
#   BLASLAPACK_INT64_PKG_CONFIG_SUFFIX - [default: "-int64"]
#   BLASLAPACK_THREADS_PKG_CONFIG_SUFFIX - [default: "-threads"]
#   BLASLAPACK_STATIC_PKG_CONFIG_SUFFIX -  [default: "-static"]
#   BLAS_PKGCONFIG_NAMES - List of names to use in priority ordering of blas module pkg-config module names. [e.g., "blas;openblas;refblas"]
#   CBLAS_PKGCONFIG_NAMES - List of names to use in priority ordering of cblas module pkg-config module names. [e.g., "cblas;openblas;refblas"]
#   LAPACK_PKGCONFIG_NAMES - List of names to use in priority ordering of lapack module pkg-config module names. [e.g., "lapack;reflapack"]
#   LAPACKE_PKGCONFIG_NAMES - List of names to use in priority ordering of lapacke module pkg-config module names. [e.g., "lapacke;reflapacke"]
#
#   For each LIB: BLAS, CBLAS, LAPACK, LAPACKE, the following overrides can be set
#   {LIB}_INT64_PKGCONFIG_NAMES - List of names to use in priority ordering of blas [int64] module pkg-config module names. [e.g., "blas-int64;openblas-int64;refblas-int64"].
#                                 Default: use {LIB}_PKGCONFIG_NAMES with BLASLAPACK_INT64_PKGCONFIG_SUFFIX
#   {LIB}_INT64_THREADS_PKGCONFIG_NAMES - List of names to use in priority ordering of blas [int64,threads] module pkg-config module names. [e.g., "blas-int64-threads;openblas-int64-threads;refblas-int64-threads"]
#                                 Default: use {LIB}_PKGCONFIG_NAMES with BLASLAPACK_INT64_PKGCONFIG_SUFFIX and BLASLAPACK_THREADS_PKGCONFIG_SUFFIX
#   {LIB}_INT64_STATIC_PKGCONFIG_NAMES - List of names to use in priority ordering of blas [int64,static] module pkg-config module names. [e.g., "blas-int64-static;openblas-int64-static;refblas-int64-static"]
#                                 Default: use {LIB}_PKGCONFIG_NAMES with BLASLAPACK_INT64_PKGCONFIG_SUFFIX and BLASLAPACK_STATIC_PKGCONFIG_SUFFIX
#   {LIB}_THREADS_PKGCONFIG_NAMES - List of names to use in priority ordering of blas [threads] module pkg-config module names. [e.g., "blas-threads;openblas-threads;refblas-threads"]
#                                 Default: use {LIB}_PKGCONFIG_NAMES with BLASLAPACK_THREADS_PKGCONFIG_SUFFIX
#   {LIB}_STATIC_PKGCONFIG_NAMES - List of names to use in priority ordering of blas [static] module pkg-config module names. [e.g., "blas-static;openblas-static;refblas-static"]
#                                 Default: use {LIB}_PKGCONFIG_NAMES with BLASLAPACK_STATIC_PKGCONFIG_SUFFIX
#
#   For each LIB: BLAS, CBLAS, LAPACK, LAPACKE; possibly including _INT64,_INT64_THREADS, _INT64_STATIC,  _THREADS, or _STATIC suffixes, the following variables
#    can be used to avoid using pkg_config.  If {LIB}_FOUND is not set.  The other variables will be ignored, and pkg-config will be used.
#   {LIB}_FOUND
#   {LIB}_LIBRARIES
#   {LIB}_LINKER_FLAGS
#   {LIB}_LIB_DIRS
#   {LIB}_INCLUDE_DIRS
#   {LIB}_COMPILE_DEFINITIONS
#   {LIB}_COMPILE_OPTIONS

#
# Attempts to find the libraries and setting from pkg-config the following Imported TARGETS
# Blas imported targets
#   Blas::Blas              - Blas int32 shared libs
#   Blas::BlasThreads       - Blas int32 shared libs with threading
#   Blas::BlasStatic        - Blas int32 static libs
#   Blas::BlasInt64         - Blas int64 shared libs
#   Blas::BlasInt64Threads  - Blas int64 shared libs with threading
#   Blas::BlasInt64Static   - Blas int64 static libs
#
# CBlas imported targets
#   CBlas::CBlas              - CBlas int32 shared libs
#   CBlas::CBlasThreads       - CBlas int32 shared libs with threading
#   CBlas::CBlasStatic        - CBlas int32 static libs
#   CBlas::CBlasInt64         - CBlas int64 shared libs
#   CBlas::CBlasInt64Threads  - CBlas int64 shared libs with threading
#   CBlas::CBlasInt64Static   - CBlas int64 static libs
#
# Lapack imported targets
#   Lapack::Lapack              - Lapack int32 shared libs
#   Lapack::LapackThreads       - Lapack int32 shared libs with threading
#   Lapack::LapackStatic        - Lapack int32 static libs
#   Lapack::LapackInt64         - Lapack int64 shared libs
#   Lapack::LapackInt64Threads  - Lapack int64 shared libs with threading
#   Lapack::LapackInt64Static   - Lapack int64 static libs
#
# Lapacke imported targets
#   Lapacke::Lapacke              - Lapacke int32 shared libs
#   Lapacke::LapackeThreads       - Lapacke int32 shared libs with threading
#   Lapacke::LapackeStatic        - Lapacke int32 static libs
#   Lapacke::LapackeInt64         - Lapacke int64 shared libs
#   Lapacke::LapackeInt64Threads  - Lapacke int64 shared libs with threading
#   Lapacke::LapackeInt64Static   - Lapacke int64 static libs


# This set of advanced cache variables determines if the modules was found with PKGCONFIG via this Find module, or if not then manually or via the built-in BLAS and LAPACK.
# For lib in: BLAS, BLAS_THREADS, BLAS_STATIC, BLAS_INT64, BLAS_INT64_THREADS, BLAS_INT64_STATIC, \
#             CBLAS, CBLAS_THREADS, CBLAS_STATIC, CBLAS_INT64, CBLAS_INT64_THREADS, CBLAS_INT64_STATIC
#             LAPACK, LAPACK_THREADS, LAPACK_STATIC, LAPACK_INT64, LAPACK_INT64_THREADS, LAPACK_INT64_STATIC
#             LAPACKE, LAPACKE_THREADS, LAPACKE_STATIC, LAPACKE_INT64, LAPACKE_INT64_THREADS, LAPACKE_INT64_STATIC
#   ${LIB}_FOUND - True if LIB was found.
#   ${LIB}_PKGCONFIG_FOUND - True if LIB was found via pkg-config.

#get_pkg_config(ret_var pcname pcflags...)
# Check if pcname is known to pkg-config
# Returns:
#  Boolean: true if ${pcname}.pc file is found by pkg-config).
# Args:
#  ret_var: return variable name.
#  pcname: pkg-config name to look for (.pc file)
function(check_pkg_config ret_var pcname)
    execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --exists ${pcname} RESULT_VARIABLE _found)
    if(_found EQUAL 0)
        set(${ret_var} True PARENT_SCOPE)
    else()
        set(${ret_var} False PARENT_SCOPE)
    endif()
endfunction()

#get_pkg_config(ret_var pcname pcflags...)
# Get the output of pkg-config
# Args:
#  ret_var: return variable name
#  pcname: pkg-config name to look for (.pc file)
#  pcflags: pkg-config flags to pass
function(get_pkg_config ret_var pcname)
    execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} ${ARGN} ${pcname} OUTPUT_VARIABLE _out RESULT_VARIABLE _ret OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_ret EQUAL 0)
        set(${ret_var} ${_out} PARENT_SCOPE)
    else()
        set(${ret_var} "" PARENT_SCOPE)
    endif()
endfunction()

# make_pkg_config_target(target_var_name target_name [STATIC] pkg_config_names... )
# Options:
#   STATIC - Find static libs.  Will pass --static args to pkg_config
# Single Value Args:
#   VAR_NAME  - Name to use for checking relevent CMake CACHE variables.  Normally uppercase. [e.g., BLAS, LAPACK, BLAS_INT64, etc.]
#   NAMESPACE - Namespace to create target at (:: optional)
#   TARGET - Name of target to create (w/o namepace)
# Mulitvalue args:
#   PCNAMES - List of pkg-config .pc names to check for in order.  The first one found is used to set target properties.
# target_name - Name of target with namespace(s) [e.g., Blas::Blas, Lapack::Lapack, Blas::BlasInt64, etc.]
# pkg_config_names -
#
function(make_pkg_config_target)
    set(options STATIC)
    set(oneValueArgs VAR_NAME NAMESPACE TARGET)
    set(multiValueArgs PCNAMES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "[BLASLAPACK:get_pkg_config] Unknown keywords given: \"${ARG_UNPARSED_ARGUMENTS}\"")
    endif()

    set(_FOUND False)
    set(_FOUND_PKG_CONFIG False)
    if(ARG_STATIC)
        set(_static_flags --static)
    else()
        set(_static_flags)
    endif()
    string(REGEX REPLACE "::" "" ARG_NAMESPACE ${ARG_NAMESPACE})
    set(target_name ${ARG_NAMESPACE}::${ARG_TARGET})
    set(target_var_name ${ARG_VAR_NAME})
    if(TARGET ${target_name} AND ${target_var_name}_FOUND)
        return()
    elseif(${target_var_name}_FOUND AND ${target_var_name}_LIBRARIES)
        #Found independently, perhaps through CMake default FindBLAS.cmake or FindLAPACK.cmake
        #These should have set ${target_var_name}_LIBRARIES and ${target_var_name}_LINKER_FLAGS at a minimum.
        add_library(${target_name} SHARED IMPORTED)
        target_link_libraries(${target_name} INTERFACE ${${target_var_name}_LIBRARIES})
        if(${target_var_name}_LINKER_FLAGS)
            target_link_options(${target_name} INTERFACE ${${target_var_name}_LINKER_FLAGS})
        endif()
        if(${target_var_name}_INCLUDE_DIRS)
            target_include_directories(${target_name} INTERFACE ${${target_var_name}_INCLUDE_DIRS})
        endif()
        if(${target_var_name}_COMPILE_DEFINITIONS)
            target_compile_definitions(${target_name} INTERFACE ${${target_var_name}_COMPILE_DEFINITIONS})
        endif()
        if(${target_var_name}_COMPILE_OPTIONS)
            target_compile_options(${target_name} INTERFACE ${${target_var_name}_COMPILE_OPTIONS})
        endif()
        if(${target_var_name}_LINK_DIRS)
            target_link_directories(${target_name} INTERFACE ${${target_var_name}_LINK_DIRS})
        endif()
        message(STATUS "[BLASLAPACK] Found ${target_name} manually specified")
        set(_FOUND True)
    elseif(BLASLAPACK_USE_PKG_CONFIG) #Look in pkg_config
        foreach(pkg_config_name IN LISTS ARG_PCNAMES)
            check_pkg_config(_FOUND ${pkg_config_name})
            if(_FOUND)
                get_pkg_config(_INCLUDES ${pkg_config_name} "--cflags-only-I" ${_static_flags})
                get_pkg_config(_CFLAGS ${pkg_config_name} "--cflags-only-other" ${_static_flags})
                get_pkg_config(_LIB_DIRS ${pkg_config_name} "--libs-only-L" ${_static_flags})
                get_pkg_config(_LIBS ${pkg_config_name} "--libs-only-l" ${_static_flags})
                get_pkg_config(_LINKER_OPTS ${pkg_config_name} "--libs-only-other" ${_static_flags})

                string(REGEX REPLACE "^-I" "" _INCLUDES "${_INCLUDES}")
                string(REGEX REPLACE "[ \t]+-I" ";" _INCLUDES "${_INCLUDES}")
                string(REGEX REPLACE "[ \t\r\n]+" ";" _CFLAGS "${_CFLAGS}")
                set(_COMPILE_DEFINITIONS ${_CFLAGS})
                set(_COMPILE_OPTIONS ${_CFLAGS})
                if(_CFLAGS)
                    list(FILTER _COMPILE_OPTIONS EXCLUDE REGEX "^-D")
                    list(FILTER _COMPILE_DEFINITIONS INCLUDE REGEX "^-D")
                    list(TRANSFORM _COMPILE_DEFINITIONS REPLACE "^-D" "")
                endif()
                string(REGEX REPLACE "^-L" "" _LIB_DIRS "${_LIB_DIRS}")
                string(REGEX REPLACE "[ \t]+-L" ";" _LIB_DIRS "${_LIB_DIRS}")
                string(REGEX REPLACE "^-l" "" _LIBS "${_LIBS}")
                string(REGEX REPLACE "[ \t]+-l" ";" _LIBS "${_LIBS}")
                string(REGEX REPLACE "[ \t\r\n]+" ";" _LINKER_OPTS "${_LINKER_OPTS}")

                add_library(${target_name} SHARED IMPORTED)
                target_include_directories(${target_name} INTERFACE ${_INCLUDES})
                target_compile_definitions(${target_name} INTERFACE ${_COMPILE_DEFINITIONS})
                target_compile_options(${target_name} INTERFACE ${_COMPILE_OPTIONS})
                target_link_directories(${target_name} INTERFACE ${_LIB_DIRS})
                target_link_libraries(${target_name} INTERFACE ${_LIBS})
                target_link_options(${target_name} INTERFACE ${_LINK_OPTS})

                set(_FOUND_PKG_CONFIG True)
                set(${target_var_name}_PKGCONFIG_FOUND_NAME ${pkg_config_name} PARENT_SCOPE)
                set(${target_var_name}_PKGCONFIG_FOUND_NAME ${pkg_config_name} CACHE STRING "${target_name} libraries: found using pkg-config name" FORCE)
                mark_as_advanced(${target_var_name}_PKGCONFIG_FOUND_NAME)
                message(STATUS "[BLASLAPACK] Found: ${target_name} using pkg-config name: ${pkg_config_name}")
                break()
            endif()
        endforeach()
    endif()
    set(${target_var_name}_PKGCONFIG_FOUND ${_FOUND_PKG_CONFIG} PARENT_SCOPE)
    set(${target_var_name}_PKGCONFIG_FOUND ${_FOUND_PKG_CONFIG} CACHE STRING "${target_name} libraries found using pkg-config" FORCE)
    mark_as_advanced(${target_var_name}_PKGCONFIG_FOUND)
    set(${target_var_name}_FOUND ${_FOUND} PARENT_SCOPE)
    set(${target_var_name}_FOUND ${_FOUND} CACHE STRING "${target_name} libraries found." FORCE)
endfunction()


### Default variables

#Default BLAS names to search for in decreasing order of importance
if(NOT BLAS_PKGCONFIG_NAMES)
    set(BLAS_PKGCONFIG_NAMES blas openblas goto2 refblas)
endif()

#Default CBLAS names to search for in decreasing order of importance
if(NOT CBLAS_PKGCONFIG_NAMES)
    set(CBLAS_PKGCONFIG_NAMES cblas refcblas)
endif()

#Default LAPACK names to search for in decreasing order of importance
if(NOT LAPACK_PKGCONFIG_NAMES)
    set(LAPACK_PKGCONFIG_NAMES lapack reflapack)
endif()

#Default LAPACKE names to search for in decreasing order of importance
if(NOT LAPACKE_PKGCONFIG_NAMES)
    set(LAPACKE_PKGCONFIG_NAMES lapacke reflapacke)
endif()

if(NOT BLASLAPACK_INT64_PKG_CONFIG_SUFFIX)
    set(BLASLAPACK_INT64_PKG_CONFIG_SUFFIX "-int64")
endif()

if(NOT BLASLAPACK_THREADS_PKG_CONFIG_SUFFIX)
    set(BLASLAPACK_THREADS_PKG_CONFIG_SUFFIX "-threads")
endif()
if(NOT BLASLAPACK_STATIC_PKG_CONFIG_SUFFIX)
    set(BLASLAPACK_STATIC_PKG_CONFIG_SUFFIX "-static")
endif()

if(NOT BLASLAPACK_USE_PKG_CONFIG)
    set(BLASLAPACK_USE_PKG_CONFIG False)
    if(NOT OPT_DISABLE_BLAS_LAPACK_PKG_CONFIG)
        find_package(PkgConfig)
        message(STATUS "PKG_CONFIG_FOUND: ${PKG_CONFIG_FOUND}")
        message(STATUS "PKG_CONFIG_FOUND: ${PKG_CONFIG_EXECUTABLE}")
        if(PKG_CONFIG_FOUND AND EXISTS ${PKG_CONFIG_EXECUTABLE})
            set(BLASLAPACK_USE_PKG_CONFIG True)
        else()
            message(STATUS "[BLASLAPACK] pkg-config not found.  Disabling pkg-config based search.")
            find_package(BLAS)
            find_package(LAPACK)
        endif()
    endif()
endif()

#Enable cross-compiling support for pkg-config via environment variables: https://autotools.io/pkgconfig/cross-compiling.html
if(BLASLAPACK_USE_PKG_CONFIG AND CMAKE_CROSSCOMPILING)
    set(_lib_dirs)
    set(_sysroot)
    if(CMAKE_SYSROOT)
        list(APPEND _lib_dirs ${CMAKE_SYSROOT}/usr/lib/pkgconfig ${CMAKE_SYSROOT}/usr/share/pkgconfig)
        set(_sysroot ${CMAKE_SYSROOT})
    endif()
    foreach(_dir IN LISTS CMAKE_FIND_ROOT_PATH)
        list(APPEND _lib_dirs ${_dir}/usr/lib/pkgconfig ${_dir}/usr/share/pkgconfig)
        if(NOT _sysroot)
            set(_sysroot ${_dir})
        endif()
    endforeach()
    if(NOT _lib_dirs OR NOT _sysroot)
        message(FATAL_ERROR "[BLASLAPACK] Cross-compiling but couldn't find valid CMAKE_SYSROOT or CMAKE_FIND_ROOT_PATH.  Unknown how to find pkg-config repository.")
    endif()
    string(REPLACE ";" ":" _lib_dirs ${_lib_dirs})
    set(ENV{PKG_CONFIG_DIR} "")
    set(ENV{PKG_CONFIG_LIBDIR} "${_lib_dirs}")
    set(ENV{PKG_CONFIG_SYSROOT} "${_sysroot}")
    unset(_lib_dirs)
    unset(_sysroot)
endif()

#Create all the targets
foreach(_lib IN ITEMS Blas CBlas Lapack Lapacke)
    #target_base_name is used to check for CMAKE variables.
    string(REGEX REPLACE "[A-Za-z0-9]::" "" _var_name ${_lib})
    string(TOUPPER ${_var_name} _var_name)
    #int32 shared
    make_pkg_config_target(VAR_NAME ${_var_name} NAMESPACE ${_lib} TARGET ${_lib} PCNAMES ${${_var_name}_PKGCONFIG_NAMES})

    #int32 shared with threads
    if(NOT ${_var_name}_THREADS_PKGCONFIG_NAMES)
        list(TRANSFORM ${_var_name}_PKGCONFIG_NAMES APPEND ${BLASLAPACK_THREADS_PKG_CONFIG_SUFFIX} OUTPUT_VARIABLE ${_var_name}_THREADS_PKGCONFIG_NAMES)
    endif()
    make_pkg_config_target(VAR_NAME ${_var_name}_THREADS NAMESPACE ${_lib} TARGET ${_lib}Threads PCNAMES ${${_var_name}_THREADS_PKGCONFIG_NAMES})

    #int32 static
    if(NOT ${_var_name}_STATIC_PKGCONFIG_NAMES)
        set(${_var_name}_STATIC_PKGCONFIG_NAMES ${${_var_name}_PKGCONFIG_NAMES})
    endif()
    make_pkg_config_target(VAR_NAME ${_var_name}_STATIC NAMESPACE ${_lib} TARGET ${_lib}Static STATIC PCNAMES ${${_var_name}_STATIC_PKGCONFIG_NAMES})

    #int64 shared
    if(NOT ${_var_name}_INT64_PKGCONFIG_NAMES)
        list(TRANSFORM ${_var_name}_PKGCONFIG_NAMES APPEND ${BLASLAPACK_INT64_PKG_CONFIG_SUFFIX} OUTPUT_VARIABLE ${_var_name}_INT64_PKGCONFIG_NAMES)
    endif()
    make_pkg_config_target(VAR_NAME ${_var_name}_INT64 NAMESPACE ${_lib} TARGET ${_lib}Int64 PCNAMES ${${_var_name}_INT64_PKGCONFIG_NAMES})

    #int64 shared with threads
    if(NOT ${_var_name}_INT64_THREADS_PKGCONFIG_NAMES)
        list(TRANSFORM ${_var_name}_PKGCONFIG_NAMES APPEND ${BLASLAPACK_INT64_PKG_CONFIG_SUFFIX} OUTPUT_VARIABLE ${_var_name}_INT64_THREADS_PKGCONFIG_NAMES)
        list(TRANSFORM ${_var_name}_INT64_THREADS_PKGCONFIG_NAMES APPEND ${BLASLAPACK_THREADS_PKG_CONFIG_SUFFIX})
    endif()
    make_pkg_config_target(VAR_NAME ${_var_name}_INT64_THREADS NAMESPACE ${_lib} TARGET ${_lib}Int64Threads PCNAMES ${${_var_name}_INT64_THREADS_PKGCONFIG_NAMES})

    #int64 static
    if(NOT ${_var_name}_INT64_STATIC_PKGCONFIG_NAMES)
        list(TRANSFORM ${_var_name}_PKGCONFIG_NAMES APPEND ${BLASLAPACK_INT64_PKG_CONFIG_SUFFIX} OUTPUT_VARIABLE ${_var_name}_INT64_STATIC_PKGCONFIG_NAMES)
    endif()
    make_pkg_config_target(VAR_NAME ${_var_name}_INT64_STATIC NAMESPACE ${_lib} TARGET ${_lib}Int64Static STATIC PCNAMES ${${_var_name}_INT64_STATIC_PKGCONFIG_NAMES})
endforeach()
unset(_lib)
unset(_var_name)
