#!/usr/bin/env bash
set -e
rm -rf build temp
mkdir build temp
cd temp
exes=("andale32" "arial32" "arialb32" "comic32" "courie32" "georgi32" "impact32" "times32" "trebuc32" "verdan32" "webdin32")
set +e
for exe in ${exes[@]}; do
    for i in {1..20}; do #sometimes a sourceforge mirror is down and if we do this it will try a different one
        wget --tries=1 "https://sourceforge.net/projects/corefonts/files/the fonts/final/$exe.exe"
        if [ $? -eq 0 ]; then
            break;
        fi
    done
    if [ ! -f "$exe.exe" ]; then
        exit 1
    fi
done
set -e
cabextract *.exe
mv *.TTF *.ttf ../build
cd ..
rm -rf temp
exit 0
