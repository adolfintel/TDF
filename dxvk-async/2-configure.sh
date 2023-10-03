#!/usr/bin/env bash
set -e
echo 2 > state
cd dxvk
git -c advice.detachedHead=false checkout --force --no-track -B temp origin/HEAD
patch -p1 --forward < ../dxvk-gplasync/patches/dxvk-gplasync-master.patch
patch -p1 --forward < ../dxvk-gplasync/patches/global-dxvk.conf.patch
cd ..
echo 3 > state
exit 0
