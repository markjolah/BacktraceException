# fixup_dependencies.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Single argument keywords:
#   COPY_RPATH - [optional] [default: '.'] Relative path from the target install location to the lib dir  i.e., copy location.
#   TARGET_DESTINATION - [suggested but optional] [default try to find_file in install prefix].  The relative path
#       of the target under the install prefix.  This is the same value as given to DESTINATION keyword of install(TARGETS).
#   FIXUP_SCRIPT_TEMPLATE - [optional] [default: look for script in ../Templates or ./Templates]
# Multi-argument keywords:
#   TARGETS - List of targets to copy dependencies for.  These targets should share all of the other keyword propoerties.
#             If multiple targets require different options to fixup_dependencies, then multiple independent calls should be made.
#   LIB_SEARCH_PATHS - Search path for libraries that should be copied into the install tree.
#   LIB_SYSTEM_PATHS - Search paths for system libraries that should be assumed to be provided by the client system and should not be copied.
set(_fixup_dependencies_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(fixup_dependencies)
    cmake_parse_arguments(FIXUP "" "COPY_RPATH;TARGET_DESTINATION;SCRIPT_TEMPLATE" "TARGETS;LIB_SEARCH_PATHS;LIB_SYSTEM_PATHS" ${ARGN})
    if(NOT FIXUP_COPY_RPATH)
        set(FIXUP_COPY_RPATH ".")  #Must be relative to TARGET_DESTINATION
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

    #Try to eliminate the need for this block
    if(WIN32)
        set(TARGET_OS WIN64)
    elseif(UNIX AND NOT APPLE)
        set(TARGET_OS LINUX)
    else()
        set(TARGET_OS OSX)
    endif()
    foreach(FIXUP_TARGET IN LISTS FIXUP_TARGETS)
        message(STATUS "FIXUP_TARGET:${FIXUP_TARGET}")
        if(NOT TARGET ${FIXUP_TARGET})
            message(FATAL_ERROR "[fixup_dependencies]  Got invalid target:${FIXUP_TARGET}")
        endif()
        set(FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-${FIXUP_TARGET}.cmake)

        configure_file(${FIXUP_SCRIPT_TEMPLATE} ${FIXUP_SCRIPT}.gen @ONLY)
        file(GENERATE OUTPUT ${FIXUP_SCRIPT} INPUT ${FIXUP_SCRIPT}.gen )
        install(SCRIPT ${FIXUP_SCRIPT})
        message(STATUS "[fixup_dependencies]  Generated dependency fixup script for target: ${FIXUP_TARGET}")
    endforeach()
endfunction()
