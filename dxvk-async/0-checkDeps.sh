#!/usr/bin/env bash
failed=0
if ! hasCommand git; then
    echo "Git not installed"
    failed=1
fi
if ! hasCommand patch; then
    echo "GNU patch not installed"
    failed=1
fi
if ! hasCommand wine; then
    echo "Wine not installed"
    failed=1
fi
if ! hasCommand meson; then
    echo "Meson not installed"
    failed=1
fi
if ! hasCommand i686-w64-mingw32-gcc || ! hasCommand x86_64-w64-mingw32-gcc; then
    echo "Mingw-w64 not installed"
    failed=1
fi
if ! hasCommand glslc && ! hasCommand glslangValidator; then
    echo "glslc or glslangValidator not installed"
    failed=1
fi
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
exit $failed
