#!/bin/bash
failed=0
git --version > /dev/null
if [ $? -ne 0 ]; then
    echo "git not installed"
    failed=1
fi
exit $failed