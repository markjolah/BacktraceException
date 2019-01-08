# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# Change MXE_ROOT to the cross-dev-environment directory.
# 
# We need to use shared libraries because a matlab mex module is a shared library.
# we can use static libraries if the files are compiled with -fPIC.  Thus we
# are using the MXE shared target
#
set(MXE_ROOT $ENV{MEXIFACE_MXE_ROOT})
set(MXE_TARGET_ARCH x86_64-w64-mingw32.shared)
set(MXE_HOST_ARCH x86_64-unknown-linux-gnu)
set(MXE_ARCH_ROOT ${MXE_ROOT}/usr/${MXE_TARGET_ARCH})
set(MXE_BIN_DIR ${MXE_ROOT}/usr/bin)

message(STATUS "[MexIFace] MXE_ROOT: ${MXE_ROOT}")
#Look here for libraries at install time
# set(LIB_SEARCH_PAT-HS "${MXE_ROOT}/usr/${TARGET_MXE_ARCH}/lib"
#                      "${MXE_ROOT}/usr/${TARGET_MXE_ARCH}/bin"
#                      "${MXE_ROOT}/usr/bin"
#                      "${MXE_ROOT}/usr/lib"
#                      "${MXE_ROOT}/usr/lib/gcc/x86_64-w64-mingw32.shared/4.9.4/"
#                      "${USER_W64_CROSS_ROOT}/lib")

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

