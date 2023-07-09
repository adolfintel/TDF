#!/bin/bash
failed=0
command -v wget > /dev/null
if [ $? -ne 0 ]; then
    echo "wget not installed"
    failed=1
fi
exit $failed
