#!/bin/bash
if [ "$1" == "stable" ]; then
    echo "Downloading d8vk (stable build)"
    rm -rf build repo
    url=$(curl --silent "https://api.github.com/repos/AlpyneDreams/d8vk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ $? -ne 0 ]; then exit 1; fi
    wget -O d8vk.tar.gz "$url"
    if [ $? -ne 0 ]; then exit 1; fi
    mkdir build
    tar -xf d8vk.tar.gz --directory build
    if [ $? -ne 0 ]; then exit 1; fi
    cd build
    rm LICENSE README.md setup_d3d8.sh
    if [ $? -ne 0 ]; then exit 1; fi
    mv dxvk.conf d8vk.conf.template
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    rm d8vk.tar.gz
else
    echo "Building d8vk (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    if [ $? -ne 0 ]; then exit 1; fi
    git clone --recursive https://github.com/AlpyneDreams/d8vk.git
    if [ $? -ne 0 ]; then exit 1; fi
    if [ -e "../branch.txt" ]; then
        cd d8vk
        git checkout $(cat "../../branch.txt")
        if [ $? -ne 0 ]; then exit 1; fi
        cd ..
    fi
    cd d8vk
    sh package-release.sh master ../build --no-package
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    rm -rf repo
    wget https://raw.githubusercontent.com/AlpyneDreams/d8vk/master/dxvk.conf -O d8vk.conf.template
    if [ $? -ne 0 ]; then exit 1; fi
    mv d8vk.conf.template build/
    if [ $? -ne 0 ]; then exit 1; fi
fi
exit 0
