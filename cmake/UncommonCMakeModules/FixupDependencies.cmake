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
#   EXPORT_BUILD_TREE - [default: off] Fixup the libraries for the build-tree export
#   LINK_INSTALLED_LIBS - [default: off] [WIN32 only] [deprecated: does not seem to be viable option] instead of copying into current directory make a symlink if dep us under in the install_prefix
#
# Single argument keywords:
#   COPY_DESTINATION - [optional] [default: 'lib'] Relative path from the install_prefix in which to copy dependencies.
#   PARENT_LIB - [optional] [default: False] The library that will load this library possibly via dlopen.  We can use the RPATH or RUNPATH from this
#                                            ELF file to correctly find libraries that will be provided on the system path.
#                                            For fixing up matlab MEx files, this should be ${MATLAB_ROOT}/bin/${MATLAB_ARCH}/MATLAB or equivalent.
#   FIXUP_INSTALL_SCRIPT_TEMPLATE - [optional] [default: FixupInstallTargetDependencies.cmake look for script in ../Templates or ./Templates]
#   FIXUP_BUILD_SCRIPT_TEMPLATE - [optional] [default: FixupBuildTargetDependencies.cmake look for script in ../Templates or ./Templates]
# Multi-argument keywords:
#   TARGETS - List of targets to copy dependencies for.  These targets should share all of the other keyword propoerties.
#             If multiple targets require different options to fixup_dependencies, then multiple independent calls should be made.
#   TARGET_DESTINATIONS - [suggested but optional] [default try to find_file in install prefix].  List of relative paths
#        to look for the installed target under the install prefix.  This is the same value as given to DESTINATION keyword of install(TARGETS).
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
    cmake_parse_arguments(FIXUP "COPY_GCC_LIBS;COPY_GLIBC_LIBS;EXPORT_BUILD_TREE;LINK_INSTALLED_LIBS"
                                "COPY_DESTINATION;PARENT_LIB;INSTALL_SCRIPT_TEMPLATE;BUILD_SCRIPT_TEMPLATE"
                                "TARGETS;TARGET_DESTINATIONS;PROVIDED_LIB_DIRS;PROVIDED_LIBS;SEARCH_LIB_DIRS;SEARCH_LIB_DIR_SUFFIXES" ${ARGN})
    set(msg_hdr "[fixup_dependencies:configure-phase]:")
    if(UNIX AND NOT FIXUP_COPY_DESTINATION)
        set(FIXUP_COPY_DESTINATION "lib")  #Must be relative to INSTALL_PREFIX
    endif()
    if(NOT FIXUP_TARGET_DESTINATIONS)
        set(FIXUP_TARGET_DESTINATIONS) #Signal to use find_file in FixupTarget script
    endif()
    if(NOT FIXUP_INSTALL_SCRIPT_TEMPLATE)
        find_file(FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH FixupInstallTargetDependenciesScript.cmake.in
                PATHS ${_fixup_dependencies_install_PATH}/Templates ${_fixup_dependencies_install_PATH}/../Templates
                NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH)
        if(NOT FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH)
            message(FATAL_ERROR "${msg_hdr} Cannot find FixupInstallTargetDependenciesScript.cmake.in")
        endif()
        set(FIXUP_INSTALL_SCRIPT_TEMPLATE ${FIXUP_INSTALL_SCRIPT_TEMPLATE_PATH})
    endif()
    if(FIXUP_EXPORT_BUILD_TREE AND NOT FIXUP_BUILD_SCRIPT_TEMPLATE)
        find_file(FIXUP_BUILD_SCRIPT_TEMPLATE_PATH FixupBuildTargetDependenciesScript.cmake.in
                PATHS ${_fixup_dependencies_install_PATH}/Templates ${_fixup_dependencies_install_PATH}/../Templates
                NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(FIXUP_BUILD_SCRIPT_TEMPLATE_PATH)
        if(NOT FIXUP_BUILD_SCRIPT_TEMPLATE_PATH)
            message(FATAL_ERROR "${msg_hdr} Cannot find FixupBuildTargetDependenciesScript.cmake.in")
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
    if(FIXUP_PROVIDED_LIBS)
        set(_provided)
        foreach(_lib IN LISTS FIXUP_PROVIDED_LIBS)
            get_filename_component(_name ${_lib} NAME_WE)
            list(APPEND _provided ${_name})
        endforeach()
        set(FIXUP_PROVIDED_LIBS ${_provided})
        if(WIN32)
            list(TRANSFORM PROVIDED_LIBS TOLOWER) #Case insensitive-match on windows
        endif()
    endif()

    #Append system libraries to FIXUP_PROVIDED_LIBS
    if(UNIX AND NOT APPLE)
        #libc and ld-linux-x86-64 loader must match versions exactly with system loader since
        #the loader location is hard-coded as an absolute path, it cannot be made relocatable without using system
        #loader which implied also using system libc.
        if(NOT FIXUP_COPY_GCC_LIBS)
            list(APPEND FIXUP_PROVIDED_LIBS libstdc++ libgfortran libgcc_s libatomic libgomp libquadmath libmpx libmpxwrappers) #gcc libs
        endif()
        if(NOT FIXUP_COPY_GLIBC_LIBS)
            list(APPEND FIXUP_PROVIDED_LIBS libdl libpthread libcrypt librt libm) #glibc libs
        endif()
        list(APPEND FIXUP_PROVIDED_LIBS libc ld-linux-x86-64) #loader
    elseif(WIN32)
        list(APPEND FIXUP_PROVIDED_LIBS kernel32 user32 msvcrt advapi32 ws2_32 msvcp120 msvcr120 msvcp120 dbghelp oleaut32 ole32 psapi powrprof)
    endif()

    #FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS - generally matches the CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES
    set(FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS)
    if(UNIX AND NOT APPLE)
        set(_suffixs ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES}) #dirs of libraries provided by host system
        foreach(sdir IN LISTS _suffixs)
            if(sdir MATCHES "^/(.*)")
                list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS ${CMAKE_MATCH_1})
            else()
                list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS ${sdir})
            endif()
        endforeach()
        unset(_suffixs)
        list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS lib lib64)
    elseif(WIN32)
        set(_suffixs ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES}) #dirs of libraries provided by host system
        foreach(_suffix IN LISTS _suffixs)
            if(IS_ABSOLUTE ${_suffix})
                get_filename_component(_suffix ${_suffix} REALPATH)
                set(_found)
                foreach(pre IN ITEMS ${CMAKE_FIND_ROOT_PATH})
                    get_filename_component(pre ${pre} REALPATH)
                    if(_suffix MATCHES "^${pre}/(.*)")
                        list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS ${CMAKE_MATCH_1})
                        set(_found True)
                        break()
                    endif()
                endforeach()
                if(NOT _found AND ${_suffix} MATCHES "^/(.*)")
                    list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS ${CMAKE_MATCH_1})
                endif()
                unset(_found)
            else()
                list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS ${_suffix})
            endif()
        endforeach()
        unset(_suffixs)
        list(APPEND FIXUP_DEFAULT_LIBRARY_SEARCH_SUFFIXS bin usr/bin lib usr/lib)
    endif()


    set(FIXUP_SCRIPT_OUTPUT_DIR ${CMAKE_BINARY_DIR}/FixupDependencies) #Directory where fixup-scripts will be written.
    foreach(FIXUP_TARGET IN LISTS FIXUP_TARGETS)
        if(NOT TARGET ${FIXUP_TARGET})
            message(FATAL_ERROR "${msg_hdr}  Got invalid target: ${FIXUP_TARGET}")
        endif()
        get_target_property(FIXUP_TARGET_TYPE ${FIXUP_TARGET} TYPE)
        if(NOT (${FIXUP_TARGET_TYPE} MATCHES SHARED_LIBRARY OR ${FIXUP_TARGET_TYPE} MATCHES EXECUTABLE) )
            message(STATUS "${msg_hdr}  Skipping non-shared target: ${FIXUP_TARGET}")
        else()
            set(FIXUP_INSTALL_SCRIPT ${FIXUP_SCRIPT_OUTPUT_DIR}/Fixup-Install-${FIXUP_TARGET}.cmake)
            set(FIXUP_INSTALL_SCRIPT_GEN_TMP ${FIXUP_SCRIPT_OUTPUT_DIR}/gen.tmp/Fixup-Install-${FIXUP_TARGET}.cmake.gen) #temporary file to use for immediate generation
            configure_file(${FIXUP_INSTALL_SCRIPT_TEMPLATE} ${FIXUP_INSTALL_SCRIPT_GEN_TMP} @ONLY)
            file(GENERATE OUTPUT ${FIXUP_INSTALL_SCRIPT} INPUT ${FIXUP_INSTALL_SCRIPT_GEN_TMP})
            install(SCRIPT ${FIXUP_INSTALL_SCRIPT})
            get_target_property(script ${FIXUP_TARGET} FIXUP_INSTALL_SCRIPT)
            if(script)
                message(STATUS "${msg_hdr} Re-generated install-tree dependency fixup script for target: ${FIXUP_TARGET}")
            else()
                message(STATUS "${msg_hdr} Generated install-tree dependency fixup script for target: ${FIXUP_TARGET}")
            endif()
            set_target_properties(${FIXUP_TARGET} PROPERTIES FIXUP_INSTALL_SCRIPT ${FIXUP_INSTALL_SCRIPT}) #Mark as fixup-ready.
            if(FIXUP_EXPORT_BUILD_TREE)
                get_target_property(_libs ${FIXUP_TARGET} LINK_LIBRARIES)
                if(NOT _libs)
                    set(_libs)
                endif()
                set(FIXUP_BUILD_TARGET_LINK_DIRECTORIES)
                foreach(_lib IN LISTS _libs)
                    if(TARGET ${_lib})
                        get_target_property(_type ${_lib} TYPE)
                        if(_type STREQUAL SHARED_LIBRARY OR _type STREQUAL EXECUTABLE)
                            list(APPEND FIXUP_BUILD_TARGET_LINK_DIRECTORIES "$<TARGET_FILE_DIR:${_lib}>")
                        endif()
                    elseif(IS_ABSOLUTE ${_lib})
                        list(APPEND FIXUP_BUILD_TARGET_LINK_DIRECTORIES ${_lib})
                    endif()
                endforeach()

                set(FIXUP_BUILD_SCRIPT ${FIXUP_SCRIPT_OUTPUT_DIR}/Fixup-Build-${FIXUP_TARGET}.cmake)
                set(FIXUP_BUILD_SCRIPT_GEN_TMP ${FIXUP_SCRIPT_OUTPUT_DIR}/gen.tmp/Fixup-Build-${FIXUP_TARGET}.cmake.gen) #temporary file to use for immediate generation
                configure_file(${FIXUP_BUILD_SCRIPT_TEMPLATE} ${FIXUP_BUILD_SCRIPT_GEN_TMP} @ONLY)
                file(GENERATE OUTPUT ${FIXUP_BUILD_SCRIPT} INPUT ${FIXUP_BUILD_SCRIPT_GEN_TMP})
                set(_build_target "FixupDependencies-${FIXUP_TARGET}")
#                 get_property(_all_targets GLOBAL PROPERTY FIXUP_ALL_CUSTOM_TARGETS)
                add_custom_command(TARGET ${FIXUP_TARGET} POST_BUILD COMMAND cmake ARGS -P ${FIXUP_BUILD_SCRIPT} COMMENT "FIXUP Build tree dependencies of target: ${FIXUP_TARGET}")
#                 set_property(GLOBAL APPEND PROPERTY FIXUP_ALL_CUSTOM_TARGETS ${_build_target})
                message(STATUS "${msg_hdr} Generated build-tree dependency fixup script for target: ${FIXUP_TARGET}")
            endif()
        endif()
    endforeach()
endfunction()
