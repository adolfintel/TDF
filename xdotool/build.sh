#!/bin/bash
echo "Building xdotool (master)"
rm -rf build repo
mkdir build
mkdir repo
cd repo
if [ $? -ne 0 ]; then exit 1; fi
git clone --recursive https://github.com/jordansissel/xdotool.git
if [ $? -ne 0 ]; then exit 1; fi
cd xdotool
make static
if [ $? -ne 0 ]; then exit 1; fi
cd ..
cp -r "xdotool/xdotool.static"* ../build/xdotool
if [ $? -ne 0 ]; then exit 1; fi
cd ..
rm -rf repo
if [ $? -ne 0 ]; then exit 1; fi
exit 0
