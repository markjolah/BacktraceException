# AddSharedStaticLibraries.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENSE file
#
# Useage: add_shared_static_libraries()
# Options:
#  NO_INSTALL - Do not install the libraries
# Single-value keywords:
#  RETURN_TARGETS - [optional] A return variable that returns a list of all targets created.  To get individual shared/static targets use the specific versions below.
#  RETURN_SHARED_TARGET - [optional] A return variable that returns just the shared target [if it was produced correctly]
#  RETURN_STATIC_TARGET - [optional] A return variable that returns just the static target [if it was produced correctly]
#  NAMESPACE - [Optional default: ${PROJECT_NAME}] The name of the namespace (without ::) intowhich the libraries will be exported
#  LIBTARGET target_name - [Optional] The name of the library target to create and export (defaults to same as Namespace)
#  STATIC_LIBTARGET target_name - [Optional] The name of the static library target to create
#                                           and export when both shared and static are enabled.
#  EXPORT_TARGETS_NAME [Default: ${PROJECT_NAME}Targets] The name of the export targets to produce.
#  BUILD_SHARED_LIBS - bool [Default: ${BUILD_SHARED_LIBS}] works as expected for common cmake useage.
#     If "ON" then shared libraries are produced and exported.  If "OFF" then static libraries are produced and exported.
#  BUILD_SHARED_LIBS - bool [Default: ${BUILD_STATIC_LIBS}] If "ON" then build of the static libraries.
#  PUBLIC_HEADER_DIR - Directory in source for public header includes (this directory should contain
#                           another directory names ${PACKAGE_NAME} with the actual headers
#                         If unset skip setting of target properties and installing debug headers.
#  PUBLIC_DEBUG_HEADER_DIR - Directory in source for debugging public header includes.
#           Installed as part of Development component under Debug configuration.
#           If unset skip setting of target properties and installing debug headers.
# Multi-value keywords:
#  SOURCES - List of sources.
#  COMPILE_FEATURES - [optional] list of PUBLIC compile features for each target
#  INCLUDE_DIRECTORIES - [optional] list of PUBLIC include directories for each target
#  LINK_LIBRARIES - [optional] list of PUBLIC link_libraries
#
#
# * POSITION_INDEPENDENT_CODE is enabled for static libraries by default.  This allows downstream
#     projects to link statically and be bundled into a client that is itself a shared library.  Also
#     no performance gains are likely being given up.

function(add_shared_static_libraries)
    set(options NO_INSTALL)
    set(oneValueArgs RETURN_TARGETS RETURN_SHARED_TARGET RETURN_STATIC_TARGET
                     NAMESPACE LIBTARGET STATIC_LIBTARGET
                     BUILD_SHARED_LIBS BUILD_STATIC_LIBS
                     PUBLIC_HEADER_DIR PUBLIC_DEBUG_HEADER_DIR)
    set(multiValueArgs SOURCES COMPILE_FEATURES INCLUDE_DIRECTORIES LINK_LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "add_shared_static_libraries: Unknown keywords given to add_shared_static_libraries(): \"${ARG_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT ARG_BUILD_SHARED_LIBS)
        set(ARG_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
    endif()
    if(NOT ARG_BUILD_STATIC_LIBS)
        set(ARG_BUILD_STATIC_LIBS ${BUILD_STATIC_LIBS})
    endif()
    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE ${PROJECT_NAME})
    endif()

    if(NOT ARG_LIBTARGET)
        set(ARG_LIBTARGET ${PROJECT_NAME})
    endif()

    if(NOT ARG_STATIC_LIBTARGET)
        set(ARG_STATIC_LIBTARGET ${PROJECT_NAME}_static)
    endif()

    set(LIB_TARGETS ${ARG_LIBTARGET}) # List of targets to configure.  At most: the shared and static library targets.
    set(SHARED_TARGET False)
    set(STATIC_TARGET False)
    if(ARG_BUILD_SHARED_LIBS)
        add_library(${ARG_LIBTARGET} SHARED ${ARG_SOURCES})
        add_library(${ARG_NAMESPACE}::${ARG_LIBTARGET} ALIAS ${ARG_LIBTARGET})
        set(SHARED_TARGET ${ARG_LIBTARGET})
        if(ARG_BUILD_STATIC_LIBS)
            add_library(${ARG_STATIC_LIBTARGET} STATIC ${ARG_SOURCES})
            add_library(${ARG_NAMESPACE}::${ARG_STATIC_LIBTARGET} ALIAS ${ARG_STATIC_LIBTARGET})
            set_target_properties(${ARG_STATIC_LIBTARGET} PROPERTIES OUTPUT_NAME ${ARG_LIBTARGET})
            set_target_properties(${ARG_STATIC_LIBTARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON)
            list(APPEND LIB_TARGETS ${ARG_STATIC_LIBTARGET})
            set(STATIC_TARGET ${ARG_STATIC_LIBTARGET})
        endif()
    else()
        #Build static only
        add_library(${ARG_LIBTARGET} STATIC ${ARG_SOURCES})
        add_library(${ARG_NAMESPACE}::${ARG_LIBTARGET} ALIAS ${ARG_LIBTARGET})
        set_target_properties(${ARG_LIBTARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON)
        set(STATIC_TARGET ${ARG_LIBTARGET})
    endif()

    if(NOT ARG_NO_INSTALL)
        install(TARGETS ${LIB_TARGETS} EXPORT ${PROJECT_NAME}Targets
            RUNTIME DESTINATION bin COMPONENT Runtime
            LIBRARY DESTINATION lib COMPONENT Runtime
            ARCHIVE DESTINATION lib COMPONENT Development)
        if(ARG_PUBLIC_HEADER_DIR)
            if(NOT EXISTS ${ARG_PUBLIC_HEADER_DIR})
                message(FATAL_ERROR "add_shared_static_libraries: Cannot find PUBLIC_HEADER_DIR:${ARG_PUBLIC_HEADER_DIR}")
            endif()
            install(DIRECTORY ${ARG_PUBLIC_HEADER_DIR}/ DESTINATION include COMPONENT Development)
        endif()
        if(ARG_PUBLIC_DEBUG_HEADER_DIR)
            if(NOT EXISTS ${ARG_PUBLIC_DEBUG_HEADER_DIR})
                message(FATAL_ERROR "add_shared_static_libraries: Cannot find PUBLIC_DEBUG_HEADER_DIR: ${ARG_PUBLIC_DEBUG_HEADER_DIR}")
            endif()
            install(DIRECTORY ${ARG_PUBLIC_DEBUG_HEADER_DIR}/ DESTINATION include CONFIGURATIONS Debug COMPONENT Development)
        endif()
    endif()

    #Set target include directories if PUBLIC_HEADER_DIR or PUBLIC_DEBUG_HEADER_DIR were given
    if(ARG_PUBLIC_HEADER_DIR)
        foreach(target IN LISTS LIB_TARGETS)
            if(NOT ARG_PUBLIC_DEBUG_HEADER_DIR)
                target_include_directories(${target} PUBLIC $<BUILD_INTERFACE:${ARG_PUBLIC_HEADER_DIR}>
                                                            $<INSTALL_INTERFACE:include>)
            else()
                target_include_directories(${target} PUBLIC $<BUILD_INTERFACE:${ARG_PUBLIC_HEADER_DIR}>
                                                            $<BUILD_INTERFACE:$<$<CONFIG:Debug>:${ARG_PUBLIC_DEBUG_HEADER_DIR}>>
                                                            $<INSTALL_INTERFACE:include>)
            endif()
        endforeach()
    endif()
    if(ARG_COMPILE_FEATURES)
        foreach(target IN LISTS LIB_TARGETS)
            target_compile_features(${target} PUBLIC ${ARG_COMPILE_FEATURES})
        endforeach()
    endif()
    if(ARG_LINK_LIBRARIES)
        foreach(target IN LISTS LIB_TARGETS)
            target_link_libraries(${target} PUBLIC ${ARG_LINK_LIBRARIES})
        endforeach()
    endif()
    if(ARG_INCLUDE_DIRECTORIES)
        foreach(target IN LISTS LIB_TARGETS)
            target_include_directories(${target} PUBLIC ${ARG_INCLUDE_DIRECTORIES})
        endforeach()
    endif()
    if(ARG_RETURN_TARGETS)
        set(${ARG_RETURN_TARGETS} ${LIB_TARGETS} PARENT_SCOPE)
    endif()
    if(ARG_RETURN_STATIC_TARGET)
        set(${ARG_RETURN_STATIC_TARGET} ${STATIC_TARGET} PARENT_SCOPE)
    endif()
     if(ARG_RETURN_SHARED_TARGET)
        set(${ARG_RETURN_SHARED_TARGET} ${SHARED_TARGET} PARENT_SCOPE)
    endif()
endfunction()
