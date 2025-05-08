#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building libstrangle (master)"
rm -rf build
mkdir build
cd libstrangle
make
mv build/libstrangle64.so ../build/
mv build/libstrangle32.so ../build/
cd ..
echo 4 > state
exit 0
