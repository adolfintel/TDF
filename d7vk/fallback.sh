#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading d7vk (stable build)"
rm -rf build
touch incomplete
url=$(curl -L --silent "https://api.github.com/repos/WinterSnowfall/d7vk/releases/latest" | grep '"browser_download_url"' | grep '.zip"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
wget -O d7vk.zip "$url"
mkdir build
unzip d7vk.zip -d build
mv build/d7vk-*/* build
rm -rf build/d7vk-*
rm -f d7vk.zip
rm -f incomplete
echo 4 > state
exit 0
