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
    before="$(pwd)"
    cd repo
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    if [ $? -ne 0 ]; then exit 1; fi
    cd dxvk-gplasync
    sh build-gplasync.sh
    cd "$before"
    mv repo/dxvk-gplasync/dxvk-gplasync-/* build/
    if [ $? -ne 0 ]; then exit 1; fi
    rm -rf repo
    if [ $? -ne 0 ]; then exit 1; fi
fi
wget https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf -O dxvk.conf.template
if [ $? -ne 0 ]; then exit 1; fi
mv dxvk.conf.template build/
if [ $? -ne 0 ]; then exit 1; fi
exit 0
