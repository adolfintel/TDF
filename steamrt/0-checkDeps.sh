#!/usr/bin/env bash
failed=0
command -v wget > /dev/null
if [ $? -ne 0 ]; then
    echo "wget not installed"
    failed=1
fi
command -v tar > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU tar not installed"
    failed=1
fi
command -v xz > /dev/null
if [ $? -ne 0 ]; then
    echo "xz not installed"
    failed=1
fi
command -v patch > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU patch not installed"
    failed=1
fi
exit $failed
