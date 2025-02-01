#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading dxvk-nvapi (stable build)"
rm -rf build
touch incomplete
url=$(curl -L --silent "https://api.github.com/repos/jp7677/dxvk-nvapi/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
wget -O dxvk-nvapi.tar.gz "$url"
mkdir build
tar -xf dxvk-nvapi.tar.gz --directory build
rm -f build/LICENSE
rm -f build/README.md
rm -f build/*/*.exe
rm -f dxvk-nvapi.tar.gz
rm -f incomplete
echo 4 > state
exit 0
