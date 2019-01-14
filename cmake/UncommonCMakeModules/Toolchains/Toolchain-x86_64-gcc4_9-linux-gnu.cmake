# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 01-2018
#
# Toolchain-x86_64-gcc4_9-linux-gnu.cmake
#
# Toolchain for cross-compiling to a linux matlab9_1 (and later)
# environment using gcc-4.9.4.
#

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_CXX_COMPILER g++-4.9.4)

set(CMAKE_FIND_ROOT_PATH $ENV{X86_64_GCC4_9_LINUX_GNU_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

#Prevent usage of the package registry since we are crosscompiling
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY True)
set(CMAKE_EXPORT_NO_PACKAGE_REGISTRY True)

#Rpath management
SET(CMAKE_SKIP_BUILD_RPATH FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

#Options to control FixupDependencies
option(OPT_INSTALL_DEPENDENCIES "Copy dependencies to install tree." ON)
option(OPT_INSTALL_SYSTEM_DEPENDENCIES "Copy system dependencies to install tree." OFF)
option(OPT_BUILD_TREE_EXPORT "Enable export of the build tree." ON)

if(OPT_INSTALL_DEPENDENCIES)
    SET(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")
    if(OPT_INSTALL_SYSTEM_DEPENDENCIES)
        #Force setting RPATH instead of RUNPATH
        #This is an agressive move to prevent any use of system libraries and is only enabled if
        #system libraries will be installed.
        set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--disable-new-dtags")
    endif()

    #Find FixupDependencies.cmake, add to path, then cleanup any variables we changed
    find_path(_FixupDependencies_Path FixupDependencies.cmake PATHS "${CMAKE_CURRENT_LIST_DIR}/.." NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
    if(NOT _FixupDependencies_Path)
        message(FATAL_ERROR "[Toolchain-x86_64-gcc4_9-linux-gnu]: Could not locate FixupDependencies.cmake.  Required to fixup directories locally.")
    endif()
    list(INSERT CMAKE_MODULE_PATH 0 ${_FixupDependencies_Path})
    include(FixupDependencies)
    list(REMOVE_AT CMAKE_MODULE_PATH 0)
    unset(_FixupDependencies_Path)
    unset(_FixupDependencies_Path CACHE)

    #intercept install(TARGETS) commands and run fixup_dependencies on the targets
    function(install type name)
        _install(${type} ${name} ${ARGN})
        if(type STREQUAL TARGETS)
            #Get all targets
            math(_N "${ARGC} - 1")
            set(_targets)
            foreach(idx IN RANGE 2 ${_N})
                if(TARGET ${ARG${idx}})
                    list(APPEND _targets ${ARG${idx}})
                else()
                    break()
                endif()
            endforeach()
            set(_args)
            if(OPT_INSTALL_SYSTEM_DEPENDENCIES)
                list(APPEND _args COPY_SYSTEM_LIBS)
            endif()
            if(OPT_BUILD_TREE_EXPORT)
                list(APPEND _args BUILD_TREE_EXPORT)
            endif()
            fixup_dependencies(TARGETS ${_targets} ${_args})
        endif()
    endfunction()
endif()
