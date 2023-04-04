#!/bin/bash
rm -rf build
mkdir build
cd build
echo "Downloading wine-ge"
rm -rf wine temp
url=$(curl --silent "https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases" | grep "browser_download_url" | grep "lutris-GE-Proton" | grep ".tar.xz" | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)
if [ $? -ne 0 ]; then exit 1; fi
wget -O wine.tar.xz "$url"
if [ $? -ne 0 ]; then exit 1; fi
mkdir temp
tar -xf wine.tar.xz --directory temp
if [ $? -ne 0 ]; then exit 1; fi
rm -rf wine.tar.xz
mv temp/* wine
if [ $? -ne 0 ]; then exit 1; fi
rm -rf temp
echo "Downloading steamrt"
rm -rf steamrt steam-runtime
wget https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-public-beta/steam-runtime.tar.xz
if [ $? -ne 0 ]; then exit 1; fi
tar -xf steam-runtime.tar.xz
if [ $? -ne 0 ]; then exit 1; fi
mv steam-runtime steamrt
if [ $? -ne 0 ]; then exit 1; fi
rm -f steam-runtime.tar.xz
rm -rf msi
mkdir msi
cd msi
if [ $? -ne 0 ]; then exit 1; fi
echo "Downloading winemono"
url=$(curl --silent "https://api.github.com/repos/madewokherd/wine-mono/releases/latest" | grep '"browser_download_url"' | grep '.msi"' | sed -E 's/.*"([^"]+)".*/\1/')
if [ $? -ne 0 ]; then exit 1; fi
wget -O winemono.msi "$url"
if [ $? -ne 0 ]; then exit 1; fi
echo "Downloading winegecko"
ver=$(curl --silent "https://dl.winehq.org/wine/wine-gecko/?C=M;O=D" | grep "indexcolicon" | sed 1,2d | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | head -n 1 | sed -e 's#/$##' -e 's/\.git$//' -e 's#^.*/##')
wget -O winegecko32.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86.msi"
if [ $? -ne 0 ]; then exit 1; fi
wget -O winegecko64.msi "https://dl.winehq.org/wine/wine-gecko/$ver/wine-gecko-$ver-x86_64.msi"
if [ $? -ne 0 ]; then exit 1; fi
exit 0
