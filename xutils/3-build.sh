#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building xdotool (master)"
rm -rf build
mkdir build
cd xdotool
make static
mv xdotool.static* ../build/xdotool
cd ..
echo 4 > state
exit 0
