# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 2014-2018
#
# This toolchain uses the MXE crossdev environment
# set MXE_ROOT to the cross-dev-environment directory.
# 
#
set(MXE_ROOT "$ENV{MXE_ROOT}")
set(MXE_TARGET_ARCH x86_64-w64-mingw32.shared)
set(MXE_HOST_ARCH x86_64-unknown-linux-gnu)
set(MXE_ARCH_ROOT ${MXE_ROOT}/usr/${MXE_TARGET_ARCH})
set(MXE_BIN_DIR ${MXE_ROOT}/usr/bin)

message(STATUS "[MexIFace] MXE_ROOT: ${MXE_ROOT}")

#Search paths for dependent libraries to copy into install dir
set(FIXUP_LIB_SEARCH_PATHS "${MXE_ROOT}/usr/${MXE_TARGET_ARCH}/bin")

set(CMAKE_SYSTEM_NAME Windows)

set(CMAKE_SYSTEM_PROGRAM_PATH ${MXE_BIN_DIR})
set(CMAKE_C_COMPILER ${MXE_TARGET_ARCH}-gcc)
set(CMAKE_CXX_COMPILER ${MXE_TARGET_ARCH}-g++)
set(CMAKE_RC_COMPILER ${MXE_TARGET_ARCH}-windres)
# set(CMAKE_PREFIX_PATH ${MXE_ROOT} ${MXE_ROOT}/usr/${MXE_HOST_ARCH})
set(CMAKE_FIND_ROOT_PATH ${MXE_ROOT} ${MXE_ARCH_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

