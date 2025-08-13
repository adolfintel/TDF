#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building reaper (master)"
rm -rf build
mkdir build
cd reaper
rm -rf build
meson build
cd build
ninja all
mv reaper ../../build/
cd ..
rm -rf build
cd ..
echo 4 > state
exit 0
