#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building vkd3d-proton (master)"
rm -rf build
cd vkd3d-proton
sh package-release.sh master ../build --no-package
cd ../build
mv vkd3d-proton-master/x* .
rm -rf vkd3d-proton-master
cd ..
echo 4 > state
exit 0
