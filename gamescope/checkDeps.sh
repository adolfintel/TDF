#!/usr/bin/env bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
command -v pkg-config > /dev/null
if [ $? -ne 0 ]; then
    echo "pkg-config not installed"
    failed=1
fi
command -v meson > /dev/null
if [ $? -ne 0 ]; then
    echo "Meson not installed"
    failed=1
fi
command -v glslc > /dev/null
if [ $? -ne 0 ]; then
    echo "glslc not installed"
    failed=1
fi
command -v glslangValidator > /dev/null
if [ $? -ne 0 ]; then
    echo "glslangValidator not installed"
    failed=1
fi
if [ ! -d "/usr/share/hwdata" ]; then
    echo "hwdata not installed (must be in /usr/share/hwdata)"
    failed=1
fi
command -v gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
exit $failed
