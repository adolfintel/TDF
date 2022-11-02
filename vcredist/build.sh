#!/bin/bash
rm -rf build
mkdir build
cd build
echo "Downloading vcredist"
wget https://aka.ms/vs/17/release/vc_redist.x64.exe
if [ $? -ne 0 ]; then exit 1; fi
wget https://aka.ms/vs/17/release/vc_redist.x86.exe
if [ $? -ne 0 ]; then exit 1; fi
exit 0
