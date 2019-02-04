#!/bin/bash
# build.sh
#
# Simple release build

INSTALL_PATH=_install
BUILD_PATH=_build
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=Off"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=Off"

set -ex
rm -rf $INSTALL_PATH $BUILD_PATH/Debug $BUILD_PATH/Release
cmake -H. -B$BUILD_PATH/Debug -DCMAKE_BUILD_TYPE=Debug -Wdev ${ARGS}
cmake --build $BUILD_PATH/Debug --target install -- -j${NUM_PROCS}
cmake -H. -B$BUILD_PATH/Release -DCMAKE_BUILD_TYPE=Release ${ARGS}
cmake --build $BUILD_PATH/Release --target install -- -j${NUM_PROCS}
