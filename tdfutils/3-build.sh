#!/usr/bin/env bash
set -e
echo "Building TDF utils"
echo 3 > state
rm -rf build
mkdir build
gcc -o build/synctest synctest.c
gcc -o build/vkgpltest vkgpltest.c $(pkg-config --cflags --libs vulkan)
i686-w64-mingw32-gcc -static -o build/winesmoke32.exe winesmoketest.c
x86_64-w64-mingw32-gcc -static -o build/winesmoke64.exe winesmoketest.c
gcc -m64 -o build/glibcsmoke64 -march=x86-64 glibcsmoketest.c
gcc -o build/dnd dnd.c $(pkg-config --cflags --libs dbus-1)
gcc -o build/nosleep nosleep.c $(pkg-config --cflags --libs dbus-1)
gcc -o build/winebrowser.exe winebrowser.c #not a typo, we actually want an ELF binary
echo 4 > state
exit 0
