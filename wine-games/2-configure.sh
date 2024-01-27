#!/usr/bin/env bash
set -e
echo 2 > state
cat wine-tkg-valve-exp-bleeding-tdf.cfg >> wine-tkg-git/wine-tkg-git/wine-tkg-profiles/wine-tkg-valve-exp-bleeding.cfg
echo "_LOCAL_PRESET=\"valve-exp-bleeding\"" >> wine-tkg-git/wine-tkg-git/customization.cfg
echo 3 > state
exit 0
