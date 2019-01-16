# fixup_dependencies.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Options:
#   COPY_GCC_LIBS - [UNIX only]  [default: off] Copy libraries provided by GCC [i.e. libgcc_s libstdc++, etc.].  This implies
#                    Setting RPATH for targets to the COPU_DESTINATION.  This is only possibly usefull if deploying to
#                    systems with and older GCC than was used to build them.
#   COPY_GLIBC_LIBS - [UNIX only] [DANGEROUS} [default: off] Copy libraries provided glibc [i.e. libc, ld-linux-x86_64 etc.].
#                      Also copy in Glibc libraries.  WARNING. This is almost certainly going to cause problems as
#                     the version of libc and ld-linux-x86_64 must match exactly.  For now this is disabled.
#
#   BUILD_TREE_EXPORT - [default: off] Fixup the libraries for the build-tree export
#   LINK_INSTALLED_LIBS - [default: off] [WIN32 only] instead of copying into current directory make a symlink if dep us under in the install_prefix
#
# Single argument keywords:
#   COPY_DESTINATION - [optional] [default: '.'] Relative path from the target install location to the lib dir  i.e., copy location.
#   TARGET_DESTINATION - [suggested but optional] [default try to find_file in install prefix].  The relative path
#       of the target under the install prefix.  This is the same value as given to DESTINATION keyword of install(TARGETS).
#   PARENT_LIB - [optional] [default: False] The library that will load this library possibly via dlopen.  We can use the RPATH or RUNPATH from this
#                                            ELF file to correctly find libraries that will be provided on the system path.
#                                            For fixing up matlab MEx files, this should be ${MATLAB_ROOT}/bin/${MATLAB_ARCH}/MATLAB or equivalent.
#   FIXUP_INSTALL_SCRIPT_TEMPLATE - [optional] [default: FixupInstallTargetDependencies.cmake look for script in ../Templates or ./Templates]
#   FIXUP_BUILD_SCRIPT_TEMPLATE - [optional] [default: FixupBuildTargetDependencies.cmake look for script in ../Templates or ./Templates]
# Multi-argument keywords:
#   TARGETS - List of targets to copy dependencies for.  These targets should share all of the other keyword propoerties.
#             If multiple targets require different options to fixup_dependencies, then multiple independent calls should be made.
#   PROVIDED_LIB_DIRS - Absolute paths to directories containaing libraries that will be provided by the system or parent program for dynamic imports.
#                       Libraries found in these directories will not be copied as they are assumed provided.
#   PROVIDED_LIBS - Names (with of without extensions) of provided libraries that should not be copied.
#   SEARCH_LIB_DIRS - Additional directories to search for libraries.  These libraries will be copied into COPY_DESTINATION
#   SEARCH_LIB_DIR_SUFFIXES - Additional suffixes to check for
#
# TODO: Allow a configure-time build-tree fixup phase.
#
set(_fixup_dependencies_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(fixup_dependencies)
    cmake_parse_arguments(FIXUP "COPY_GCC_LIBS;COPY_GLIBC_LIBS;BUILD_TREE_EXPORT;LINK_INSTALLED_LIBS"
                                "COPY_DESTINATION;TARGET_DESTINATION;PARENT_LIB;INSTALL_SCRIPT_TEMPLATE;BUILD_SCRIPT_TEMPLATE"
                                "TARGETS;PROVIDED_LIB_DIRS;PROVIDED_LIBS;SEARCH_LIB_DIRS;SEARCH_LIB_DIR_SUFFIXES" ${ARGN})
    if(NOT FIXUP_COPY_DESTINATION)
        set(FIXUP_COPY_DESTINATION ".")  #Must be relative to TARGET_DESTINATION
    endif()
    if(NOT FIXUP_TARGET_DESTINATION)
        set(FIXUP_TARGET_DESTINATION) #Signal to use find_file in FixupTarget script
    endif()
    if(NOT FIXUP_INSTALL_SCRIPT_TEMPLATE)
        find_file(FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH FixupIstallTargetDependenciesScript.cmake.in
                PATHS ${_fixup_dependencies_install_PATH}/Templates ${_fixup_dependencies_install_PATH}/../Templates
                NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH)
        if(NOT FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH)
            message(FATAL_ERROR "[fixup_dependencies]: Cannot find FixupInstallTargetDependenciesScript.cmake.in")
        endif()
        set(FIXUP_INSTALL_SCRIPT_TEMPLATE ${FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH})
    endif()
    if(FIXUP_BUILD_TREE_EXPORT AND NOT FIXUP_BUILD_SCRIPT_TEMPLATE)
        find_file(FIXUP_BUILD_SCRIPT_TEMPLATE_PATH FixupBuildTargetDependenciesScript.cmake.in
                PATHS ${_fixup_dependencies_install_PATH}/Templates ${_fixup_dependencies_install_PATH}/../Templates
                NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(FIXUP_BUILD_SCRIPT_TEMPLATE_PATH)
        if(NOT FIXUP_BUILD_SCRIPT_TEMPLATE_PATH)
            message(FATAL_ERROR "[fixup_dependencies]: Cannot find FixupBuildTargetDependenciesScript.cmake.in")
        endif()
        set(FIXUP_BUILD_SCRIPT_TEMPLATE ${FIXUP_BUILD_SCRIPT_TEMPLATE_PATH})
    endif()
    if(NOT FIXUP_COPY_SYSTEM_LIBS AND OPT_INSTALL_SYSTEM_DEPENDENCIES)
        set(FIXUP_COPY_SYSTEM_LIBS True)
    endif()
    #Normal variables WIN32 UNIX, etc. are not respected in install scrtipts
    #(apparently due to toolchain file not being used at install time?)
    if(WIN32)
        set(FIXUP_TARGET_OS WIN32)
    elseif(UNIX AND NOT APPLE)
        set(FIXUP_TARGET_OS UNIX)
    else()
        set(FIXUP_TARGET_OS OSX)
    endif()
    if(PROVIDED_LIBS)
        list(LENGTH PROVIDED_LIBS ndirs)
        math(EXPR niter "${ndirs} - 1")
        foreach(idx RANGE ${niter})
            list(GET PROVIDED_LIBS ${idx} _item)
            get_filename_component(_name ${_item} NAME_WE)
            list(REMOVE_AT PROVIDED_LIBS ${idx})
            list(INSERT PROVIDED_LIBS ${idx} ${_name})
        endforeach()
        if(WIN32)
            list(TRANSFORM PROVIDED_LIBS TOLOWER) #Case insensitive-match on windows
        endif()
    endif()
    foreach(FIXUP_TARGET IN LISTS FIXUP_TARGETS)
        if(NOT TARGET ${FIXUP_TARGET})
            message(FATAL_ERROR "[fixup_dependencies]  Got invalid target: ${FIXUP_TARGET}")
        endif()
        get_target_property(FIXUP_TARGET_TYPE ${FIXUP_TARGET} TYPE)
        if(NOT (${FIXUP_TARGET_TYPE} MATCHES SHARED_LIBRARY OR ${FIXUP_TARGET_TYPE} MATCHES EXECUTABLE) )
            message(STATUS "[fixup_dependencies]  Skipping non-shared target: ${FIXUP_TARGET}")
        else()
            set(FIXUP_INSTALL_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-Install-${FIXUP_TARGET}.cmake)
            configure_file(${FIXUP_INSTALL_SCRIPT_TEMPLATE} ${FIXUP_INSTALL_SCRIPT}.gen @ONLY)
            file(GENERATE OUTPUT ${FIXUP_INSTALL_SCRIPT} INPUT ${FIXUP_INSTALL_SCRIPT}.gen)
            install(SCRIPT ${FIXUP_INSTALL_SCRIPT})
            get_target_property(script ${FIXUP_TARGET} FIXUP_INSTALL_SCRIPT)
            if(script)
                message(STATUS "[fixup_dependencies]  Re-generated install-tree dependency fixup script for target: ${FIXUP_TARGET}")
            else()
                message(STATUS "[fixup_dependencies]  Generated install-tree dependency fixup script for target: ${FIXUP_TARGET}")
            endif()
            set_target_properties(${FIXUP_TARGET} PROPERTIES FIXUP_INSTALL_SCRIPT ${FIXUP_INSTALL_SCRIPT}) #Mark as fixup-ready.
            if(FIXUP_BUILD_TREE_EXPORT)
                set(FIXUP_BUILD_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-Build-${FIXUP_TARGET}.cmake)
                configure_file(${FIXUP_INSTALL_BUILD_TEMPLATE} ${FIXUP_BUILD_SCRIPT}.gen @ONLY)
                file(GENERATE OUTPUT ${FIXUP_BUILD_SCRIPT} INPUT ${FIXUP_BUILD_SCRIPT}.gen)
                add_custom_command(TARGET ${FIXUP_TARGET} POST_BUILD COMMAND cmake ${FIXUP_BUILD_SCRIPT})
                message(STATUS "[fixup_dependencies]  Generated build-tree dependency fixup script for target: ${FIXUP_TARGET}")
            endif()
        endif()
    endforeach()
endfunction()
