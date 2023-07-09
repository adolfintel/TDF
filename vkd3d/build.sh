#!/bin/bash
if [ "$1" == "stable" ]; then
    echo "Downloading vkd3d-proton (stable build)"
    rm -rf build
    url=$(curl --silent "https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest" | grep '"browser_download_url"' | grep '.tar.zst"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ $? -ne 0 ]; then exit 1; fi
    wget -O vkd3d.tar.zst "$url"
    if [ $? -ne 0 ]; then exit 1; fi
    mkdir build
    tar -xf vkd3d.tar.zst --directory build
    if [ $? -ne 0 ]; then exit 1; fi
    mv build/vkd3d-*/* build
    if [ $? -ne 0 ]; then exit 1; fi
    rm -rf build/vkd3d-*
    rm build/setup_vkd3d_proton.sh
    rm vkd3d.tar.zst
else
    echo "Building vkd3d-proton (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    if [ $? -ne 0 ]; then exit 1; fi
    git clone --recursive https://github.com/HansKristian-Work/vkd3d-proton
    if [ $? -ne 0 ]; then exit 1; fi
    cd vkd3d-proton
    #git checkout wave-heuristics
    #git submodule update
    sh package-release.sh master ../build --no-package
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    cp -r "build/vkd3d-proton-master/x"* ../build
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    rm -rf repo
fi
exit 0
