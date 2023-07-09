#!/bin/bash
failed=0
command -v gcc > /dev/null
if [ $? -ne 0 ]; then
    echo "GCC not installed"
    failed=1
fi
exit $failed
