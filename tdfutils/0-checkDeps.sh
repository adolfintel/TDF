#!/usr/bin/env bash
failed=0
if ! hasCommand cmake; then
    echo "cmake not installed"
    failed=1
fi
if ! hasCommand make; then
    echo "make not installed"
    failed=1
fi
if ! hasCommand gcc; then
    echo "GCC not installed"
    failed=1
fi
if ! hasCommand g++; then
    echo "G++ not installed"
    failed=1
fi
if ! hasCommand i686-w64-mingw32-gcc || ! hasCommand x86_64-w64-mingw32-gcc; then
    echo "Mingw-w64 not installed"
    failed=1
fi
exit $failed
