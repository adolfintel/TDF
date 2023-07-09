#!/usr/bin/env bash
set -e
rm -rf build
mkdir build
cd build
echo "Downloading wine-ge"
rm -rf wine-ge temp
url=$(curl --silent "https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases" | grep "browser_download_url" | grep "lutris-GE-Proton" | grep ".tar.xz" | sed -E 's/.*"([^"]+)".*/\1/' | sort -V -r | head -n 1)
wget -O wine.tar.xz "$url"
mkdir temp
tar -xf wine.tar.xz --directory temp
rm -rf wine.tar.xz
mv temp/* wine-ge
rm -rf wine-ge/share/{applications,man}
rm -rf temp
echo "Downloading wine stable"
rm -rf wine-stable temp
mkdir wine-stable
wget -O wine.tar.zst "https://archlinux.org/packages/multilib/x86_64/wine/download/"
mkdir temp
tar -xf wine.tar.zst --directory temp
rm -rf wine.tar.zst
mv temp/usr/* wine-stable
rm -rf wine-stable/include wine-stable/share/{applications,man,fontconfig}
rm -rf temp
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
