#!/usr/bin/env bash
failed=0
if ! hasCommand git; then
    echo "Git not installed"
    failed=1
fi
if ! hasCommand gcc; then
    echo "GCC not installed"
    failed=1
fi
if ! hasCommand make; then
    echo "make not installed"
    failed=1
fi
exit $failed
