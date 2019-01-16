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
option(OPT_INSTALL_DEPENDENCIES "Copy dependencies to install tree." OFF)
option(OPT_FIXUP_BUILD_TREE_DEPENDENCIES "Enable export of the build tree." OFF)
option(OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES "Disable the auto hood on install() function for fixup_dependencies().  Must manually call fixup_dependencies()." OFF)

option(OPT_INSTALL_GCC_DEPENDENCIES "Copy gcc provided dependencies to install tree and set RPATH for all libraries and executables." OFF)
option(OPT_SET_RPATH "Set RPATH on installed libraries and binaries. This supersedes LD_LIBRARY_PATH and rpaths are searched recursively in dependency hierarchy" OFF)
option(OPT_SET_RUNPATH "Set RUNPATH on installed libraries and binaries." OFF)
set(INSTALL_RUNTIME_PATH "\$ORIGIN/../lib" CACHE STRING "Runtime path used for installed libraries and executables.")
set(BUILD_RUNTIME_PATH "\$ORIGIN" CACHE STRING "Build tree path used for installed libraries and executables.")


if(OPT_INSTALL_DEPENDENCIES)
    #Check options logical restrictions
    if(OPT_INSTALL_GCC_DEPENDENCIES)
        if(OPT_SET_RUNPATH)
            message(STATUS "OPT_INSTALL_GCC_DEPENDENCIES is set.  OPT_SET_RUNPATH is not compatible.  Forcing OPT_SET_RUNPATH OFF.")
            set(OPT_SET_RUNPATH OFF)
            set(OPT_SET_RUNPATH OFF CACHE BOOL "Set RUNPATH on installed libraries and binaries." FORCE)
        endif()
        if(NOT OPT_SET_RPATH)
            message(STATUS "OPT_INSTALL_GCC_DEPENDENCIES is set.  OPT_SET_RPATH must also be set.  Forcing OPT_SET_RPATH On.")
            set(OPT_SET_RPATH ON)
            set(OPT_SET_RPATH ON CACHE BOOL "Set RPATH on installed libraries and binaries. This supersedes LD_LIBRARY_PATH and rpaths are searched recursively in dependency hierarchy" FORCE)
        endif()
    endif()
    get_property(_install_hook_activated GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED)
    if(NOT _install_hook_activated)
        if(OPT_SET_RPATH OR OPT_SET_RUNPATH)
            SET(CMAKE_INSTALL_RPATH "${INSTALL_RUNTIME_PATH}")
        endif()
        if(OPT_FIXUP_BUILD_TREE_DEPENDENCIES)
            SET(CMAKE_BUILD_RPATH "${BUILD_RUNTIME_PATH}")
        endif()
        if(OPT_SET_RPATH)
            set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--disable-new-dtags")
        elseif(OPT_SET_RUNPATH)
            set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--enable-new-dtags")
        endif()

        message(STATUS "gcc4_9 Toolchain option: OPT_INSTALL_DEPENDENCIES:${OPT_INSTALL_DEPENDENCIES}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_BUILD_TREE_DEPENDENCIES:${OPT_FIXUP_BUILD_TREE_DEPENDENCIES}")
        message(STATUS "gcc4_9 Toolchain option: OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES:${OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES}")

        message(STATUS "gcc4_9 Toolchain option: OPT_INSTALL_GCC_DEPENDENCIES:${OPT_INSTALL_GCC_DEPENDENCIES}")
        message(STATUS "gcc4_9 Toolchain option: OPT_SET_RPATH:${OPT_SET_RPATH}")
        message(STATUS "gcc4_9 Toolchain option: OPT_SET_RUNPATH:${OPT_SET_RUNPATH}")

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
        function(install type)
            _install(${type} ${name} ${ARGN})
            if(NOT OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES AND type STREQUAL TARGETS)
                #Get all targets
                math(EXPR _N "${ARGC} - 1")
                set(_targets)
                foreach(idx RANGE 1 ${_N})
                    if(TARGET ${ARGV${idx}})
                        list(APPEND _targets ${ARGV${idx}})
                    else()
                        break()
                    endif()
                endforeach()
                set(_args)
                if(OPT_INSTALL_GCC_DEPENDENCIES)
                    list(APPEND _args COPY_GCC_LIBS)
                endif()
                if(OPT_FIXUP_BUILD_TREE_DEPENDENCIES)
                    list(APPEND _args BUILD_TREE_EXPORT)
                endif()
                fixup_dependencies(TARGETS ${_targets} ${_args} COPY_DESTINATION "../lib")
            endif()
        endfunction()
        set_property(GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED True)
    endif()
    unset(_install_hook_activated)
endif()
