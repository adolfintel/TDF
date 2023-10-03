#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading wine-tkg build system (master)"
if [ -f incomplete ]; then
    rm -rf wine-tkg-git build
fi
touch incomplete
if [ -d wine-tkg-git ]; then
    cd wine-tkg-git
    git fetch --all -p
    git reset --hard origin/master > /dev/null
    cd ..
else
    git clone https://github.com/Frogging-Family/wine-tkg-git
fi
rm -f incomplete
echo 2 > state
exit 0
