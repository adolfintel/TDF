#!/bin/bash
failed=0
git --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
wine --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Wine not installed"
    failed=1
fi
meson --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Meson not installed"
    failed=1
fi
i686-w64-mingw32-gcc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Mingw-w64 not installed"
    failed=1
fi
x86_64-w64-mingw32-gcc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Mingw-w64 not installed"
    failed=1
fi
glslc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "glslang not installed"
    failed=1
fi
patch --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU patch not installed"
    failed=1
fi
curl --version > /dev/null
if [ $? -ne 0 ]; then
    echo "curl not installed"
    failed=1
fi
wget --version > /dev/null
if [ $? -ne 0 ]; then
    echo "wget not installed"
    failed=1
fi
grep --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU grep not installed"
    failed=1
fi
sed --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU sed not installed"
    failed=1
fi
exit $failed
