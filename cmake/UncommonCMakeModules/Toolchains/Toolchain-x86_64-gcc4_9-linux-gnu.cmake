# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 01-2018
#
# Toolchain-x86_64-gcc4_9-linux-gnu.cmake
#
# Toolchain for cross-compiling to a linux matlab9_3 (and earlier)
# environment using gcc-4.9.4.
#

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_CXX_COMPILER g++-4.9.4)
set(CMAKE_FIND_ROOT_PATH $ENV{X86_64_GCC4_9_LINUX_GNU_ROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY True)
set(CMAKE_EXPORT_NO_PACKAGE_REGISTRY True)

#Rpath management
option(OPT_INSTALL_DEPENDENCIES "Copy dependencies to install tree." ON)
option(OPT_INSTALL_SYSTEM_DEPENDENCIES "Copy system dependencies to install tree." OFF)

SET(CMAKE_SKIP_BUILD_RPATH FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

if(OPT_INSTALL_DEPENDENCIES)
    SET(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")
    if(OPT_INSTALL_SYSTEM_DEPENDENCIES)
        #Force setting RPATH instead of RUNPATH
        #This is an agressive move to prevent any use of system libraries and is only enabled if
        #system libraries will be installed.
        set_property(DIRECTORY APPEND PROPERTY LINK_OPTIONS "-Wl,--disable-new-dtags")
    endif()
endif()
