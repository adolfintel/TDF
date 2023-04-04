#!/bin/bash
failed=0
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
tar --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GNU tar not installed"
    failed=1
fi
exit $failed
