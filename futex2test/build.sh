#!/usr/bin/env bash
set -e
echo "Building futex2test"
mkdir build
gcc -static -o build/futex2test futex2test.c
exit 0
