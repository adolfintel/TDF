#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading dxvk (stable build)"
rm -rf build
touch incomplete
url=$(curl --silent "https://api.github.com/repos/doitsujin/dxvk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
wget -O dxvk.tar.gz "$url"
mkdir build
tar -xf dxvk.tar.gz --directory build
mv build/dxvk-*/* build
rm -rf build/dxvk-*
rm -f build/setup_dxvk.sh
rm -f dxvk.tar.gz
rm -f incomplete
echo 4 > state
exit 0
