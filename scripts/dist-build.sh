#!/bin/bash
# dist-build.sh <INSTALL_PREFIX>
# Release-only build for distribution.  Testing is enabled.
# Does not clear INSTALL_PATH for obvious reasons.
#
# Args:
#  <INSTALL_PREFIX> - path to distribution install directory [Default: _dist].
#                     Interpreted relative to current directory.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..

if [ -z $1 ]; then
    INSTALL_DIR="${SRC_PATH}/_dist_intstall"
else
    INSTALL_DIR=$1
fi
VERSION=0.3
NAME=ParallelRngManager
INSTALL_DIR_NAME=${NAME}-${VERSION}
ZIP_FILE=${NAME}-${VERSION}.zip
TAR_FILE=${NAME}-${VERSION}.tbz2
INSTALL_PATH=${INSTALL_DIR}/$INSTALL_DIR_NAME


BUILD_PATH=${SRC_PATH}/_build/dist
NUM_PROCS=$(grep -c ^processor /proc/cpuinfo)

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_DOC=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=Off"

set -ex
rm -rf $BUILD_PATH
rm -rf $INSTALL_PATH
cmake -H${SRC_PATH} -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Release $ARGS
cmake --build $BUILD_PATH --target doc -- -j$NUM_PROCS
cmake --build $BUILD_PATH --target pdf -- -j$NUM_PROCS
cmake --build $BUILD_PATH --target install -- -j$NUM_PROCS

cd $INSTALL_DIR
zip -rq $ZIP_FILE $INSTALL_DIR_NAME
tar cjf $TAR_FILE $INSTALL_DIR_NAME
