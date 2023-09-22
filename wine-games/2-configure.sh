#!/usr/bin/env bash
set -e
echo 2 > state
cp wine-tkg-valve-exp-bleeding-tdf.cfg wine-tkg-git/wine-tkg-git/wine-tkg-profiles/
echo "_LOCAL_PRESET=\"valve-exp-bleeding-tdf\"" >> wine-tkg-git/wine-tkg-git/customization.cfg
echo 3 > state
exit 0
