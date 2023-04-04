#!/bin/bash
failed=0
wget --version > /dev/null
if [ $? -ne 0 ]; then
    echo "wget not installed"
    failed=1
fi
cabextract --version > /dev/null
if [ $? -ne 0 ]; then
    echo "cabextract not installed"
    failed=1
fi
exit $failed