#!/bin/bash

INSTALL_PATH=_install
BUILD_PATH=_build
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`
COMMON_ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON"
rm -rf $INSTALL_PATH $BUILD_PATH

set -e

cmake -H. -B$BUILD_PATH/Debug -DCMAKE_BUILD_TYPE=Debug ${COMMON_ARGS}
cmake -H. -B$BUILD_PATH/Release -DCMAKE_BUILD_TYPE=Release ${COMMON_ARGS}
cmake --build $BUILD_PATH/Debug --target install -- -j${NUM_PROCS}
cmake --build $BUILD_PATH/Release --target install -- -j${NUM_PROCS}
