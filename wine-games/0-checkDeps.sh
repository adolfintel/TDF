#!/usr/bin/env bash
failed=0
if ! hasCommand git; then
    echo "Git not installed"
    failed=1
fi
if ! hasCommand automake; then
    echo "automake not installed"
    failed=1
fi
if ! hasCommand flex; then
    echo "flex not installed"
    failed=1
fi
if ! hasCommand bison; then
    echo "bison not installed"
    failed=1
fi
if ! hasCommand pkg-config; then
    echo "pkgconf not installed"
    failed=1
fi
#wine-tkg's build script has its own dependency checks
exit $failed
