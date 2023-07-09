#!/usr/bin/env bash
set -e
if [ "$1" == "stable" ]; then
    echo "Downloading dxvk-gplasync (stable build)"
    rm -rf build repo
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    filename=$(ls dxvk-gplasync/releases/*.tar.gz | tail -n 1)
    mkdir build
    tar -xf "$filename" --directory build
    mv build/dxvk-*/* build
    rm -rf build/dxvk-*
    rm build/x*/*.sh
    rm build/*.sh
    rm -rf dxvk-gplasync
else
    echo "Building dxvk-gplasync (master)"
    rm -rf build repo
    mkdir build
    mkdir repo
    cd repo
    git clone --recursive https://github.com/doitsujin/dxvk
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    cd dxvk-gplasync
    git checkout test
    cd ../dxvk
    patch -p1 < ../dxvk-gplasync/patches/dxvk-gplasync-master.patch
    patch -p1 < ../dxvk-gplasync/patches/global-dxvk.conf.patch
    sh package-release.sh master ../build --no-package
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    cd ..
    rm -rf repo
fi
wget https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf -O dxvk.conf.template
mv dxvk.conf.template build/
exit 0
