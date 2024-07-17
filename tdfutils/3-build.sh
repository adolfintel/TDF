#!/usr/bin/env bash
set -e
echo 3 > state
rm -rf build
mkdir build
echo "Building futex2test"
gcc -static -o build/futex2test futex2test.c
echo "Building vkgpltest"
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
echo "Building Wine smoke test"
i686-w64-mingw32-gcc -static -o build/smoke32.exe winesmoketest.c
x86_64-w64-mingw32-gcc -static -o build/smoke64.exe winesmoketest.c
echo 4 > state
exit 0
