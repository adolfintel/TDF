#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading dxvk-gplasync (stable build)"
rm -rf build dxvk-gplasync
touch incomplete
git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
filename=$(ls dxvk-gplasync/releases/*.tar.gz | tail -n 1)
mkdir build
tar -xf "$filename" --directory build
mv build/dxvk-*/* build
rm -rf build/dxvk-*
rm -f build/x*/*.sh
rm -f build/*.sh
rm -f incomplete
echo 4 > state
exit 0
