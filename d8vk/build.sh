#!/usr/bin/env bash
set -e
if [ "$1" == "stable" ]; then
    echo "Downloading d8vk (stable build)"
    rm -rf build repo
    url=$(curl --silent "https://api.github.com/repos/AlpyneDreams/d8vk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | sed -E 's/.*"([^"]+)".*/\1/')
    wget -O d8vk.tar.gz "$url"
    mkdir build
    tar -xf d8vk.tar.gz --directory build
    cd build
    rm LICENSE README.md setup_d3d8.sh dxvk.conf
    cd ..
    rm d8vk.tar.gz
else
    echo "Building d8vk (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    git clone --recursive https://github.com/AlpyneDreams/d8vk.git
    cd d8vk
    sh package-release.sh master ../build --no-package
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    cd ..
    rm -rf repo
fi
exit 0
