#
# File: AddExternalDependency.cmake
# Mark J. Olah (mjo AT cs.unm.edu)
# date: 2017-2018
# copyright: Licensed under the Apache License, Version 2.0.  See LICENSE file.
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
# Options:
#   STATIC - Require static libraries.  [default=OFF]
#   SHARED - Require shared libraries.  If neither SHARED nor STATIC is set, then SHARED is default.
#   TESTING - Attempt to build testing functionality. [default=OFF]
# Single-Value arguments:
#   NAME - [required] Name of PROJECT_NAME of the external cmake project
#   URL - URL of git repository or local path to git repository (can be overwritten with ${PROJECT_NAME}URL environment variable giving alternate URL
#   VERSION - [optional] Version number of dependency required. Leave empty for any version with appropriate BUILD_TYPE_COMPATABILITY
#   INSTALL_PREFIX - [optional] install location for package [defaults to CMAKE_INSTALL_PREFIX]
#   CMAKELISTS_TEMPLATE - [optional] Template file for the CMakeLists.txt to the building and installing via ExternalProject_Add [default: Templates/External.CMakeLists.txt.in]
#   BUILD_TYPE_COMPATABILITY - [optional] Default: Exact  Options: Exact, Any
#   TOOLCHAIN_FILE - [optional] [Only used if CMAKE_CROSSCOMPILING is true.  Uses CMAKE_TOOLCHAIN_FILE as the default.]
#Multi-arguments
#  PASS_CACHE_VARIABLES - [optional] List of cache variables to pass-through
#  COMPONENTS - [optional] List of required components for find_package
set(AddExternalDependency_include_path ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "Path of AddExternalDependency.cmake")

macro(add_external_dependency)
    set(options SHARED STATIC TESTING)
    set(oneArgOpts NAME URL VERSION INSTALL_PREFIX CMAKELISTS_TEMPLATE BUILD_TYPE_COMPATABILITY TOOLCHAIN_FILE)
    set(multiArgOpts PASS_CACHE_VARIABLES COMPONENTS)
    cmake_parse_arguments(_ExtProject "${options}" "${oneArgOpts}" "${multiArgOpts}" ${ARGN})
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

    if(NOT _ExtProject_BUILD_TYPE_COMPATABILITY)
        set(_ExtProject_BUILD_TYPE_COMPATABILITY Exact)
    endif()

    if(CMAKE_CROSSCOMPILING AND NOT _ExtProject_TOOLCHAIN_FILE)
        set(_ExtProject_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
    endif()
    #Determine extra variables to pass on command line.
    #Try not to pass anything a child would not accept as it generates ugly warnings
    if(_ExtProject_SHARED)
        list(APPEND _ExtProject_PASS_CACHE_VARIABLES BUILD_SHARED)
    endif()
    if(_ExtProject_STATIC)
        list(APPEND _ExtProject_PASS_CACHE_VARIABLES BUILD_STATIC)
    endif()
    if(_ExtProject_TESTING)
        list(APPEND _ExtProject_PASS_CACHE_VARIABLES BUILD_TESTING)
    endif()

    #Fixup each passed cache variable
    if(_ExtProject_PASS_CACHE_VARIABLES)
        set(_pass_vars)
        foreach(_var IN LISTS _ExtProject_PASS_CACHE_VARIABLES)
            if(${_var} MATCHES "([A-Za-z0-9_]+)=([A-Za-z0-9_]+)")
                set(_var ${CMAKE_MATCH_1})
                set(_val ${CMAKE_MATCH_2})
                if(DEFINED ${_var})
                    list(APPEND _pass_vars "-D${_var}=${_val}") # Use defined value
                endif()
            elseif(DEFINED ${_var})
                list(APPEND _pass_vars "-D${_var}=${${_var}}") # Use current value
            endif()
        endforeach()
        set(_ExtProject_PASS_CACHE_VARIABLES ${_pass_vars})
        unset(_pass_vars)
    endif()

    #Build shared libraries by default if neither SHARED or STATIC are set
    if(NOT _ExtProject_SHARED AND NOT _ExtProject_STATIC)
        set(_ExtProject_SHARED ON)
    endif()
    set(_ExtProject_FIND_PACKAGE_ARGS)
    if(NOT _ExtProject_VERSION)
        list(APPEND _ExtProject_FIND_PACKAGE_ARGS CONFIG)
    else()
        list(APPEND _ExtProject_FIND_PACKAGE_ARGS ${_ExtProject_VERSION} CONFIG)
    endif()
    if(_ExtProject_COMPONENTS)
        list(APPEND _ExtProject_FIND_PACKAGE_ARGS COMPONENTS ${_ExtProject_COMPONENTS})
    endif()
    find_package(${_ExtProject_NAME} ${_ExtProject_FIND_PACKAGE_ARGS})
    string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
    if(NOT ${_ExtProject_NAME}_FOUND OR (${_ExtProject_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_ExtProject_NAME}_BUILD_TYPES )))
        set(_ExtProject_Dir ${CMAKE_BINARY_DIR}/External/${_ExtProject_NAME})
        message(STATUS "[add_external_dependency] Not found: ${_ExtProject_NAME}")
        if(${_ExtProject_BUILD_TYPE_COMPATABILITY} STREQUAL Exact AND ${_ExtProject_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_ExtProject_NAME}_BUILD_TYPES))
            message(STATUS "[add_external_dependency] ${_ExtProject_NAME} Build types: {${${_ExtProject_NAME}_BUILD_TYPES}}; Does not provide current build type: ${BUILD_TYPE}.")
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
            find_file(_ExtProject_CMAKELISTS_TEMPLATE NAME External.CMakeLists.txt.in PATHS ${AddExternalDependency_include_path}/Templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
            mark_as_advanced(_ExtProject_CMAKELISTS_TEMPLATE)
            if(NOT _ExtProject_CMAKELISTS_TEMPLATE)
                message(FATAL_ERROR "[add_external_dependency] Could not locate template file External.CMakeLists.txt.in in path ${AddExternalDependency_include_path}/Templates")
            endif()
        endif()

        if(CMAKE_CROSSCOMPILING)
            set(_ExtProject_TOOLCHAIN_ARGS -DCMAKE_TOOLCHAIN_FILE=${_ExtProject_TOOLCHAIN_FILE})
        else()
            set(_ExtProject_TOOLCHAIN_ARGS)
        endif()
        configure_file(${_ExtProject_CMAKELISTS_TEMPLATE} ${_ExtProject_Dir}/CMakeLists.txt @ONLY)
        execute_process(COMMAND ${CMAKE_COMMAND} . WORKING_DIRECTORY ${_ExtProject_Dir})
        message(STATUS "[add_external_dependency] Downloading Building and Installing: ${_ExtProject_NAME}")
        execute_process(COMMAND ${CMAKE_COMMAND} --build . WORKING_DIRECTORY ${_ExtProject_Dir})

        find_package(${_ExtProject_NAME} ${_ExtProject_FIND_PACKAGE_ARGS} PATHS ${_ExtProject_INSTALL_PREFIX}/lib/cmake/${_ExtProject_NAME} NO_CMAKE_FIND_ROOT_PATH)

        if(NOT ${_ExtProject_NAME}_FOUND)
            message(FATAL_ERROR "[add_external_dependency] Install of ${_ExtProject_NAME} failed.")
        endif()
        message(STATUS "[add_external_dependency] Installed: ${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION} Location:${PACKAGE_PREFIX_DIR}")
    else()
        message(STATUS "[add_external_dependency] Found:${_ExtProject_NAME} Ver:${${_ExtProject_NAME}_VERSION} Location:${PACKAGE_PREFIX_DIR}")
    endif()

    message(STATUS "[add_external_dependency]: FIND_PACKAGE_CONSIDERED_CONFIGS: ${${_ExtProject_NAME}_CONSIDERED_CONFIGS}")
    message(STATUS "[add_external_dependency]: FIND_PACKAGE_CONSIDERED_VERSIONS: ${${_ExtProject_NAME}_CONSIDERED_VERSIONS}")

    if(${_ExtProject_NAME}_TARGETS)
        set(_ExtProject_Targets ${${_ExtProject_NAME}_TARGETS})
    elseif(TARGET ${_ExtProject_NAME}::${_ExtProject_NAME})
        set(_ExtProject_Targets ${_ExtProject_NAME}::${_ExtProject_NAME})
    elseif(${_ExtProject_NAME}_LIBRARIES)
        set(_ExtProject_Targets ${_ExtProject_NAME}_LIBRARIES)
    endif()

    message(STATUS "[add_external_dependency] Imported Targets: ${_ExtProject_Targets}")

    set(_ExtProject_Print_Properties TYPE IMPORTED_CONFIGURATIONS INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES INTERFACE_LINK_DIRECTORIES INTERFACE_COMPILE_FEATURES)
    set(_ExtProject_Config_Properties IMPORTED_LOCATION  IMPORTED_LINK_DEPENDENT_LIBRARIES IMPORTED_LINK_INTERFACE_LIBRARIES)
    set(_ExtProject_Config_Types RELEASE DEBUG RELWITHDEBINFO MINSIZEREL)
    foreach(prop IN LISTS _ExtProject_Config_Properties)
        foreach(type IN LISTS _ExtProject_Config_Types)
            list(APPEND _ExtProject_Print_Properties ${prop}_${type})
        endforeach()
    endforeach()
    foreach(target IN LISTS _ExtProject_Targets)
        foreach(prop IN LISTS _ExtProject_Print_Properties)
            get_target_property(v ${target} ${prop})
            if(v)
                message(STATUS "[add_external_dependency] [${target}] ${prop}: ${v}")
            endif()
        endforeach()
    endforeach()
endmacro()
