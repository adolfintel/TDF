#!/usr/bin/env bash
set -e
rm -rf gamescope seatd build
mkdir build
if [ -d "override" ]; then
    echo "Using prebuilt Gamescope from override folder"
    cp -r override/* build
    exit 0
fi
echo "Building Gamescope (master)"
git clone https://github.com/Plagman/gamescope
cd gamescope
git submodule update --init
cp -f ../gs_meson_options.txt meson_options.txt
meson build/
ninja -C build/
set +e
cp build/src/gamescope ../build/
if [ $? -ne 0 ]; then
    cp build/gamescope ../build/
    if [ $? -ne 0 ]; then exit 1; fi
fi
set -e
cd ..
rm -rf gamescope
echo "Building libseat (master)"
git clone https://github.com/kennylevinsen/seatd
cd seatd
cp -f ../seatd_meson_options.txt meson_options.txt
meson build/
ninja -C build/
cp build/libseat.so.1 ../build/
cd ..
rm -rf seatd
cd build
ln -s libseat.so.1 libseat.so
cd ..
exit 0
