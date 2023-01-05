#!/bin/bash
echo "Building vkgpltest"
mkdir build
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
if [ $? -ne 0 ]; then exit 1; fi
exit 0
