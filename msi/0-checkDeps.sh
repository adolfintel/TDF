#!/usr/bin/env bash
failed=0
if ! hasCommand curl; then
    echo "curl not installed"
    failed=1
fi
if ! hasCommand wget; then
    echo "wget not installed"
    failed=1
fi
if ! hasCommand grep; then
    echo "GNU grep not installed"
    failed=1
fi
if ! hasCommand sed; then
    echo "GNU sed not installed"
    failed=1
fi
if ! hasCommand sort; then
    echo "GNU sort not installed"
    failed=1
fi
if ! hasCommand tar; then
    echo "GNU tar not installed"
    failed=1
fi
if ! hasCommand patch; then
    echo "GNU patch not installed"
    failed=1
fi
exit $failed
