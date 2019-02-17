#!/bin/bash
# scripts/dist-build.sh <INSTALL_DIR> <cmake-args...>
#
# Builds a re-distributable release-only build for C++ libraries.
# Testing and documentation are enabled.
# Creates a .zip and .tar.gz archives.
#
# Args:
#  <INSTALL_DIR> - path to distribution install directory [Default: ${SRC_PATH}/_dist].
#                  The distribution files will be created under this directory with names based on
#                  package and versions.
#  <cmake_args...> - additional cmake arguments.
#
# Optional environment variables:

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..

NAME=$(grep -Po "project\(\K([A-Za-z]+)" ${SRC_PATH}/CMakeLists.txt)
VERSION=$(grep -Po "project\([A-Za-z]+ VERSION \K([0-9.]+)" ${SRC_PATH}/CMakeLists.txt)
if [ -z $NAME ] || [ -z $VERSION ]; then
    echo "Unable to find package name and version from: ${SRC_PATH}/CMakeLists.txt"
    exit 1
fi
DIST_DIR_NAME=${NAME}-${VERSION}
if [ -z $1 ]; then
    INSTALL_PATH=${SRC_PATH}/_dist/$DIST_DIR_NAME
else
    INSTALL_PATH=$1/$DIST_DIR_NAME
fi

ZIP_FILE=${NAME}-${VERSION}.zip
TAR_FILE=${NAME}-${VERSION}.tbz2

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

cmake -H${SRC_PATH} -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Release $ARGS ${@:2}
cmake --build $BUILD_PATH --target doc -- -j$NUM_PROCS
cmake --build $BUILD_PATH --target pdf -- -j$NUM_PROCS
cmake --build $BUILD_PATH --target install -- -j$NUM_PROCS

cd $INSTALL_PATH/..
zip -rq $ZIP_FILE $DIST_DIR_NAME
tar cjf $TAR_FILE $DIST_DIR_NAME
