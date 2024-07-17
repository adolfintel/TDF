#!/usr/bin/env bash
set -e
echo 2 > state
rm -rf wine-tkg-git/wine-tkg-git/wine-tkg-userpatches/*
cp patches/* wine-tkg-git/wine-tkg-git/wine-tkg-userpatches
cat wine-tkg-valve-exp-bleeding-tdf.cfg >> wine-tkg-git/wine-tkg-git/wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
echo "_LOCAL_PRESET=\"valve-exp-bleeding\"" >> wine-tkg-git/wine-tkg-git/customization.cfg
echo 3 > state
exit 0
