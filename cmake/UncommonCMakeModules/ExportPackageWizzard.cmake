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
# Note by "Build Type" we mean the same thing as what cmake often calls "<CONFIG>" are the common build configurations
#   RELEASE, DEBUG, RELWITHDEBINFO, MINSIZEREL.  For Make generators this is the value of BUILD_TYPE.  For now we only
#  support useage on single build-type generators like Make.
#
# Respects options:
#  OPT_EXPORT_BUILD_TREE - If defined and false, don't export build tree
#
#
# Options:
#  DISABLE_EXPORT_BUILD_TREE - Disable the export of the build tree, if it would have otherwise been enabled.

# Single Argument Keywords
#  NAME - [Default: ${PACKAGE_NAME}] The name of the export. The name a client will use use to import with: find_package(NAME).  
#  NAMESPACE - [Default: $NAME}] The namespace in which to place  the export.
#  EXPORT_TARGETS_NAME - [Default: ${NAME}Targets] The name of the target export (the one used with the instal(TARGET EXPORT) keyword)
#                         set to OFF to disable exporting Targets.cmake file.
#  PACKAGE_CONFIG_TEMPLATE -  The template file for package config.
#         [Default: Look for PackageConfig.cmake.in under ${CMAKE_SOURCE_DIR}/cmake/<Templates|templatesModules|modules|>]
#  VERSION_COMPATIBILITY - [Default:AnyNewerVersion] The argument required by write_basic_package_version_file()
#  BUILD_TYPE_COMPATIBILITY - [Default:Exact]
#                               Exact - Require the BuildType of packages using this as a dependency to match build type exactly
#                               Any - Totally ignore BuildType
#  CONFIG_INSTALL_DIR - [Default: lib/${NAME}/cmake/] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  SHARED_CMAKE_INSTALL_DIR - [Default: share/${NAME}/cmake/] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  SHARED_CMAKE_SOURCE_DIR - [Default: ${CMAKE_SOURCE_DIR}/cmake] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
# Multi-Argument Keywords
#   PROVIDED_COMPONENTS - List of provided components which enables the version file to check for required components and reject builds with missing required components.
#                         If this variable is not set, the component check with PackageConfigVersion.cmake is disabled.
#   FIND_MODULES - List of relative paths to provided custom find module files to propagate with export and install.
#   EXPORTED_BUILD_TYPES - [default:${BUILD_TYPE}] The list of BUILD_TYPES this export will provide.  Normally this should just
#                           be the current BUILD_TYPE for single build-type generators like Make.
include(CMakePackageConfigHelpers)

function(export_package_wizzard)

### Parse arguments and set defaults
set(options DISABLE_EXPORT_BUILD_TREE)
set(oneValueArgs NAME NAMESPACE EXPORT_TARGETS_NAME PACKAGE_CONFIG_TEMPLATE_PATH VERSION_COMPATIBILITY
                 BUILD_TYPE_COMPATIBILITY CONFIG_INSTALL_DIR SHARED_CMAKE_INSTALL_DIR SHARED_CMAKE_SOURCE_DIR)
set(multiValueArgs FIND_MODULES EXPORTED_BUILD_TYPES PROVIDED_COMPONENTS)
cmake_parse_arguments(ARG "${options}" "${oneValueArgs}"  "${multiValueArgs}"  ${ARGN})
if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to export_package_wizzard(): \"${ARG_UNPARSED_ARGUMENTS}\"")
endif()

if(NOT ARG_NAME)
    set(ARG_NAME ${PROJECT_NAME})
endif()

if(NOT ARG_NAMESPACE)
    set(ARG_NAMESPACE ${ARG_NAME})
endif()

if(NOT DEFINED ARG_EXPORT_TARGETS_NAME)
    set(ARG_EXPORT_TARGETS_NAME ${ARG_NAME}Targets)
endif()

if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
    find_file(ARG_PACKAGE_CONFIG_TEMPLATE PackageConfig.cmake.in PATHS "${CMAKE_SOURCE_DIR}/cmake"
              PATH_SUFFIXES Modules modules Templates templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
    mark_as_advanced(ARG_PACKAGE_CONFIG_TEMPLATE)
    if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
        message(FATAL_ERROR "Unable to find PackageConfig.cmake.in. Cannot configure exports.")
    endif()
endif()

if(NOT ARG_VERSION_COMPATIBILITY)
    set(ARG_VERSION_COMPATIBILITY AnyNewerVersion)
endif()

if(NOT ARG_BUILD_TYPE_COMPATIBILITY)
    set(ARG_BUILD_TYPE_COMPATIBILITY Exact)
endif()

if(NOT ARG_EXPORTED_BUILD_TYPES)
    string(TOLOWER "${CMAKE_BUILD_TYPE}" ARG_EXPORTED_BUILD_TYPES)
endif()
if(NOT ARG_EXPORTED_BUILD_TYPES)
    message(FATAL_ERROR "No Exported build-types provided or CMAKE_BUILDT_TYPE is not set")
endif()

if(NOT ARG_CONFIG_INSTALL_DIR)
    set(ARG_CONFIG_INSTALL_DIR lib/${ARG_NAME}/cmake) #Where to install project Config.cmake and ConfigVersion.cmake files
endif()

if(NOT ARG_SHARED_CMAKE_INSTALL_DIR)
    set(ARG_SHARED_CMAKE_INSTALL_DIR share/${ARG_NAME}/cmake) #Where to install shared .cmake build scripts for downstream
endif()

if(NOT ARG_SHARED_CMAKE_SOURCE_DIR)
    set(ARG_SHARED_CMAKE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/cmake) #Source for shared .cmake build scripts for build-tree exports
endif()

if(NOT ARG_FIND_MODULES)
    set(ARG_FIND_MODULES)
endif()

if(DISABLE_EXPORT_BUILD_TREE OR CMAKE_CROSSCOMPILING OR CMAKE_EXPORT_NO_PACKAGE_REGISTRY OR (DEFINED OPT_EXPORT_BUILD_TREE AND NOT OPT_EXPORT_BUILD_TREE))
    set(ARG_EXPORT_BUILD_TREE False)
else()
    set(ARG_EXPORT_BUILD_TREE True)
endif()

if(ARG_UNPARSED_ARGUMENTS)
    message(WARNING "export_package_wizzard: Unrecognized arguments: ${ARG_UNPARSED_ARGUMENTS}")
endif()

set(ARG_CONFIG_DIR ${CMAKE_BINARY_DIR}) #Directory for generated .cmake config file.  Use CMAKE_CURRENT_BINARY_DIR to allow export of build dir.
set(ARG_PACKAGE_CONFIG_FILE ${ARG_NAME}Config.cmake) #<Package>Config.cmake name
set(ARG_VERSION_CONFIG_FILE ${ARG_NAME}ConfigVersion.cmake)

if(ARG_EXPORT_BUILD_TREE)
    set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_NAME}Config.cmake.install_tree) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
else()
    set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_PACKAGE_CONFIG_FILE}) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
endif()


### Generate Package Config files for downstream projects to utilize
#Generate and install ${PROJECT_NAME}ConfigVersion.cmake and related files to also check for BUILD_TYPE compatability
include(SmarterPackageVersionFile)
install_smarter_package_version_file(CONFIG_DIR ${ARG_CONFIG_DIR}
                                     INSTALL_DIR ${ARG_CONFIG_INSTALL_DIR}
                                     VERSION_COMPATIBILITY ${ARG_VERSION_COMPATIBILITY}
                                     BUILD_TYPE_COMPATIBILITY ${ARG_BUILD_TYPE_COMPATIBILITY}
                                     EXPORTED_BUILD_TYPES ${ARG_EXPORTED_BUILD_TYPES}
                                     PROVIDED_COMPONENTS ${ARG_PROVIDED_COMPONENTS})

#Generate: ${PROJECT_NAME}Config.cmake
#Copy modules PATH_VARS to easier to use names for use in PackageConfig.cmake.in
set(EXPORT_TARGETS_NAME ${ARG_EXPORT_TARGETS_NAME})
set(SHARED_CMAKE_DIR ${ARG_SHARED_CMAKE_INSTALL_DIR})
set(FIND_MODULES_PATH ${ARG_SHARED_CMAKE_INSTALL_DIR}) #Location to look for exported Find<XXX>.cmake modules provided by this package from install tree
configure_package_config_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE}
                              INSTALL_DESTINATION ${ARG_CONFIG_INSTALL_DIR}
                              PATH_VARS FIND_MODULES_PATH SHARED_CMAKE_DIR)

### Install tree export
#<Package>Config.cmake
install(FILES ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE} RENAME ${ARG_PACKAGE_CONFIG_FILE}
        DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)
#<Package>Targets.cmake
if(ARG_EXPORT_TARGETS_NAME) #set to OFF to disable exporting Targets.cmake file
    install(EXPORT ${ARG_EXPORT_TARGETS_NAME}
            NAMESPACE ${ARG_NAMESPACE}::
            DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)
endif()

#install provided Find<XXX>.cmake modules into the install tree
install(FILES ${ARG_FIND_MODULES} DESTINATION ${ARG_SHARED_CMAKE_INSTALL_DIR} COMPONENT Development)
        
### Build tree export
if(ARG_EXPORT_BUILD_TREE)
    #Generate: ${PROJECT_NAME}Config.cmake for use in exporting from the build-tree
    set(FIND_MODULES_PATH ${ARG_CONFIG_DIR})  #Location to look for exported Find<XXX>.cmake modules provided by this package from install tree
    #Note setting INSTALL_DESTINATION to ${ARG_CONFIG_DIR} for build tree PackageConfig.cmake as it is never installed to install tree
    set(SHARED_CMAKE_DIR ${ARG_SHARED_CMAKE_SOURCE_DIR})
    configure_package_config_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_FILE}
                              INSTALL_DESTINATION .
                              INSTALL_PREFIX ${ARG_CONFIG_DIR}
                              PATH_VARS FIND_MODULES_PATH SHARED_CMAKE_DIR)
    #copy provided Find<XXX>.cmake modules into the build tree
    foreach(module_path ${ARG_FIND_MODULES})
        get_filename_component(module_name ${module_path} NAME)
        configure_file(${module_path} ${ARG_CONFIG_DIR}/${module_name} COPYONLY)
    endforeach()
    #Make a ProjectTargets file for use in the build tree
    export(EXPORT ${ARG_EXPORT_TARGETS_NAME} FILE ${ARG_CONFIG_DIR}/${ARG_EXPORT_TARGETS_NAME}.cmake NAMESPACE ${ARG_NAMESPACE}::)
    #Add this project build tree to the CMake user package registry
    export(PACKAGE ${ARG_NAME})
endif()

endfunction()
