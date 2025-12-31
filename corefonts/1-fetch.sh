#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading Windows Fonts Archive (master)"
if [ -f incomplete ]; then
    rm -rf WindowsFontsArchive build
fi
touch incomplete
if [ ! -d build ]; then
    mkdir build
fi
if [ -d WindowsFontsArchive ]; then
    cd WindowsFontsArchive
    git fetch --all -p
    git reset --hard origin/main > /dev/null
    cd ..
else
    git clone https://github.com/adasThePro/WindowsFontsArchive
fi
cp -f "WindowsFontsArchive/Windows 11"/* build
rm -f incomplete
echo 2 > state
exit 0
