# WriteSmarterPackageVersionFile.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017-2018
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# A PackageVersion.cmake file generator that is aware of build types
#
# Options:
# Single Argument Keywords
#   VERSION - [optional] version string to match for this export.
#   CONFIG_DIR - [optional] [default: ${CMAKE_BINARY_DIR}] Location to configure the files before installation.
#                 This should also match where the build-tree export PackageConfig.cmake file is to enable version selection for
#                 build-tree exports in the user package registry.
#   TEMPLATE_FILE - [optional] Main template file for use by the ordinary WRITE_BASIC_CONFIG_VERSION_FILE
#   INSTALL_DIR - [optional] Default: lib/cmake/${PROJECT_NAME}
#   VERSION_COMPATIBILITY - [optional] Default: AnyNewerVersion Options: <AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion>
#   BUILD_TYPE_COMPATIBILITY - [optional] Default: Exact Options:<Exact|Any>
# Multi-Argument Keywords
#   EXPORTED_BUILD_TYPES - [optional] Default: ${BUILD_TYPE}
include(CMakePackageConfigHelpers)
set(_WriteSmarterPackageVersionFile_PATH ${CMAKE_CURRENT_LIST_DIR})
function(install_smarter_package_version_file)
    set(options)
    set(oneValueArgs VERSION TEMPLATE_FILE CONFIG_DIR INSTALL_DIR VERSION_COMPATIBILITY BUILD_TYPE_COMPATIBILITY)
    set(multiValueArgs EXPORTED_BUILD_TYPES)
    cmake_parse_arguments(_SVF "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(_SVF_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to install_smarter_package_version_file(): \"${_SVF_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT _SVF_VERSION)
        set(_SVF_VERSION ${PACKAGE_VERSION})
    endif()
    if(NOT _SVF_CONFIG_DIR)
        set(_SVF_CONFIG_DIR ${CMAKE_BINARY_DIR})
    endif()
    if(NOT _SVF_INSTALL_DIR)
        set(_SVF_INSTALL_DIR lib/cmake/${PROJECT_NAME})
    endif()
    if(NOT _SVF_VERSION_COMPATIBILITY)
        set(_SVF_VERSION_COMPATIBILITY AnyNewerVersion)
    endif()
    if(NOT _SVF_BUILD_TYPE_COMPATIBILITY)
        set(_SVF_BUILD_TYPE_COMPATIBILITY Exact)
    endif()
    if(NOT _SVF_EXPORTED_BUILD_TYPES)
        string(TOUPPER "${CMAKE_BUILD_TYPE}" _SVF_EXPORTED_BUILD_TYPES)
    endif()

    set(_SVF_TEMPLATE_DIR ${_WriteSmarterPackageVersionFile_PATH}/Templates)

    #Generate the normal write_basic_config_version_file as ${PROJECT_NAME}ConfigVersionNumber.cmake
    set(_SVF_NUMERIC_VERSION_FILE ${_SVF_CONFIG_DIR}/${PROJECT_NAME}ConfigVersionNumber.cmake)
    if(NOT _SVF_TEMPLATE_FILE)
        write_basic_config_version_file(${_SVF_NUMERIC_VERSION_FILE} VERSION ${_SVF_VERSION} COMPATIBILITY ${_SVF_VERSION_COMPATIBILITY})
    else()
        write_basic_config_version_file(${_SVF_NUMERIC_VERSION_FILE} VERSION ${_SVF_VERSION} COMPATIBILITY ${_SVF_VERSION_COMPATIBILITY}
                                        TEMPLATE_FILE ${_SVF_TEMPLATE_FILE})
    endif()
    install(FILES ${_SVF_NUMERIC_VERSION_FILE} DESTINATION ${_SVF_INSTALL_DIR} COMPONENT Development)

    #Generate and install PackageVersionBuildType-<BUILD_TYPE>.cmake
    # This files appends EXPORTED_BUILD_TYPES to PACKAGE_BUILD_TYPES when called by find_package for use in main PackageConfigVersion.cmake
    set(_SVF_EXPORTED_BUILD_TYPE_TEMPLATE ${_SVF_TEMPLATE_DIR}/SmarterPackageVersionBuildType.cmake.in)
    string(CONCAT _SVF_BUILD_TYPE_NAME ${_SVF_EXPORTED_BUILD_TYPES})
    set(_SVF_EXPORTED_BUILD_TYPE_FILE ${_SVF_CONFIG_DIR}/${PROJECT_NAME}ConfigVersionBuildType-${_SVF_BUILD_TYPE_NAME}.cmake)
    configure_file(${_SVF_EXPORTED_BUILD_TYPE_TEMPLATE} ${_SVF_EXPORTED_BUILD_TYPE_FILE} @ONLY)
    install(FILES ${_SVF_EXPORTED_BUILD_TYPE_FILE} DESTINATION ${_SVF_INSTALL_DIR} COMPONENT Development)

    #Generate and install the primary PackageConfigVersion.cmake file
    # The file template used depends on the choice of BUILD_TYPE_COMPATIBILITY
    set(_SVF_CONFIG_VERSION_TEMPLATE ${_SVF_TEMPLATE_DIR}/SmarterPackageVersion-${_SVF_BUILD_TYPE_COMPATIBILITY}.cmake.in)
    set(_SVF_CONFIG_VERSION_FILE ${_SVF_CONFIG_DIR}/${PROJECT_NAME}ConfigVersion.cmake)
    configure_file(${_SVF_CONFIG_VERSION_TEMPLATE} ${_SVF_CONFIG_VERSION_FILE} @ONLY)
    install(FILES ${_SVF_CONFIG_VERSION_FILE} DESTINATION ${_SVF_INSTALL_DIR} COMPONENT Development)
endfunction()
