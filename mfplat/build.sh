#!/bin/bash
set -e
rm -rf build
mkdir build
cd build
echo "Downloading MS mfplat"
git clone https://github.com/z0z0z/mf-install
mv mf-install/*.reg mf-install/system32 mf-install/syswow64 .
rm -rf mf-install
exit 0
