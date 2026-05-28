#!/usr/bin/env bash
set -e
echo 1 > state
if [ -f incomplete ]; then
    rm -rf build temp driver.exe *.dll
fi
if [ ! -d build ]; then
    mkdir build
fi
touch incomplete
ver='26.5.2'
echo "Downloading AMD FSR4 files ($ver)"
mustDownload=0
if [ -f amddrv_version ]; then
    if [ "$(cat amddrv_version)" != "$ver" ]; then
        mustDownload=1
    fi
else
    mustDownload=1
fi
if [ $mustDownload -eq 1 ]; then
    wget -O driver.exe --referer="https://drivers.amd.com" "https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-$ver-win11-b.exe"
    7z x -otemp driver.exe
    find . -name "amdxcffx64.dll" -type f -exec mv {} . \;
    mv *.dll build/
    rm -rf temp driver.exe
    echo "$ver" > amddrv_version
fi
rm -f incomplete
echo 2 > state
exit 0
