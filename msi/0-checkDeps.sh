#!/usr/bin/env bash
failed=0
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
command -v sort > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU sort not installed"
    failed=1
fi
command -v tar > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU tar not installed"
    failed=1
fi
command -v patch > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU patch not installed"
    failed=1
fi
exit $failed
