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
option(OPT_INSTALL_DEPENDENCIES "Copy dependencies to install tree." ON)
option(OPT_LINK_INSTALLED_LIBS "Create symbolic links to dependent DLLs that are within install_prefix already, as opposed to copying." ON)
option(OPT_BUILD_TREE_EXPORT "Enable export of the build tree." ON)

if(OPT_INSTALL_DEPENDENCIES)
    include(FixupDependencies)
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
            if(OPT_LINK_INSTALLED_LIBS)
                list(APPEND _args LINK_INSTALLED_LIBS)
            endif()
            if(OPT_BUILD_TREE_EXPORT)
                list(APPEND _args BUILD_TREE_EXPORT)
            endif()
            fixup_dependencies(TARGETS ${_targets} ${_args})
        endif()
    endfunction()
endif()
