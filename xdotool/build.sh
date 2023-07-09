#!/bin/bash
set -e
echo "Building xdotool (master)"
rm -rf build repo
mkdir build
mkdir repo
cd repo
git clone --recursive https://github.com/jordansissel/xdotool.git
cd xdotool
make static
cd ..
cp -r "xdotool/xdotool.static"* ../build/xdotool
cd ..
rm -rf repo
exit 0
