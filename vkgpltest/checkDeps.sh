#!/bin/bash
failed=0
g++ --version > /dev/null
if [ $? -ne 0 ]; then
    echo "G++ not installed"
    failed=1
fi
exit $failed
