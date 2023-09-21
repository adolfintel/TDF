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
url=$(curl --silent "https://api.github.com/repos/madewokherd/wine-mono/releases/latest" | grep '"browser_download_url"' | grep '.msi"' | sed -E 's/.*"([^"]+)".*/\1/')
mustDownload=0
if [ -f ../winemono_version ]; then
    if [ "$(cat ../winemono_version)" != "$url" ]; then
        mustDownload=1;
    fi
else
    mustDownload=1;
fi
if [ $mustDownload -eq 1 ]; then
    wget -O winemono.msi "$url"
    echo "$url" > ../winemono_version
fi
echo "Downloading winegecko"
ver=$(curl --silent "https://dl.winehq.org/wine/wine-gecko/?C=M;O=D" | grep "indexcolicon" | sed 1,2d | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | head -n 1 | sed -e 's#/$##' -e 's/\.git$//' -e 's#^.*/##')
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
