# fixup_dependencies.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Single argument keywords:
#   COPY_DESTINATION - [optional] [default: '.'] Relative path from the install location to the copy location
#   TARGET_DESTINATION - [suggested but optional] [default try to find_file in install prefix].  The relative path
#       of the target under the install prefix.  This is the same value as given to DESTINATION keyword of install(TARGETS).
# Multi-argument keywords:
#   TARGETS - List of targets to copy dependencies for.  These targets should share all of the other keyword propoerties.
#             If multiple targets require different options to fixup_dependencies, then multiple independent calls should be made.
#   LIB_SEARCH_PATHS - Search path for libraries that should be copied into the install tree.
#   LIB_SYSTEM_PATHS - Search paths for system libraries that should be assumed to be provided by the client system and should not be copied.
function(fixup_dependencies target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "fixup_dependencies works on cmake targets.  Got target=${target}")
    endif()
    cmake_parse_arguments(FIXUP "" "COPY_DESTINATION;TARGET_DESTINATION" "TARGETS;LIB_SEARCH_PATHS;LIB_SYSTEM_PATHS" ${ARGN})
    if(NOT FIXUP_COPY_DESTINATION)
        set(FIXUP_COPY_DESTINATION ".")  #Must be relative to TARGET_DESTINATION
    endif()
    if(NOT FIXUP_TARGET_DESTINATION)
        set(FIXUP_TARGET_DESTINATION) #Signal to use find_file in FixupTarget script
    endif()

#     set(FIXUP_RPATH "." ${FIXUP_COPY_DESTINATION} ${FIXUP_RPATH})
#     list(REMOVE_DUPLICATES FIXUP_RPATH)
    set(FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-${target}.cmake)
    #Try to eliminate the need for this block
    if(WIN32)
        set(TARGET_OS WIN64)
    elseif(UNIX AND NOT APPLE)
        set(TARGET_OS LINUX)
    else()
        set(TARGET_OS OSX)
    endif()
    
    configure_file(${MexIFace_CMAKE_TEMPLATES_DIR}/FixupTarget.cmake.in ${FIXUP_SCRIPT}.gen @ONLY)
    file(GENERATE OUTPUT ${FIXUP_SCRIPT} INPUT ${FIXUP_SCRIPT}.gen )
    install(SCRIPT ${FIXUP_SCRIPT})
endfunction()
