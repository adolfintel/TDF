#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building Wine smoke test"
rm -rf build
mkdir build
i686-w64-mingw32-gcc -static -o build/smoke32.exe smoke.c
x86_64-w64-mingw32-gcc -static -o build/smoke64.exe smoke.c
echo 4 > state
exit 0
