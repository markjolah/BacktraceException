# ExportPackageWizzard.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017-2018
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Prepare cmake package configuration and target export files so that
# this package can be found both from the install tree and the build tree
# This simple function provides enough flexibility to meet 90% of the use cases of small cmake projects.
# For more complex tasks it can be customized easily.
#
# Options:
#  DISABLE_BUILD_EXPORT - Disable the export of the build tree.  Those configuration files generated for install tree export will
#                         still be generated in the build tree.  Note cmake variable CMAKE_EXPORT_NO_PACKAGE_REGISTRY=1 will disable
#                         the effect of the export(PACKAGE) call, but other build export tasks are still enabled unless this option 
#                         is used.
# Single Argument Keywords
#  NAME - [Default: ${PACKAGE_NAME}] The name of the export. The name a client will use use to import with: find_package(NAME).  
#  NAMESPACE - [Default: ${PACKAGE_NAME}] The namespace in which to place  the export.
#  EXPORT_TARGETS_NAME - [Default: ${PACKAGE_NAME}Targets] The name of the target export (the one used with the instal(TARGET EXPORT) keyword)
#  PACKAGE_CONFIG_TEMPLATE_PATH -  [Default: Look for PackageConfig.cmake.in under ${CMAKE_SOURCE_DIR}/cmake]  The template file for package config.
#                             This typically must be customized for each project.
#  VERSION_COMPATABILITY - [Default:SameMajorVersion] The argument required by write_basic_package_version_file()
#  CONFIG_INSTALL_DIR - [Default: lib/cmake/${PROJECT_NAME}] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  SHARED_CMAKE_INSTALL_DIR - [Default: share/${PROJECT_NAME}/cmake/] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#
# Multi-Argument Keywords
#   FIND_MODULES - List of relative paths to provided custome find module files to propgate with export and install.
include(CMakePackageConfigHelpers)

function(export_package_wizzard)

### Parse arguments and set defaults
cmake_parse_arguments(PARSE_ARGV 0 "_WIZ" 
                      "DISABLE_BUILD_EXPORT" 
                      "NAME;NAMESPACE;EXPORT_TARGETS_NAME;PACKAGE_CONFIG_TEMPLATE_PATH;VERSION_COMPATABILITY;CONFIG_INSTALL_DIR;SHARED_CMAKE_INSTALL_DIR"
                      "FIND_MODULES")
if(NOT _WIZ_NAME)
    set(_WIZ_NAME ${PROJECT_NAME})
endif()

if(NOT _WIZ_NAMESPACE)
    set(_WIZ_NAMESPACE ${PROJECT_NAME})
endif()

if(NOT _WIZ_EXPORT_TARGETS_NAME)
    set(_WIZ_EXPORT_TARGETS_NAME ${PROJECT_NAME}Targets)
endif()

if(NOT _WIZ_PACKAGE_CONFIG_TEMPLATE_PATH)
    find_file(_WIZ_PACKAGE_CONFIG_TEMPLATE_PATH PackageConfig.cmake.in PATHS "${CMAKE_SOURCE_DIR}/cmake" 
              PATH_SUFFIXES Templates templates NO_DEFAULT_PATH)
    if(NOT _WIZ_PACKAGE_CONFIG_TEMPLATE_PATH)
        message(FATAL_ERROR "Unable to find PackageConfig.cmake.in. Cannot configure exports.")
    endif()
endif()

if(NOT _WIZ_VERSION_COMPATABILITY)
    set(_WIZ_VERSION_COMPATABILITY SameMajorVersion)
endif()

if(NOT _WIZ_CONFIG_INSTALL_DIR)
    set(_WIZ_CONFIG_INSTALL_DIR lib/cmake/${PROJECT_NAME}) #Where to install project Config.cmake and ConfigVersion.cmake files
endif()

if(NOT _WIZ_SHARED_CMAKE_INSTALL_DIR)
    set(_WIZ_SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake) #Where to install shared .cmake build scripts for downstream
endif()

if(NOT _WIZ_FIND_MODULES)
    set(_WIZ_FIND_MODULES)
endif()

if(_WIZ_UNPARSED_ARGUMENTS)
    message(WARNING "export_package_wizzard: Unrecognized arguments: ${_WIZ_UNPARSED_ARGUMENTS}")
endif()

set(_WIZ_CONFIG_DIR ${CMAKE_BINARY_DIR}) #Directory for generated .cmake config file.  Use CMAKE_CURRENT_BINARY_DIR to allow export of build dir.
set(_WIZ_PACKAGE_CONFIG_FILE ${_WIZ_NAME}Config.cmake) #<Package>Config.cmake name
set(_WIZ_VERSION_CONFIG_FILE ${_WIZ_NAME}ConfigVersion.cmake)

if(NOT _WIZ_DISABLE_BUILD_EXPORT)
    set(_WIZ_PACKAGE_CONFIG_INSTALL_TREE_FILE ${_WIZ_NAME}Config.cmake.install_tree) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
else()
    set(_WIZ_PACKAGE_CONFIG_INSTALL_TREE_FILE ${_WIZ_PACKAGE_CONFIG_FILE}) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
endif()


### Generate Package Config files for downstream projects to utilize
#Generate:${PROJECT_NAME}ConfigVersion.cmake
write_basic_package_version_file(${_WIZ_CONFIG_DIR}/${_WIZ_VERSION_CONFIG_FILE} COMPATIBILITY ${_WIZ_VERSION_COMPATABILITY})

#Remove the _WIZ prefix if EXPORT_TARGETS_NAME is not in use.  This simplifies writing of PackageConfig.cmake.in
if(NOT EXPORT_TARGETS_NAME)
    set(EXPORT_TARGETS_NAME ${_WIZ_EXPORT_TARGETS_NAME})
endif()
#Generate: ${PROJECT_NAME}Config.cmake

set(_WIZ_FIND_MODULES_PATH ${_WIZ_SHARED_CMAKE_INSTALL_DIR}) #Location to look for exported Find<XXX>.cmake modules provided by this package from install tree
configure_package_config_file(${_WIZ_PACKAGE_CONFIG_TEMPLATE_PATH} ${_WIZ_CONFIG_DIR}/${_WIZ_PACKAGE_CONFIG_INSTALL_TREE_FILE}
                              INSTALL_DESTINATION ${_WIZ_CONFIG_INSTALL_DIR}
                              PATH_VARS _WIZ_FIND_MODULES_PATH _WIZ_CONFIG_INSTALL_DIR _WIZ_SHARED_CMAKE_INSTALL_DIR)

### Install tree export
#<Package>ConfigVersion.cmake
install(FILES ${_WIZ_CONFIG_DIR}/${_WIZ_VERSION_CONFIG_FILE}
        DESTINATION ${_WIZ_CONFIG_INSTALL_DIR} COMPONENT Development)
#<Package>Config.cmake
install(FILES ${_WIZ_CONFIG_DIR}/${_WIZ_PACKAGE_CONFIG_INSTALL_TREE_FILE} RENAME ${_WIZ_PACKAGE_CONFIG_FILE}
        DESTINATION ${_WIZ_CONFIG_INSTALL_DIR} COMPONENT Development)
#<Package>Targets.cmake
install(EXPORT ${_WIZ_EXPORT_TARGETS_NAME} 
        NAMESPACE ${_WIZ_NAMESPACE}::
        DESTINATION ${_WIZ_CONFIG_INSTALL_DIR} COMPONENT Development)

#install provided Find<XXX>.cmake modules into the install tree
foreach(module_path IN ITEMS ${_WIZ_FIND_MODULES})
    install(FILES ${module_path} DESTINATION ${_WIZ_SHARED_CMAKE_INSTALL_DIR} COMPONENT Development)
endforeach()
        
### Build tree export
if(NOT _WIZ_DISABLE_BUILD_EXPORT)
    #Generate: ${PROJECT_NAME}Config.cmake for use in exporting from the build-tree
    set(_WIZ_FIND_MODULES_PATH ${_WIZ_CONFIG_DIR})  #Location to look for exported Find<XXX>.cmake modules provided by this package from install tree
    #Note setting INSTALL_DESTINATION to ${_WIZ_CONFIG_DIR} for build tree PackageConfig.cmake as it is never installed to install tree
    configure_package_config_file(${_WIZ_PACKAGE_CONFIG_TEMPLATE_PATH} ${_WIZ_CONFIG_DIR}/${_WIZ_PACKAGE_CONFIG_FILE}
                              INSTALL_DESTINATION ${_WIZ_CONFIG_DIR}
                              PATH_VARS _WIZ_FIND_MODULES_PATH _WIZ_CONFIG_INSTALL_DIR _WIZ_SHARED_CMAKE_INSTALL_DIR)
    #copy provided Find<XXX>.cmake modules into the build tree
    foreach(module_path IN ITEMS ${_WIZ_FIND_MODULES})
        get_filename_component(module_name ${module_path} NAME)
        configure_file(${module_path} ${_WIZ_CONFIG_DIR}/${module_name} COPYONLY)
    endforeach()
    #Make a ProjectTargets file for use in the build tree
    export(EXPORT ${_WIZ_EXPORT_TARGETS_NAME} FILE ${CMAKE_BINARY_DIR}/${_WIZ_EXPORT_TARGETS_NAME}.cmake NAMESPACE ${_WIZ_NAMESPACE}::)
    #Add this project build tree to the CMake user package registry
    export(PACKAGE ${_WIZ_NAME})
endif()

endfunction()
