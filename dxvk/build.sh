#!/usr/bin/env bash
set -e
if [ "$1" == "stable" ]; then
    echo "Downloading dxvk (stable build)"
    rm -rf build repo
    url=$(curl --silent "https://api.github.com/repos/doitsujin/dxvk/releases/latest" | grep '"browser_download_url"' | grep '.tar.gz"' | sed -E 's/.*"([^"]+)".*/\1/')
    wget -O dxvk.tar.gz "$url"
    mkdir build
    tar -xf dxvk.tar.gz --directory build
    mv build/dxvk-*/* build
    rm -rf build/dxvk-*
    rm build/setup_dxvk.sh
    rm dxvk.tar.gz
else
    echo "Building dxvk (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    git clone --recursive https://github.com/doitsujin/dxvk
    cd dxvk
    sh package-release.sh master ../build --no-package
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    cd ..
    rm -rf repo
fi
wget https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf -O dxvk.conf.template
mv dxvk.conf.template build/
exit 0
