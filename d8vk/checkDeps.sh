#!/bin/bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
command -v wine > /dev/null
if [ $? -ne 0 ]; then
    echo "Wine not installed"
    failed=1
fi
command -v meson > /dev/null
if [ $? -ne 0 ]; then
    echo "Meson not installed"
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
command -v glslc > /dev/null
if [ $? -ne 0 ]; then
    echo "glslang not installed"
    failed=1
fi
command -v curl > /dev/null
if [ $? -ne 0 ]; then
    echo "curl not installed"
    failed=1
fi
command -v wget > /dev/null
if [ $? -ne 0 ]; then
    echo "wget not installed"
    failed=1
fi
command -v grep > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU grep not installed"
    failed=1
fi
command -v sed > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU sed not installed"
    failed=1
fi
exit $failed
