#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building vkgpltest"
rm -rf build
mkdir build
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
echo 4 > state
exit 0
