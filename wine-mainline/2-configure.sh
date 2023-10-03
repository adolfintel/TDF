#!/usr/bin/env bash
set -e
echo 2 > state
cp wine-tkg-tdf-mainline.cfg wine-tkg-git/wine-tkg-git/wine-tkg-profiles/
echo "_LOCAL_PRESET=\"tdf-mainline\"" >> wine-tkg-git/wine-tkg-git/customization.cfg
echo 3 > state
exit 0
