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
if ! hasCommand meson; then
    echo "meson not installed"
    failed=1
fi
if ! hasCommand help2man; then
    echo "help2man not installed"
    failed=1
fi
if ! hasCommand itstool; then
    echo "itstool not installed"
    failed=1
fi
exit $failed
