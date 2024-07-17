#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading zenity (3.44)"
if [ -f incomplete ]; then
    rm -rf zenity build build2
fi
touch incomplete
if [ -d zenity ]; then
    cd zenity
    git fetch --all -p
    git reset --hard origin/zenity-3-44 > /dev/null
    git submodule update
    cd ..
else
    git clone --recursive https://gitlab.gnome.org/GNOME/zenity.git
    cd zenity
    git checkout zenity-3-44
    cd ..
fi
rm -f incomplete
echo 2 > state
exit 0
