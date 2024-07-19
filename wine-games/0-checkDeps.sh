#!/usr/bin/env bash
failed=0
if ! hasCommand git; then
    echo "Git not installed"
    failed=1
fi
#wine-tkg's build script has its own dependency checks
exit $failed
