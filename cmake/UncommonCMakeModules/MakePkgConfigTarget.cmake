# FindBlasLapack.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2019
# see file: LICENCE
#
# Functions to enable use of pkg-config for modern CMake namespaced-targets, with cross-compiling awareness.
#
#

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
        separate_arguments(_out)
        set(${ret_var} ${_out} PARENT_SCOPE)
    else()
        set(${ret_var} "" PARENT_SCOPE)
    endif()
endfunction()

# make_pkg_config_target(target_var_name target_name [STATIC] pkg_config_names... )
# Options:
#   STATIC - Find static libs.  Will pass --static args to pkg_config
#   DISABLE_PKGCONFIG - Disable usage of pkg-config.  Will only add targets when ${VAR_NAME}_LIBRARIES and friends are already set.
# Single Value Args:
#   VAR_NAME  - Name to use for checking relevant CMake CACHE variables.  Normally uppercase. [e.g., BLAS, LAPACK, BLAS_INT64, etc.]
#   NAMESPACE - Namespace to create target at (:: optional)
#   TARGET - Name of target to create (w/o namespace)
# Multi-value args:
#   PCNAMES - List of pkg-config .pc names to check for in order.  The first one found is used to set target properties.
#
# Sets cache variables:
#  ${VAR_NAME}_FOUND - True if found either with pkg-config or through ${VAR_NAME}_LIBRARIES variables
#  ${VAR_NAME}_PKGCONFIG_FOUND - True if found with pkg-config.
#  ${VAR_NAME}_PKGCONFIG_NAME - pkg-config name found under if any.
#
#
function(make_pkg_config_target)
    set(options STATIC DISABLE_PKGCONFIG)
    set(oneValueArgs VAR_NAME NAMESPACE TARGET)
    set(multiValueArgs PCNAMES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "[MakePkgConfigTarget:make_pkg_config_target] Unknown keywords given: \"${ARG_UNPARSED_ARGUMENTS}\"")
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
        add_library(${target_name} SHARED IMPORTED)
        target_link_libraries(${target_name} INTERFACE ${${target_var_name}_LIBRARIES})
        if(${target_var_name}_LINKER_FLAGS)
            target_link_options(${target_name} INTERFACE ${${target_var_name}_LINKER_FLAGS})
        endif()
        if(${target_var_name}_LINKER_DIRS)
            target_link_directories(${target_name} INTERFACE ${${target_var_name}_LINKER_DIRS})
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
        message(STATUS "Found ${target_name} manually specified")
        set(_FOUND True)
    elseif(NOT DISABLE_PKGCONFIG) #Look in pkg_config
        foreach(pkg_config_name IN LISTS ARG_PCNAMES)
            check_pkg_config(_FOUND ${pkg_config_name})
            if(_FOUND)
                get_pkg_config(_INCLUDES ${pkg_config_name} "--cflags-only-I" ${_static_flags})
                get_pkg_config(_CFLAGS ${pkg_config_name} "--cflags-only-other" ${_static_flags})
                get_pkg_config(_LIB_DIRS ${pkg_config_name} "--libs-only-L" ${_static_flags})
                get_pkg_config(_LIBS ${pkg_config_name} "--libs-only-l" ${_static_flags})
                get_pkg_config(_LINKER_OPTS ${pkg_config_name} "--libs-only-other" ${_static_flags})

                string(REGEX REPLACE "-I" "" _INCLUDES "${_INCLUDES}")
                #Splitup compile definitions and options
                set(_COMPILE_DEFINITIONS ${_CFLAGS})
                set(_COMPILE_OPTIONS ${_CFLAGS})
                if(_CFLAGS)
                    list(FILTER _COMPILE_OPTIONS EXCLUDE REGEX "^-D")
                    list(FILTER _COMPILE_DEFINITIONS INCLUDE REGEX "^-D")
                    list(TRANSFORM _COMPILE_DEFINITIONS REPLACE "^-D" "")
                endif()
                string(REGEX REPLACE "-L" "" _LIB_DIRS "${_LIB_DIRS}")
                string(REGEX REPLACE "-l" "" _LIBS "${_LIBS}")

                add_library(${target_name} INTERFACE IMPORTED)
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
                message(STATUS "Found ${target_name} using pkg-config name: ${pkg_config_name}")
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

#Enable cross-compiling support for pkg-config via environment variables: https://autotools.io/pkgconfig/cross-compiling.html
if(NOT OPT_DISABLE_PKG_CONFIG AND CMAKE_CROSSCOMPILING)
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
    string(REPLACE ";" ":" _lib_dirs "${_lib_dirs}")
    set(ENV{PKG_CONFIG_DIR} "")
    set(ENV{PKG_CONFIG_LIBDIR} "${_lib_dirs}")
    set(ENV{PKG_CONFIG_SYSROOT} "${_sysroot}")
    unset(_lib_dirs)
    unset(_sysroot)
endif()
