#!/usr/bin/env bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "Git not installed"
    failed=1
fi
command -v gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
command -v meson > /dev/null
if [ $? -ne 0 ]; then
    echo "meson not installed"
    failed=1
fi
command -v help2man > /dev/null
if [ $? -ne 0 ]; then
    echo "help2man not installed"
    failed=1
fi
command -v itstool > /dev/null
if [ $? -ne 0 ]; then
    echo "itstool not installed"
    failed=1
fi
exit $failed
