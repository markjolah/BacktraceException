# fixup_dependencies.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Options:
#   COPY_SYSTEM_LIBS - [default: off] Only has effect on Linux targets.  Copy all system (gcc) libraries into COPY_DESTINATION.
#
# Single argument keywords:
#   COPY_DESTINATION - [optional] [default: '.'] Relative path from the target install location to the lib dir  i.e., copy location.
#   TARGET_DESTINATION - [suggested but optional] [default try to find_file in install prefix].  The relative path
#       of the target under the install prefix.  This is the same value as given to DESTINATION keyword of install(TARGETS).
#   FIXUP_SCRIPT_TEMPLATE - [optional] [default: look for script in ../Templates or ./Templates]
# Multi-argument keywords:
#   TARGETS - List of targets to copy dependencies for.  These targets should share all of the other keyword propoerties.
#             If multiple targets require different options to fixup_dependencies, then multiple independent calls should be made.
#   PROVIDED_LIB_DIRS - Absolute paths to directories containaing libraries that will be provided by the system or parent program for dynamic imports.
#                       Libraries found in these directories will not be copied as they are assumed provided.
#   PROVIDED_LIBS - Names (with of without extensions) of provided libraries that should not be copied.
#   SEARCH_LIB_DIRS - Additional directories to search for libraries.  These libraries will be copied into COPY_DESTINATION
#   SEARCH_LIB_DIR_SUFFIXES - Additional suffixes to check for
set(_fixup_dependencies_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(fixup_dependencies)
    cmake_parse_arguments(FIXUP "COPY_SYSTEM_LIBS"
                                "COPY_DESTINATION;TARGET_DESTINATION;SCRIPT_TEMPLATE"
                                "TARGETS;PROVIDED_LIB_DIRS;PROVIDED_LIBS;SEARCH_LIB_DIRS;SEARCH_LIB_DIR_SUFFIXES" ${ARGN})
    if(NOT FIXUP_COPY_DESTINATION)
        set(FIXUP_COPY_DESTINATION ".")  #Must be relative to TARGET_DESTINATION
    endif()
    if(NOT FIXUP_TARGET_DESTINATION)
        set(FIXUP_TARGET_DESTINATION) #Signal to use find_file in FixupTarget script
    endif()
    if(NOT FIXUP_SCRIPT_TEMPLATE)
        find_file(FIXUP_SCRIPT_TEMPLATE_PATH FixupTargetDependenciesScript.cmake.in
                PATHS ${_fixup_dependencies_install_PATH}/Templates ${_fixup_dependencies_install_PATH}/../Templates
                NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(FIXUP_SCRIPT_TEMPLATE_PATH)
        if(NOT FIXUP_SCRIPT_TEMPLATE_PATH)
            message(FATAL_ERROR "[fixup_dependencies]: Cannot find FixupTargetDependenciesScript.cmake.in")
        endif()
        set(FIXUP_SCRIPT_TEMPLATE ${FIXUP_SCRIPT_TEMPLATE_PATH})
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
    message(STATUS "CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES:${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES}")
    foreach(FIXUP_TARGET IN LISTS FIXUP_TARGETS)
        if(NOT TARGET ${FIXUP_TARGET})
            message(FATAL_ERROR "[fixup_dependencies]  Got invalid target: ${FIXUP_TARGET}")
        endif()
        get_target_property(FIXUP_TARGET_TYPE ${FIXUP_TARGET} TYPE)
        if(NOT (${FIXUP_TARGET_TYPE} MATCHES SHARED_LIBRARY OR ${FIXUP_TARGET_TYPE} MATCHES EXECUTABLE) )
            message(STATUS "[fixup_dependencies]  Skipping non-shared target: ${FIXUP_TARGET}")
        else()
            set(FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-${FIXUP_TARGET}.cmake)
            configure_file(${FIXUP_SCRIPT_TEMPLATE} ${FIXUP_SCRIPT}.gen @ONLY)
            file(GENERATE OUTPUT ${FIXUP_SCRIPT} INPUT ${FIXUP_SCRIPT}.gen )
            install(SCRIPT ${FIXUP_SCRIPT})
            message(STATUS "[fixup_dependencies]  Generated dependency fixup script for target: ${FIXUP_TARGET}")
        endif()
    endforeach()
endfunction()
