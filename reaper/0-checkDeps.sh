#!/usr/bin/env bash
failed=0
if ! hasCommand git; then
    echo "Git not installed"
    failed=1
fi
if ! hasCommand g++; then
    echo "g++ not installed"
    failed=1
fi
if ! hasCommand meson; then
    echo "meson not installed"
    failed=1
fi
exit $failed
