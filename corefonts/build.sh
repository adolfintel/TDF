#!/bin/bash
rm -rf build temp
if [ $? -ne 0 ]; then exit 1; fi
mkdir build temp
if [ $? -ne 0 ]; then exit 1; fi
cd temp
if [ $? -ne 0 ]; then exit 1; fi
exes=("andale32" "arial32" "arialb32" "comic32" "courie32" "georgi32" "impact32" "times32" "trebuc32" "verdan32" "webdin32")
for exe in ${exes[@]}; do
    wget "https://sourceforge.net/projects/corefonts/files/the fonts/final/$exe.exe"
    if [ $? -ne 0 ]; then exit 1; fi
done
cabextract *.exe
if [ $? -ne 0 ]; then exit 1; fi
mv *.TTF *.ttf ../build
if [ $? -ne 0 ]; then exit 1; fi
cd ..
rm -rf temp
if [ $? -ne 0 ]; then exit 1; fi
