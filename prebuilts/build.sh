#!/bin/bash
rm -rf build
mkdir build
cd build
echo "Downloading wine-ge"
rm -rf wine temp
url=$(curl --silent "https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest" | grep '"browser_download_url"' | grep '.tar.xz"' | sed -E 's/.*"([^"]+)".*/\1/')
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
echo "Downloading seatd"
wget -O seatd.tar.zst https://archlinux.org/packages/community/x86_64/seatd/download
if [ $? -ne 0 ]; then exit 1; fi
rm -rf temp
mkdir temp
tar -xf seatd.tar.zst --directory temp
if [ $? -ne 0 ]; then exit 1; fi
mv temp/usr/lib/*.so.* steamrt/lib/x86_64-linux-gnu
if [ $? -ne 0 ]; then exit 1; fi
rm -f seatd.tar.zst
rm -rf temp
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
wget -O winegecko32.msi https://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86.msi
if [ $? -ne 0 ]; then exit 1; fi
wget -O winegecko64.msi https://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86_64.msi
if [ $? -ne 0 ]; then exit 1; fi
exit 0
