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
set(CMAKE_SYSROOT $ENV{X86_64_GCC4_9_LINUX_GNU_ROOT}) #This sets --sysroot= on linking

set(CMAKE_PREFIX_PATH $ENV{X86_64_GCC4_9_LINUX_GNU_ROOT}) #This root for pkg-config in FindPkgConfig
set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH On)
# set(ENV{PKG_CONFIG_LIBDIR} ${CMAKE_SYSROOT}/lib/pkgconfig:${CMAKE_SYSROOT}/share/pkgconfig) #tell pkg-config to replace root with sysroot
# set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT}) #tell pkg-config to replace root with sysroot
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

## Fixup Dependencies ##
#Options to control FixupDependencies
option(OPT_FIXUP_DEPENDENCIES "Copy dependencies to install tree." ON)
option(OPT_FIXUP_DEPENDENCIES_AUTO "Enable the auto hook on install() function for fixup_dependencies(). Disable to manually call fixup_dependencies()." ON)
option(OPT_FIXUP_DEPENDENCIES_BUILD_TREE "Fixup dependencies for targets in the build tree." OFF)
option(OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS "Copy gcc provided dependencies to install tree and set RPATH for all libraries and executables." OFF)
option(OPT_FIXUP_DEPENDENCIES_COPY_GLIBC_LIBS "[Warning: not recommended] Copy glibc provided dependencies to install tree and set RPATH for all libraries and executables." OFF)
option(OPT_FIXUP_SET_RPATH "Set RPATH on installed libraries and binaries. This supersedes LD_LIBRARY_PATH and rpaths are searched recursively in dependency hierarchy" ON)
option(OPT_FIXUP_SET_RUNPATH "Set RUNPATH on installed libraries and binaries." OFF)
set(INSTALL_RUNTIME_PATH "\$ORIGIN/../lib" CACHE STRING "Runtime path used for installed libraries and executables.")
set(BUILD_RUNTIME_PATH "\$ORIGIN" CACHE STRING "Build tree path used for installed libraries and executables.")

if(OPT_FIXUP_DEPENDENCIES)
    #Check options logical restrictions
    if(OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS)
        if(OPT_FIXUP_SET_RUNPATH)
            message(STATUS "OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS is set.  OPT_FIXUP_SET_RUNPATH is not compatible.  Forcing OPT_FIXUP_SET_RUNPATH OFF.")
            set(OPT_FIXUP_SET_RUNPATH OFF)
            set(OPT_FIXUP_SET_RUNPATH OFF CACHE BOOL "Set RUNPATH on installed libraries and binaries." FORCE)
        endif()
        if(NOT OPT_FIXUP_SET_RPATH)
            message(STATUS "OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS is set.  OPT_FIXUP_SET_RPATH must also be set.  Forcing OPT_FIXUP_SET_RPATH On.")
            set(OPT_FIXUP_SET_RPATH ON)
            set(OPT_FIXUP_SET_RPATH ON CACHE BOOL "Set RPATH on installed libraries and binaries. This supersedes LD_LIBRARY_PATH and rpaths are searched recursively in dependency hierarchy" FORCE)
        endif()
    elseif(NOT OPT_FIXUP_SET_RPATH AND NOT OPT_FIXUP_SET_RUNPATH)
        message(STATUS "Neither OPT_RUNPATH or OPT_RPATH is set.  Must have at least one when cross-compiling.  Setting OPT_RUNPATH.")
        set(OPT_FIXUP_SET_RUNPATH ON)
        set(OPT_FIXUP_SET_RUNPATH ON CACHE BOOL "Set RUNPATH on installed libraries and binaries." FORCE)
    endif()

    get_property(_install_hook_activated GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED)
    if(NOT _install_hook_activated)
        if(OPT_FIXUP_SET_RPATH OR OPT_FIXUP_SET_RUNPATH)
            SET(CMAKE_INSTALL_RPATH "${INSTALL_RUNTIME_PATH}")
        endif()
        if(OPT_FIXUP_DEPENDENCIES_BUILD_TREE)
            SET(CMAKE_BUILD_RPATH "${BUILD_RUNTIME_PATH}")
        endif()
        if(OPT_FIXUP_SET_RPATH)
            set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--disable-new-dtags")
        elseif(OPT_FIXUP_SET_RUNPATH)
            set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--enable-new-dtags")
        endif()

        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_DEPENDENCIES:${OPT_FIXUP_DEPENDENCIES}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_DEPENDENCIES_AUTO:${OPT_FIXUP_DEPENDENCIES_AUTO}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_DEPENDENCIES_BUILD_TREE:${OPT_FIXUP_DEPENDENCIES_BUILD_TREE}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS:${OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_DEPENDENCIES_COPY_GLIBC_LIBS:${OPT_FIXUP_DEPENDENCIES_COPY_GLIBC_LIBS}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_SET_RPATH:${OPT_FIXUP_SET_RPATH}")
        message(STATUS "gcc4_9 Toolchain option: OPT_FIXUP_SET_RUNPATH:${OPT_FIXUP_SET_RUNPATH}")


        if(OPT_FIXUP_DEPENDENCIES_AUTO)
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
                if(OPT_FIXUP_DEPENDENCIES_AUTO AND type STREQUAL TARGETS) #Need to check for OPT_FIXUP_DEPENDENCIES_AUTO again incase it is disabled in main CMakeLists.txt after this Toolchain is processed
                    #Get all targets
                    math(EXPR _N "${ARGC} - 1")
                    set(_targets)
                    set(_destinations)
                    set(_found_targets)
                    set(_found_destination)
                    foreach(idx RANGE 1 ${_N})
                        if(NOT _found_targets AND TARGET ${ARGV${idx}})
                            list(APPEND _targets ${ARGV${idx}})
                        elseif(_found_destination)
                            set(_found_destination)
                            list(APPEND _destinations ${ARGV${idx}})
                        elseif(${ARGV${idx}} STREQUAL DESTINATION)
                            set(_found_destination 1)
                        endif()
                    endforeach()
                    set(_args)
                    if(OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS)
                        list(APPEND _args COPY_GCC_LIBS)
                    endif()
                    if(OPT_FIXUP_DEPENDENCIES_COPY_GLIBC_LIBS)
                        list(APPEND _args COPY_GLIBC_LIBS)
                    endif()
                    if(OPT_FIXUP_DEPENDENCIES_BUILD_TREE)
                        list(APPEND _args EXPORT_BUILD_TREE On)
                    endif()
                    fixup_dependencies(TARGETS ${_targets} ${_args} TARGET_DESTINATIONS ${_destinations})
                endif()
            endfunction()
        endif(OPT_FIXUP_DEPENDENCIES_AUTO)
        set_property(GLOBAL PROPERTY _FIXUP_DEPENDENCY_INSTALL_HOOK_ACTIVATED True)
    endif()
    unset(_install_hook_activated)
endif()
