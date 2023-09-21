#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building futex2test"
rm -rf build
mkdir build
gcc -static -o build/futex2test futex2test.c
echo 4 > state
exit 0
