#!/usr/bin/env bash
set -e
echo 3 > state
rm -rf build
mkdir build
echo "Building TDF Wine using tkg build system (wine-games)"
cd wine-tkg-git/wine-tkg-git
./non-makepkg-build.sh
mv non-makepkg-builds/wine-tkg-tdf-games-*/* ../../build
cd ../../build
rm -rf include share/man share/applications
cd ..
echo 4 > state
exit 0
