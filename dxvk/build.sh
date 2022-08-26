#!/bin/bash
if [ "$1" == "stable" ]; then
    echo "Downloading dxvk (stable build)"
    rm -rf build repo
    url=$(curl --silent "https://api.github.com/repos/doitsujin/dxvk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ $? -ne 0 ]; then exit 1; fi
    wget -O dxvk.tar.gz "$url"
    if [ $? -ne 0 ]; then exit 1; fi
    mkdir build
    tar -xf dxvk.tar.gz --directory build
    if [ $? -ne 0 ]; then exit 1; fi
    mv build/dxvk-*/* build
    if [ $? -ne 0 ]; then exit 1; fi
    rm -rf build/dxvk-*
    rm build/setup_dxvk.sh
    rm dxvk.tar.gz
else
    echo "Building dxvk (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    if [ $? -ne 0 ]; then exit 1; fi
    git clone --recursive https://github.com/doitsujin/dxvk
    if [ $? -ne 0 ]; then exit 1; fi
    if [ -e "../branch.txt" ]; then
        cd dxvk
        git checkout $(cat "../../branch.txt")
        if [ $? -ne 0 ]; then exit 1; fi
        cd ..
    fi
    cd dxvk
    sh package-release.sh master ../build --no-package
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    rm -rf repo
fi
exit 0
