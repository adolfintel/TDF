#!/usr/bin/env bash
set -e
echo "Building vkgpltest"
rm -rf build
mkdir build
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
exit 0
