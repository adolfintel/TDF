#!/usr/bin/env bash
failed=0
command -v git > /dev/null
if [ $? -ne 0 ]; then
    echo "git not installed"
    failed=1
fi
exit $failed
