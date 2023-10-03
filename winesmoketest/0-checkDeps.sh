#!/usr/bin/env bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
command -v i686-w64-mingw32-gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "Mingw-w64 not installed"
    failed=1
fi
command -v x86_64-w64-mingw32-gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "Mingw-w64 not installed"
    failed=1
fi
exit $failed
