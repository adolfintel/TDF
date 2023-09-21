#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading Steam Runtime (scout)"
if [ -f incomplete ]; then
    rm -rf build steam-runtime
fi
touch incomplete
newVer="$(curl https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-public-beta/steam-runtime.version.txt)"
mustUpdate=0
if [ -f build/version.txt ]; then
    if [ "$newVer" != "$(cat build/version.txt)" ]; then
        mustUpdate=1;
    fi
else
    mustUpdate=1;
fi
if [ $mustUpdate -eq 1 ]; then
    rm -rf build steam-runtime
    wget https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-public-beta/steam-runtime.tar.xz
    tar -xf steam-runtime.tar.xz
    mv steam-runtime build
    rm -f steam-runtime.tar.xz
fi
rm -f incomplete
echo 2 > state
exit 0
