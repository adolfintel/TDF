#!/usr/bin/env bash
set -e
echo 3 > state
rm -rf build
mkdir build
echo "Building futex2test"
gcc -static -o build/futex2test futex2test.c
echo "Building vkgpltest"
g++ -static-libstdc++ -static-libgcc -o build/vkgpltest vkgpltest.cpp -lvulkan
echo "Building Wine smoke test"
i686-w64-mingw32-gcc -static -o build/winesmoke32.exe winesmoketest.c
x86_64-w64-mingw32-gcc -static -o build/winesmoke64.exe winesmoketest.c
echo "Building glibc smoke test"
gcc -m64 -o build/glibcsmoke64 -march=x86-64 glibcsmoketest.c
echo "Building dnd (Do Not Disturb)"
if [ -e dndbuild ]; then
    rm -rf dndbuild
fi
cp -R dnd dndbuild
cd dndbuild
cmake .
make
mv dnd ../build
cd ..
rm -rf dndbuild
echo 4 > state
exit 0
