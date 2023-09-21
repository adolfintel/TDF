#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading d8vk (stable build)"
rm -rf build
touch incomplete
url=$(curl --silent "https://api.github.com/repos/AlpyneDreams/d8vk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
wget -O d8vk.tar.gz "$url"
mkdir build
tar -xf d8vk.tar.gz --directory build
cd build
rm LICENSE README.md setup_d3d8.sh dxvk.conf
cd ..
rm d8vk.tar.gz
rm -f incomplete
echo 4 > state
exit 0
