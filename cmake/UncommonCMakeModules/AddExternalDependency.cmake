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
#   DISABLE_TESTING - Attempt to build testing functionality. [default=OFF]
# Single-Value arguments:
#   NAME - [required] Name of PROJECT_NAME of the external cmake project
#   URL - URL of git repository or local path to git repository (can be overwritten with ${PROJECT_NAME}URL environment variable giving alternate URL
#   GIT_TAG - git tag to use
#   VERSION - [optional] Version number of dependency required. Leave empty for any version with appropriate BUILD_TYPE_COMPATABILITY
#   INSTALL_PREFIX - [optional] install location for package [defaults to CMAKE_INSTALL_PREFIX]
#   CMAKELISTS_TEMPLATE - [optional] Template file for the CMakeLists.txt to the building and installing via ExternalProject_Add [default: Templates/External.CMakeLists.txt.in]
#   BUILD_TYPE_COMPATABILITY - [optional] Default: Exact  Options: Exact, Any
#   TOOLCHAIN_FILE - [optional] [Only used if CMAKE_CROSSCOMPILING is true.  Uses CMAKE_TOOLCHAIN_FILE as the default.]
#Multi-arguments
#  VARS - [optional] List of cache variables to pass-through
#  COMPONENTS - [optional] List of required components for find_package
#
# CMAKE options respected.  (These can be enabled from the command line
# - OPT_AddExternalDependency_VERBOSE - Enable verbose output
# - OPT_AddExternalDependency_DISABLE_TESTING - Disable recursive BUILD_TESTING.
#
set(AddExternalDependency_include_path ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "Path of AddExternalDependency.cmake")

macro(add_external_dependency)
    set(options SHARED STATIC TESTING)
    set(oneArgOpts NAME URL GIT_TAG VERSION INSTALL_PREFIX CMAKELISTS_TEMPLATE BUILD_TYPE_COMPATABILITY TOOLCHAIN_FILE)
    set(multiArgOpts VARS COMPONENTS)
    cmake_parse_arguments(_EXT "${options}" "${oneArgOpts}" "${multiArgOpts}" ${ARGN})
    if(NOT _EXT_NAME)
        message(FATAL_ERROR "No package name given")
    endif()
    if(_EXT_UNPARSED_ARGUMENTS)
        message(WARNING "[add_external_dependency] UNPARSED ARGUMENTS:${_EXT_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT _EXT_INSTALL_PREFIX)
        set(_EXT_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
    endif()

    #override _EXT_URL passed in with environment variable
    set(_EXT_URL_ENV $ENV{${_EXT_NAME}URL})
    if(_EXT_URL_ENV)
        set(_EXT_URL $ENV{${_EXT_NAME}URL})
    endif()

    if(NOT _EXT_GIT_TAG)
        set(_EXT_GIT_TAG master)
    endif()

    if(NOT _EXT_BUILD_TYPE_COMPATABILITY)
        set(_EXT_BUILD_TYPE_COMPATABILITY Exact)
    endif()

    if(CMAKE_CROSSCOMPILING AND NOT _EXT_TOOLCHAIN_FILE)
        set(_EXT_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
    endif()

    #PASS_CACHE_VARIABLES is a list of CMake variables to pass on command line.
    # Fornat is <Var> or <Var>=<val>.  If no <val> is specified, the current value of that CMake variable
    # is passed.
    set(_EXT_CMAKE_VARS BUILD_STATIC_LIBS BUILD_SHARED_LIBS)
    if(_EXT_VARS)
        list(APPEND _EXT_CMAKE_VARS ${_EXT_VARS})
    endif()
    list(APPEND _EXT_CMAKE_VARS CMAKE_INSTALL_PREFIX)
    list(APPEND _EXT_CMAKE_VARS CMAKE_CXX_COMPILER CMAKE_C_COMPILER CMAKE_Fortran_COMPILER)

    if(OPT_AddExternalDependency_DISABLE_TESTING)
        list(APPEND _EXT_CMAKE_VARS BUILD_TESTING=Off) #Disable recursive testing if OPT_AddExternalDependency_DISABLE_TESTING
    else()
        list(APPEND _EXT_CMAKE_VARS BUILD_TESTING)
    endif()
    list(APPEND _EXT_CMAKE_VARS CMAKE_EXPORT_NO_PACKAGE_REGISTRY=On)

    #Fixup each passed cache variable accepts Names and Name=val
    if(_EXT_CMAKE_VARS)
        set(_pass_vars)
        foreach(_var IN LISTS _EXT_CMAKE_VARS)
            if(${_var} MATCHES "([A-Za-z0-9_]+)=([A-Za-z0-9_/+-]+)")
                set(_var ${CMAKE_MATCH_1})
                set(_val ${CMAKE_MATCH_2})
                if(DEFINED ${_var})
                    list(APPEND _pass_vars "-D${_var}=${_val}") # Use defined value
                endif()
            elseif(DEFINED ${_var})
                list(APPEND _pass_vars "-D${_var}=${${_var}}") # Use current value
            endif()
        endforeach()
        set(_EXT_CMAKE_VARS ${_pass_vars})
        unset(_pass_vars)
    endif()

    set(_EXT_FIND_PACKAGE_ARGS)
    if(NOT _EXT_VERSION)
        list(APPEND _EXT_FIND_PACKAGE_ARGS CONFIG)
    else()
        list(APPEND _EXT_FIND_PACKAGE_ARGS ${_EXT_VERSION} CONFIG)
    endif()
    if(_EXT_COMPONENTS)
        list(APPEND _EXT_FIND_PACKAGE_ARGS COMPONENTS ${_EXT_COMPONENTS})
    endif()

    find_package(${_EXT_NAME} ${_EXT_FIND_PACKAGE_ARGS} CMAKE_FIND_ROOT_PATH_BOTH)

    string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
    if( (NOT ${_EXT_NAME}_FOUND) OR
        (${_EXT_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_EXT_NAME}_BUILD_TYPES)) )
        set(_EXT_Dir ${CMAKE_BINARY_DIR}/External/${_EXT_NAME})
        message(STATUS "[add_external_dependency] Not found: ${_EXT_NAME}")
        if(${_EXT_BUILD_TYPE_COMPATABILITY} STREQUAL Exact AND ${_EXT_NAME}_BUILD_TYPES AND (NOT ${BUILD_TYPE} IN_LIST ${_EXT_NAME}_BUILD_TYPES))
            message(STATUS "[add_external_dependency] ${_EXT_NAME} Build types: {${${_EXT_NAME}_BUILD_TYPES}}; Does not provide current build type: ${BUILD_TYPE}.")
        endif()
        if(NOT _EXT_INSTALL_PREFIX)
            message(FATAL_ERROR "[add_external_dependency]  CMAKE_INSTALL_PREFIX is not set and INSTALL_PREFIX argument is not set."
                                "  Cannot use AddExternalDependency to autoinstall ${_EXT_NAME}"
                                "   Recommend: (1) Set CMAKE_INSTALL_PREFIX to a valid directory.  This can be a local directory if this package is to be exported"
                                "                  directly from the build tree."
                                "              (2) Install dependency ${_EXT_NAME} from URL: ${_EXT_URL} to a user or system location cmake can find.")
        endif()
        if(NOT _EXT_URL)
            message(FATAL_ERROR "[add_external_autotools_dependency] No URL provided.")
        endif()
        message(STATUS "[add_external_dependency] Initializing as ExternalProject URL:${_EXT_URL}")
        message(STATUS "[add_external_dependency] ExtProjectBuildTypes:${${_EXT_NAME}_BUILD_TYPES}")
        
        if(NOT _EXT_CMAKELISTS_TEMPLATE)
            find_file(_EXT_CMAKELISTS_TEMPLATE NAME External.CMakeLists.txt.in PATHS ${AddExternalDependency_include_path}/Templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
            mark_as_advanced(_EXT_CMAKELISTS_TEMPLATE)
            if(NOT _EXT_CMAKELISTS_TEMPLATE)
                message(FATAL_ERROR "[add_external_dependency] Could not locate template file External.CMakeLists.txt.in in path ${AddExternalDependency_include_path}/Templates")
            endif()
        endif()

        if(CMAKE_CROSSCOMPILING)
            set(_EXT_TOOLCHAIN_ARGS -DCMAKE_TOOLCHAIN_FILE=${_EXT_TOOLCHAIN_FILE})
        else()
            set(_EXT_TOOLCHAIN_ARGS)
        endif()
        if(OPT_AddExternalDependency_VERBOSE)
            message(STATUS "[add_external_dependency] CMAKE_ARGS:${_EXT_CMAKE_VARS}")
        endif()
        configure_file(${_EXT_CMAKELISTS_TEMPLATE} ${_EXT_Dir}/CMakeLists.txt @ONLY)
        execute_process(COMMAND ${CMAKE_COMMAND} . WORKING_DIRECTORY ${_EXT_Dir})
        message(STATUS "[add_external_dependency] Downloading Building and Installing: ${_EXT_NAME}")
        execute_process(COMMAND ${CMAKE_COMMAND} --build . WORKING_DIRECTORY ${_EXT_Dir})

        find_package(${_EXT_NAME} ${_EXT_FIND_PACKAGE_ARGS} PATHS ${_EXT_INSTALL_PREFIX}/lib/cmake/${_EXT_NAME} NO_CMAKE_FIND_ROOT_PATH)

        if(NOT ${_EXT_NAME}_FOUND)
            message(FATAL_ERROR "[add_external_dependency] Install of ${_EXT_NAME} failed.")
        endif()
        message(STATUS "[add_external_dependency] Installed: ${_EXT_NAME} Ver:${${_EXT_NAME}_VERSION} Location:${PACKAGE_PREFIX_DIR}")
    else()
        message(STATUS "[add_external_dependency] Found:${_EXT_NAME} Ver:${${_EXT_NAME}_VERSION} Location:${PACKAGE_PREFIX_DIR}")
    endif()

    if(OPT_AddExternalDependency_VERBOSE)
        #Debugging
        message(STATUS "[add_external_dependency] FIND_PACKAGE_CONSIDERED_CONFIGS: ${${_EXT_NAME}_CONSIDERED_CONFIGS}")
        message(STATUS "[add_external_dependency] FIND_PACKAGE_CONSIDERED_VERSIONS: ${${_EXT_NAME}_CONSIDERED_VERSIONS}")

        if(${_EXT_NAME}_TARGETS)
            set(_EXT_Targets ${${_EXT_NAME}_TARGETS})
        elseif(TARGET ${_EXT_NAME}::${_EXT_NAME})
            set(_EXT_Targets ${_EXT_NAME}::${_EXT_NAME})
        elseif(${_EXT_NAME}_LIBRARIES)
            set(_EXT_Targets ${_EXT_NAME}_LIBRARIES)
        endif()

        message(STATUS "[add_external_dependency] Imported Targets: ${_EXT_Targets}")

        set(_EXT_Print_Properties TYPE IMPORTED_CONFIGURATIONS INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES INTERFACE_LINK_DIRECTORIES INTERFACE_COMPILE_FEATURES)
        set(_EXT_Config_Properties IMPORTED_LOCATION  IMPORTED_LINK_DEPENDENT_LIBRARIES IMPORTED_LINK_INTERFACE_LIBRARIES)
        set(_EXT_Config_Types RELEASE DEBUG RELWITHDEBINFO MINSIZEREL)
        foreach(prop IN LISTS _EXT_Config_Properties)
            foreach(type IN LISTS _EXT_Config_Types)
                list(APPEND _EXT_Print_Properties ${prop}_${type})
            endforeach()
        endforeach()
        foreach(target IN LISTS _EXT_Targets)
            foreach(prop IN LISTS _EXT_Print_Properties)
                get_target_property(v ${target} ${prop})
                if(v)
                    message(STATUS "[add_external_dependency] [${target}] ${prop}: ${v}")
                endif()
            endforeach()
        endforeach()
    endif()
endmacro()
