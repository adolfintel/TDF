#!/usr/bin/env bash
set -e
rm -rf build
mkdir build
cd build
echo "Downloading steamrt"
rm -rf steamrt steam-container-runtime
wget https://repo.steampowered.com/steamrt3/images/latest-container-runtime-public-beta/steam-container-runtime-complete.tar.gz
tar -xf steam-container-runtime-complete.tar.gz
mv steam-container-runtime steamrt
cd steamrt/depot/sniper_platform_*/files/share
tar -cvf "ca-certificates.tar" "ca-certificates/" > /dev/null
rm -rf "ca-certificates"
cd ../../../../../
rm -f steam-container-runtime-complete.tar.gz
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
