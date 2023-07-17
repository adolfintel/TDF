#!/usr/bin/env bash
set -e
echo "Building TDF Wine using wine-tkg"
rm -rf build repo
mkdir build
mkdir repo
cd repo
git clone https://github.com/Frogging-Family/wine-tkg-git
cd wine-tkg-git/wine-tkg-git
#tkg is supposed to have an _EXT_CONFIG_PATH variable but it doesn't work (or if it does it doesn't disable the stupid prompt at the beginning) so I just copy the config into it, fuck it
cp ../../../wine-tkg-tdf-games.cfg wine-tkg-profiles
cp ../../../wine-tkg-tdf-mainline.cfg wine-tkg-profiles
echo "_LOCAL_PRESET=\"tdf-games\"" > customization.cfg
./non-makepkg-build.sh
mv non-makepkg-builds/wine-tkg-tdf-games-* ../../../build/wine-games
echo "_LOCAL_PRESET=\"tdf-mainline\"" > customization.cfg
./non-makepkg-build.sh
mv non-makepkg-builds/wine-tkg-tdf-mainline-* ../../../build/wine-mainline
cd ../../../build/wine-games
rm -rf include share/man share/applications
cd ../wine-mainline
rm -rf include share/man share/applications
cd ../..
rm -rf repo
exit 0
