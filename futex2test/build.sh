#!/usr/bin/env bash
set -e
echo "Building futex2test"
rm -rf build
mkdir build
gcc -static -o build/futex2test futex2test.c
exit 0
