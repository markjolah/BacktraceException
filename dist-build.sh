#!/bin/bash
# dist-build.sh <INSTALL_PREFIX>
# Release-only build for distribution.  Testing is enabled.
# Does not clear INSTALL_PATH for obvious reasons.
#
# Args:
#  <INSTALL_PREFIX> - path to distribution install directory [Default: _dist].
#                     Interpreted relative to current directory.
if [ -z $1 ]; then
    INSTALL_PATH=_dist
else
    INSTALL_PATH=$1
fi

BUILD_PATH=_build/dist
NUM_PROCS=$(grep -c ^processor /proc/cpuinfo)

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=Off"

set -ex
rm -rf $BUILD_PATH
cmake -H. -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Release ${ARGS}
cmake --build $BUILD_PATH --target install -- -j${NUM_PROCS}
