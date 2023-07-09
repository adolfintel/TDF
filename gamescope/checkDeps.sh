#!/bin/bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
command -v meson > /dev/null
if [ $? -ne 0 ]; then
    echo "Meson not installed"
    failed=1
fi
command -v glslc > /dev/null
if [ $? -ne 0 ]; then
    echo "glslang not installed"
    failed=1
fi
command -v gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
exit $failed
