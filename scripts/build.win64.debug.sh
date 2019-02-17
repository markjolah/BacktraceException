#!/bin/bash
#
# scripts/build.win64.debug.sh <cmake-args...>
#
# Toolchain build for mingw-w64 arch using MXE (https://mxe.cc/)
#
# Required environment variables:
# MXE_ROOT=<mxe-root-dir>
#
# Optional environment variables:
# OPT_DOC=On - enable documentation build.
ARCH=win64
FULL_ARCH=x86_64-w64-mingw32
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..
TOOLCHAIN_FILE=${SRC_PATH}/cmake/UncommonCMakeModules/Toolchains/Toolchain-MXE-${FULL_ARCH}.cmake
INSTALL_PATH=${SRC_PATH}/_${ARCH}.install
BUILD_PATH=${SRC_PATH}/_${ARCH}.build/Debug
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`
if [ -z $OPT_DOC ]; then
    OPT_DOC="Off"
fi

ARGS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE"
ARGS="${ARGS} -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_DOC=${OPT_DOC}"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"
ARGS="${ARGS} -DOPT_FIXUP_DEPENDENCIES=On"
ARGS="${ARGS} -DOPT_FIXUP_DEPENDENCIES_BUILD_TREE=On"

set -ex
rm -rf $INSTALL_PATH $BUILD_PATH
cmake -H${SRC_PATH} -B$BUILD_PATH  -DCMAKE_BUILD_TYPE=Debug $ARGS $@
VERBOSE=1 cmake --build $BUILD_PATH --target all -- -j$NUM_PROCS
if [ "${OPT_DOC,,}" == "on" ] || [ $OPT_DOC -eq 1 ]; then
    VERBOSE=1 cmake --build $BUILD_PATH --target pdf -- -j$NUM_PROCS
fi
VERBOSE=1 cmake --build $BUILD_PATH --target install -- -j${NUM_PROCS}
