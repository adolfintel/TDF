#!/bin/bash
failed=0
git --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
meson --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Meson not installed"
    failed=1
fi
glslc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "glslang not installed"
    failed=1
fi
gcc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
exit $failed
