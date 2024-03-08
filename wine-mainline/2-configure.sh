#!/usr/bin/env bash
set -e
echo 2 > state
rm -rf wine-tkg-git/wine-tkg-git/wine-tkg-userpatches/*
cp 0001-Hardcode-username-to-wine.mylatepatch wine-tkg-git/wine-tkg-git/wine-tkg-userpatches
echo "_LOCAL_PRESET=\"mainline\"" >> wine-tkg-git/wine-tkg-git/customization.cfg
cat wine-tkg-mainline-tdf.cfg >> wine-tkg-git/wine-tkg-git/wine-tkg-profiles/wine-tkg-mainline.cfg
echo 3 > state
exit 0
