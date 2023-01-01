#!/bin/bash
echo "Building Gamescope (master)"
rm -rf gamescope build
mkdir build
git clone https://github.com/Plagman/gamescope
if [ $? -ne 0 ]; then exit 1; fi
cd gamescope
git submodule update --init
if [ $? -ne 0 ]; then exit 1; fi
meson build/
if [ $? -ne 0 ]; then exit 1; fi
ninja -C build/
if [ $? -ne 0 ]; then exit 1; fi
cp build/src/gamescope ../build/gamescope
if [ $? -ne 0 ]; then
    cp build/gamescope ../build/gamescope
    if [ $? -ne 0 ]; then exit 1; fi
fi
cd ..
rm -rf gamescope
exit 0
