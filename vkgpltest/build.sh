#!/usr/bin/env bash
set -e
echo "Building vkgpltest"
mkdir build
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
exit 0
