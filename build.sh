#!/bin/bash
# build.sh <cmake-args...>
#
# Release only build to local install prefix with build-tree export and testing.
#
# For safety only delete the _install if and only if INSTALL_PATH hasn't been modified.

INSTALL_PATH=_install
BUILD_PATH=_build
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"

set -ex

if [ "$INSTALL_PATH" == "_install" ]; then
    rm -rf _install
fi
rm -rf $BUILD_PATH/Release
cmake -H. -B$BUILD_PATH/Release -DCMAKE_BUILD_TYPE=Release ${ARGS} $@
cmake --build $BUILD_PATH/Release --target install -- -j${NUM_PROCS}
