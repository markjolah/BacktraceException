#
# File: AddExternalAutotoolsDependency.cmake
# Mark J. Olah (mjo AT cs.unm.edu)
# copyright: Licensed under the Apache License, Version 2.0.  See LICENSE file.
# date: 2017
#
# Function: add_external_autotools_dependency
#
# Allows a autotools-based package dependency to be automatically added as a cmake ExternalProject, then built and installed
# to CMAKE_INSTALL_PREFIX.  All this happens before configure time for the client package, so that the dependency will be
# automatically found through the cmake PackageConfig system and the normal find_package() mechanism.
#
# This approach eliminates the need for an explicit git submodule for the external package, and it allows the client package to
# be quickly built on systems where the ExternalProject is already installed.
#
# useage: AddExternalDependency(<package_name> <package-git-clone-url> [SHARED] [STATIC])
cmake_policy(SET CMP0057 NEW)
set(AddExternalAutotoolsDependency_include_path ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "Path of AddExternalAutotoolsDependency.cmake")

macro(add_external_autotools_dependency)
    cmake_parse_arguments(_ExtProject "SHARED;STATIC" "NAME;URL;INSTALL_PREFIX;CMAKELISTS_TEMPLATE" "" "${ARGN}")
    if(NOT _ExtProject_NAME)
        message(FATAL_ERROR "No package name given")
    endif()
    if(_ExtProject_UNPARSED_ARGUMENTS)
        message(WARNING "[add_external_autotools_dependency] UNPARSED ARGUMENTS:${_ExtProject_UNPARSED_ARGUMENTS}")
    endif()
    if(NOT _ExtProject_INSTALL_PREFIX)
        set(_ExtProject_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
    endif()
    
    #override ExtProjectURL passed in with environment variable
    set(_ExtProjectURL_ENV $ENV{${_ExtProject_NAME}URL})
    if(_ExtProjectURL_ENV)
        set(_ExtProject_URL $ENV{${_ExtProject_NAME}URL})
    endif()
        
    find_package(${_ExtProject_NAME})
    if(NOT ${_ExtProject_NAME}_FOUND)
        set(_ExtProject_Dir ${CMAKE_BINARY_DIR}/External/${_ExtProject_NAME})
        message(STATUS "[add_external_autotools_dependency] 3rd Party Package Not found: ${_ExtProject_NAME}")
        if(NOT _ExtProject_INSTALL_PREFIX)
            message(FATAL_ERROR "[add_external_autotools_dependency] CMAKE_INSTALL_PREFIX is not set and INSTALL_PREFIX argument is not set.  "
                                "   Cannot use add_external_autotools_dependency to autoinstall ${_ExtProject_NAME}."
                                "   Recommend: (1) Set CMAKE_INSTALL_PREFIX to a valid directory.  This can be a local directory if this package is to be exported"
                                "                  directly from the build tree."
                                "              (2) Install dependency ${_ExtProject_NAME} from URL: ${_ExtProject_URL} to a user or system location cmake can find.")
        endif()
        if(NOT _ExtProject_URL)
            message(FATAL_ERROR "[add_external_autotools_dependency] No URL provided.")
        endif()
        
        if(NOT _ExtProject_CMAKELISTS_TEMPLATE)
            find_file(_ExtProject_CMAKELISTS_TEMPLATE NAME ExternalAutotools.CMakeLists.txt.in PATHS ${AddExternalAutotoolsDependency_include_path}/Templates)
        endif()
        message(STATUS "[add_external_autotools_dependency] Initializing as ExternalProject using git URL:${_ExtProject_URL}")
        message(STATUS "[add_external_autotools_dependency] Installing to: ${_ExtProject_INSTALL_PREFIX}")
        configure_file(${_ExtProject_CMAKELISTS_TEMPLATE} ${_ExtProject_Dir}/CMakeLists.txt @ONLY)
        execute_process(COMMAND ${CMAKE_COMMAND} . WORKING_DIRECTORY ${_ExtProject_Dir})
        message(STATUS "[add_external_autotools_dependency] Downloading Building and Installing: ${_ExtProject_NAME}")
        execute_process(COMMAND ${CMAKE_COMMAND} --build . WORKING_DIRECTORY ${_ExtProject_Dir})
        find_package(${_ExtProject_NAME} REQUIRED)
        if(NOT ${_ExtProject_NAME}_FOUND)
            message(FATAL_ERROR "[add_external_autotools_dependency] Install of ${_ExtProject_NAME} failed.")
        endif()
        message(STATUS "[add_external_autotools_dependency] Installed: ${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION} Location:${_ExtProject_INSTALL_PREFIX}")
    else()
        message(STATUS "[add_external_autotools_dependency] Found:${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION}")
    endif()
endmacro()
