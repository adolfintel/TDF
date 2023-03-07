#!/bin/bash
echo "Building Gamescope (master)"
rm -rf gamescope seatd build
mkdir build
git clone https://github.com/Plagman/gamescope
if [ $? -ne 0 ]; then exit 1; fi
cd gamescope
git submodule update --init
if [ $? -ne 0 ]; then exit 1; fi
cp -f ../gs_meson_options.txt meson_options.txt
if [ $? -ne 0 ]; then exit 1; fi
meson build/
if [ $? -ne 0 ]; then exit 1; fi
ninja -C build/
if [ $? -ne 0 ]; then exit 1; fi
cp build/src/gamescope ../build/
if [ $? -ne 0 ]; then
    cp build/gamescope ../build/
    if [ $? -ne 0 ]; then exit 1; fi
fi
cd ..
rm -rf gamescope
echo "Building libseat (master)"
git clone https://github.com/kennylevinsen/seatd
if [ $? -ne 0 ]; then exit 1; fi
cd seatd
cp -f ../seatd_meson_options.txt meson_options.txt
if [ $? -ne 0 ]; then exit 1; fi
meson build/
if [ $? -ne 0 ]; then exit 1; fi
ninja -C build/
if [ $? -ne 0 ]; then exit 1; fi
cp build/libseat.so.1 ../build/
if [ $? -ne 0 ]; then exit 1; fi
cd ..
rm -rf seatd
cd build
ln -s libseat.so.1 libseat.so
cd ..
exit 0
