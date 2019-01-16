# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 2014-2018
#
# Toolchain-MXE-x86_64-w64-mingw32.cmake
#
# This toolchain uses the MXE crossdev environment to build dependencies for 64-bit windows
# using the MXE (mxe.cc) cross-dev environment.  This toolchain used a fixup-dependencies
# phase that copies needed dependencies into the install path runtime folders.
#
# Can be used to build Matlab Mex files for Win64, using the MexIFace package http://github.com/markjolah/MexIFace
#
set(MXE_ROOT "$ENV{MXE_ROOT}")
#Note: Matlab uses posix threads and sjlj exceptions.
set(MXE_TARGET_ARCH x86_64-w64-mingw32.shared.posix.sjlj)
set(MXE_HOST_ARCH x86_64-unknown-linux-gnu)
set(MXE_ARCH_ROOT ${MXE_ROOT}/usr/${MXE_TARGET_ARCH})
set(MXE_BIN_DIR ${MXE_ROOT}/usr/bin)

set(CMAKE_SYSTEM_NAME Windows)

set(CMAKE_SYSTEM_PROGRAM_PATH ${MXE_BIN_DIR})
set(CMAKE_C_COMPILER ${MXE_TARGET_ARCH}-gcc)
set(CMAKE_CXX_COMPILER ${MXE_TARGET_ARCH}-g++)
set(CMAKE_RC_COMPILER ${MXE_TARGET_ARCH}-windres)

set(CMAKE_FIND_ROOT_PATH ${MXE_ROOT} ${MXE_ARCH_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

#Prevent usage of the package registry since we are crosscompiling
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY True)
set(CMAKE_EXPORT_NO_PACKAGE_REGISTRY True)

#Options to control FixupDependencies
option(OPT_FIXUP_DEPENDENCIES "Copy dependencies to install tree." ON)
option(OPT_FIXUP_BUILD_TREE_DEPENDENCIES "Enable export of the build tree." OFF)
option(OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES "Disable the auto hood on install() function for fixup_dependencies().  Must manually call fixup_dependencies()." OFF)

option(OPT_LINK_INSTALLED_LIBS "Create symbolic links to dependent DLLs that are within install_prefix already, as opposed to copying." OFF)

if(OPT_FIXUP_DEPENDENCIES)
    get_property(_install_hook_activated GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED)
    if(NOT _install_hook_activated)
        list(APPEND External_Dependency_PASS_CACHE_VARIABLES OPT_INSTALL_DEPENDENCIES OPT_FIXUP_BUILD_TREE_DEPENDENCIES=0
                                                OPT_LINK_INSTALLED_LIBS)
        SET(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")

        message(STATUS "mingw-w64 Toolchain option: OPT_INSTALL_DEPENDENCIES:${OPT_INSTALL_DEPENDENCIES}")
        message(STATUS "mingw-w64 Toolchain option: OPT_FIXUP_BUILD_TREE_DEPENDENCIES:${OPT_FIXUP_BUILD_TREE_DEPENDENCIES}")
        message(STATUS "mingw-w64 Toolchain option: OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES:${OPT_DISABLE_AUTO_FIXUP_DEPENDENCIES}")

        message(STATUS "mingw-w64 Toolchain option: OPT_LINK_INSTALLED_LIBS:${OPT_LINK_INSTALLED_LIBS}")

        #Find FixupDependencies.cmake, add to path, then cleanup any variables we changed
        find_path(_FixupDependencies_Path FixupDependencies.cmake PATHS "${CMAKE_CURRENT_LIST_DIR}/.." NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        if(NOT _FixupDependencies_Path)
            message(FATAL_ERROR "[Toolchain-x86_64-gcc4_9-linux-gnu]: Could not locate FixupDependencies.cmake.  Required to fixup directories locally.")
        endif()
        list(INSERT CMAKE_MODULE_PATH 0 ${_FixupDependencies_Path})
        include(FixupDependencies)
        message(STATUS "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")
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
                if(OPT_LINK_INSTALLED_LIBS)
                    list(APPEND _args LINK_INSTALLED_LIBS)
                endif()
                if(OPT_FIXUP_BUILD_TREE_DEPENDENCIES)
                    list(APPEND _args BUILD_TREE_EXPORT)
                endif()
                message(" Targets:${_targets} Args:${_args}")
                fixup_dependencies(TARGETS ${_targets} ${_args} COPY_DESTINATION "../bin")
            endif()
        endfunction()
        set_property(GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED True)
    endif()
    unset(_install_hook_activated)
endif()
