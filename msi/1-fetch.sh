#!/usr/bin/env bash
set -e
echo 1 > state
if [ -f incomplete ]; then
    rm -rf build
fi
touch incomplete
if [ ! -d build ]; then
    mkdir build
fi
cd build
echo "Downloading winemono"
ver='10.2.0'
mustDownload=0
if [ -f ../winemono_version ]; then
    if [ "$(cat ../winemono_version)" != "$ver" ]; then
        mustDownload=1;
    fi
else
    mustDownload=1;
fi
if [ $mustDownload -eq 1 ]; then
    wget -O winemono.msi "https://dl.winehq.org/wine/wine-mono/$ver/wine-mono-$ver-x86.msi"
    echo "$ver" > ../winemono_version
fi
echo "Downloading winegecko"
ver='2.47.4'
mustDownload=0
if [ -f ../winegecko_version ]; then
    if [ "$(cat ../winegecko_version)" != "$ver" ]; then
        mustDownload=1;
    fi
else
    mustDownload=1;
fi
if [ $mustDownload -eq 1 ]; then
    wget -O winegecko32.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86.msi"
    wget -O winegecko64.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86_64.msi"
    echo "$ver" > ../winegecko_version
fi
cd ..
rm -f incomplete
echo 2 > state
exit 0
