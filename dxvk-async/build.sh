#!/bin/bash
echo "Downloading dxvk-async (stable build)"
rm -rf build repo
url=$(curl --silent "https://api.github.com/repos/Sporif/dxvk-async/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | sed -E 's/.*"([^"]+)".*/\1/')
if [ $? -ne 0 ]; then exit 1; fi
wget -O dxvk.tar.gz "$url"
if [ $? -ne 0 ]; then exit 1; fi
mkdir build
tar -xf dxvk.tar.gz --directory build
if [ $? -ne 0 ]; then exit 1; fi
mv build/dxvk-*/* build
if [ $? -ne 0 ]; then exit 1; fi
rm -rf build/dxvk-*
rm build/setup_dxvk.sh
rm dxvk.tar.gz
wget https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf -O dxvk.conf.template
if [ $? -ne 0 ]; then exit 1; fi
mv dxvk.conf.template build/
if [ $? -ne 0 ]; then exit 1; fi
exit 0
