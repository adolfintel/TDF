#!/bin/bash
echo "Building futex2test"
mkdir build
gcc -static -o build/futex2test futex2test.c
if [ $? -ne 0 ]; then exit 1; fi
exit 0
