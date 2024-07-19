#!/usr/bin/env bash
failed=0
if ! hasCommand wget; then
    echo "wget not installed"
    failed=1
fi
exit $failed
