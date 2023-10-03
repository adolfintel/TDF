#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building dxvk (master)"
rm -rf build
cd dxvk
sh package-release.sh master ../build --no-package
cd ../build
mv dxvk-master/x* .
rm -rf dxvk-master
cd ..
echo 4 > state
exit 0
