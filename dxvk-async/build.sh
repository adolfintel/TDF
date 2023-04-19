#!/bin/bash
if [ "$1" == "stable" ]; then
    echo "Downloading dxvk-gplasync (stable build)"
    rm -rf build repo
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    filename=$(ls dxvk-gplasync/*.tar.gz | tail -n 1)
    if [ $? -ne 0 ]; then exit 1; fi
    mkdir build
    tar -xf "$filename" --directory build
    if [ $? -ne 0 ]; then exit 1; fi
    mv build/dxvk-*/* build
    if [ $? -ne 0 ]; then exit 1; fi
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
    if [ $? -ne 0 ]; then exit 1; fi
    git clone --recursive https://github.com/doitsujin/dxvk
    if [ $? -ne 0 ]; then exit 1; fi
    if [ -e "../branch.txt" ]; then
        cd dxvk
        git checkout $(cat "../../branch.txt")
        if [ $? -ne 0 ]; then exit 1; fi
        cd ..
    fi
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    cd dxvk-gplasync
    filename=$(ls *.patch | tail -n 1)
    cd ..
    if [ $? -ne 0 ]; then exit 1; fi
    cd dxvk
    patch -Np1 < "../dxvk-gplasync/$filename"
    if [ $? -ne 0 ]; then exit 1; fi
    sh package-release.sh master ../build --no-package
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    cp -r "build/dxvk-master/x"* ../build
    if [ $? -ne 0 ]; then exit 1; fi
    cd ..
    rm -rf repo
fi
wget https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf -O dxvk.conf.template
if [ $? -ne 0 ]; then exit 1; fi
mv dxvk.conf.template build/
if [ $? -ne 0 ]; then exit 1; fi
exit 0
