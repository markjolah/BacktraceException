#
# File: AddExternalDependency.cmake
# Mark J. Olah (mjo AT cs.unm.edu)
# copyright: Licensed under the Apache License, Version 2.0.  See LICENSE file.
# date: 2017
#
# Function: AddExternalDependency
#
# Allows a cmake package dependency to be automatically added as a cmake ExternalProject, then built and installed
# to CMAKE_INSTALL_PREFIX.  All this happens before configure time for the client package, so that the dependency will be
# automatically found through the cmake PackageConfig system and the normal find_package() mechanism.
#
# This approach eliminates the need for an explicit git submodule for the external package, and it allows the client package to
# be quickly built on systems where the ExternalProject is already installed.
#
# useage: AddExternalDependency(<package-name> <package-git-clone-url> [SHARED] [STATIC])

set(AddExternalDependency_include_path ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "Path of AddExternalDependency.cmake")

macro(add_external_dependency)
    cmake_parse_arguments(_ExtProject "SHARED;STATIC" "NAME;URL;INSTALL_PREFIX;CMAKELISTS_TEMPLATE" "" ${ARGN})
    if(NOT _ExtProject_NAME)
        message(FATAL_ERROR "No package name given")
    endif()
    if(_ExtProject_UNPARSED_ARGUMENTS)
        message(WARNING "[add_external_dependency] UNPARSED ARGUMENTS:${_ExtProject_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT _ExtProject_INSTALL_PREFIX)
        set(_ExtProject_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
    endif()

    #override _ExtProject_URL passed in with environment variable
    set(_ExtProject_URL_ENV $ENV{${_ExtProject_NAME}URL})
    if(_ExtProject_URL_ENV)
        set(_ExtProject_URL $ENV{${_ExtProject_NAME}URL})
    endif()
        
    find_package(${_ExtProject_NAME} CONFIG)
    string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
    if(NOT ${_ExtProject_NAME}_FOUND OR (${_ExtProject_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_ExtProject_NAME}_BUILD_TYPES )))
        set(_ExtProject_Dir ${CMAKE_BINARY_DIR}/External/${_ExtProject_NAME})
        message(STATUS "[add_external_dependency] Not found: ${_ExtProject_NAME}")
        if(${_ExtProject_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_ExtProject_NAME}_BUILD_TYPES))
            message(STATUS "[add_external_dependency] ${_ExtProject_NAME} Build types: {${${_ExtProject_NAME}_BUILD_TYPES}}; Does not satisfy current build type: ${BUILD_TYPE}.")
        endif()
        if(NOT _ExtProject_INSTALL_PREFIX)
            message(FATAL_ERROR "[add_external_dependency]  CMAKE_INSTALL_PREFIX is not set and INSTALL_PREFIX argument is not set."
                                "  Cannot use AddExternalDependency to autoinstall ${_ExtProject_NAME}"
                                "   Recommend: (1) Set CMAKE_INSTALL_PREFIX to a valid directory.  This can be a local directory if this package is to be exported"
                                "                  directly from the build tree."
                                "              (2) Install dependency ${_ExtProject_NAME} from URL: ${_ExtProject_URL} to a user or system location cmake can find.")
        endif()
        if(NOT _ExtProject_URL)
            message(FATAL_ERROR "[add_external_autotools_dependency] No URL provided.")
        endif()
        message(STATUS "[add_external_dependency] Initializing as ExternalProject URL:${_ExtProject_URL}")
        message(STATUS "[add_external_dependency] BUILD_STATIC_LIBS:${_ExtProject_STATIC} BUILD_SHARED_LIBS:${_ExtProject_SHARED}")
        message(STATUS "[add_external_dependency] ExtProjectBuildTypes:${${_ExtProject_NAME}_BUILD_TYPES}")
        
        if(NOT _ExtProject_CMAKELISTS_TEMPLATE)
            find_file(_ExtProject_CMAKELISTS_TEMPLATE NAME External.CMakeLists.txt.in PATHS ${AddExternalDependency_include_path}/Templates)
        endif()
        configure_file(${_ExtProject_CMAKELISTS_TEMPLATE} ${_ExtProject_Dir}/CMakeLists.txt @ONLY)
        execute_process(COMMAND ${CMAKE_COMMAND} . WORKING_DIRECTORY ${_ExtProject_Dir})
        message(STATUS "[add_external_dependency] Downloading Building and Installing: ${_ExtProject_NAME}")
        execute_process(COMMAND ${CMAKE_COMMAND} --build . WORKING_DIRECTORY ${_ExtProject_Dir})
        find_package(${_ExtProject_NAME} CONFIG PATHS ${_ExtProject_INSTALL_PREFIX}/lib/cmake/${_ExtProject_NAME} NO_CMAKE_FIND_ROOT_PATH)
        if(NOT ${_ExtProject_NAME}_FOUND)
            message(FATAL_ERROR "[add_external_dependency] Install of ${_ExtProject_NAME} failed.")
        endif()
        message(STATUS "[add_external_dependency] Installed: ${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION} Location:${_ExtProject_INSTALL_PREFIX}")
    else()
        message(STATUS "[add_external_dependency] Found:${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION} Install-Prefix:${_ExtProject_INSTALL_PREFIX}")
    endif()
endmacro()