#!/usr/bin/env bash
set -e
rm -rf build
mkdir build
cd build
echo "Downloading steamrt"
rm -rf steamrt steam-runtime
wget https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-public-beta/steam-runtime.tar.xz
tar -xf steam-runtime.tar.xz
mv steam-runtime steamrt
cd steamrt
patch -p1 < ../../steamrt-misleading-message.patch
cd ..
rm -f steam-runtime.tar.xz
rm -rf msi
mkdir msi
cd msi
echo "Downloading winemono"
url=$(curl --silent "https://api.github.com/repos/madewokherd/wine-mono/releases/latest" | grep '"browser_download_url"' | grep '.msi"' | sed -E 's/.*"([^"]+)".*/\1/')
wget -O winemono.msi "$url"
echo "Downloading winegecko"
ver=$(curl --silent "https://dl.winehq.org/wine/wine-gecko/?C=M;O=D" | grep "indexcolicon" | sed 1,2d | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | head -n 1 | sed -e 's#/$##' -e 's/\.git$//' -e 's#^.*/##')
wget -O winegecko32.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86.msi"
wget -O winegecko64.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86_64.msi"
exit 0
