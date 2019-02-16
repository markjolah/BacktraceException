#!/bin/bash
# scripts/doc-build.sh <cmake args ...>
# Build documentation into the build tree
# Works with Travis CI.

NUM_PROCS=`grep -c ^processor /proc/cpuinfo`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..
BUILD_PATH=${SCRIPT_DIR}/../_build/documentation
INSTALL_PATH=${SCRIPT_DIR}/../_install.documentation
ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DOPT_DOC=On"

set -ex
rm -rf $BUILD_PATH

cmake -H${SRC_PATH} -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Debug -Wdev $ARGS $@
VERBOSE=1 cmake --build $BUILD_PATH --target doc -- -j$NUM_PROCS
