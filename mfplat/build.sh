#!/bin/bash
rm -rf build
mkdir build
cd build
echo "Downloading MS mfplat"
git clone https://github.com/z0z0z/mf-install
if [ $? -ne 0 ]; then exit 1; fi
mv mf-install/*.reg mf-install/system32 mf-install/syswow64 .
if [ $? -ne 0 ]; then exit 1; fi
rm -rf mf-install
exit 0
