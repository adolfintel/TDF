#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building zenity (3.44)"
rm -rf build
mkdir build
cd zenity
meson ../build
sed -i "s/#define ZENITY_DATADIR*/#define ZENITY_DATADIR \".\/system\/zenity\/data\"\/\//g" ../build/config.h
meson compile -C ../build
cd ..
mkdir build2
mv build/src/zenity build2/
cp -R zenity/data build2/
cp zenity/src/zenity.ui build2/data/
rm -rf build
mv build2 build
cp running.png build
echo 4 > state
exit 0
