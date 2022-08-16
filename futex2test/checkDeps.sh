#!/bin/bash
failed=0
gcc --version > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
exit $failed
