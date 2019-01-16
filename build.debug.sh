#!/bin/bash
#
# build.debug.sh
#
INSTALL_PATH=_install
BUILD_PATH=_build
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"
rm -rf $INSTALL_PATH $BUILD_PATH

set -ex

cmake -H. -B$BUILD_PATH/Debug -DCMAKE_BUILD_TYPE=Debug -Wdev ${ARGS}
VERBOSE=1 cmake --build $BUILD_PATH/Debug --target install -- -j${NUM_PROCS}
