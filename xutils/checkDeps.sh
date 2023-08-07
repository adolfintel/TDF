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
command -v ar > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU ar not installed"
    failed=1
fi
exit $failed
