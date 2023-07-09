#!/usr/bin/env bash
set -e
rm -rf build temp
mkdir build temp
cd temp
exes=("andale32" "arial32" "arialb32" "comic32" "courie32" "georgi32" "impact32" "times32" "trebuc32" "verdan32" "webdin32")
for exe in ${exes[@]}; do
    wget "https://sourceforge.net/projects/corefonts/files/the fonts/final/$exe.exe"
done
cabextract *.exe
mv *.TTF *.ttf ../build
cd ..
rm -rf temp
exit 0
