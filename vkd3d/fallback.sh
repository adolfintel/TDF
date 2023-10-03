#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading vkd3d-proton (stable build)"
rm -rf build
touch incomplete
url=$(curl --silent "https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest" | grep '"browser_download_url"' | grep '.tar.zst"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
wget -O vkd3d.tar.zst "$url"
mkdir build
tar -xf vkd3d.tar.zst --directory build
mv build/vkd3d-*/* build
rm -rf build/vkd3d-*
rm -f build/setup_vkd3d_proton.sh
rm -f vkd3d.tar.zst
rm -f incomplete
echo 4 > state
exit 0
