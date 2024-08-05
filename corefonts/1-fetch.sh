#!/usr/bin/env bash
set -e
echo 1 > state
if [ -f incomplete ]; then
    rm -rf temp build
fi
touch incomplete
if [ -d build ]; then #don't even bother checking for updates, this stuff hasn't been updated in 20+ years
    rm -f incomplete
    echo 2 > state
    exit 0
fi
exes=("andale32" "arial32" "arialb32" "comic32" "courie32" "georgi32" "impact32" "times32" "trebuc32" "verdan32" "webdin32")
rm -rf build temp
mkdir temp
cd temp
set +e
for exe in "${exes[@]}"; do
    # shellcheck disable=SC2034
    for i in {1..20}; do #sometimes a sourceforge mirror is down and if we do this it will try a different one
        if wget --tries=1 --timeout=10 "https://sourceforge.net/projects/corefonts/files/the fonts/final/$exe.exe"; then
            break;
        fi
    done
    if [ ! -f "$exe.exe" ]; then
        exit 1
    fi
done
set -e
mkdir ../build
cabextract "./"*.exe
mv "./"*.TTF "./"*.ttf ../build
cd ..
rm -rf temp
rm -f incomplete
echo 2 > state
exit 0
