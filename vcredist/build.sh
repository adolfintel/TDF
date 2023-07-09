#!/usr/bin/env bash
set -e
rm -rf build
mkdir build
cd build
echo "Downloading vcredist"
wget https://aka.ms/vs/17/release/vc_redist.x64.exe
wget https://aka.ms/vs/17/release/vc_redist.x86.exe
exit 0
