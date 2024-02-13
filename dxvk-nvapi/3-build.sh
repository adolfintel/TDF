#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building dxvk-nvapi (master)"
rm -rf build
cd dxvk-nvapi
sh package-release.sh master ../build --no-package
cd ../build
mv dxvk-nvapi-master/x* .
rm -rf dxvk-nvapi-master
cd ..
echo 4 > state
exit 0
