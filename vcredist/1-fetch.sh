#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading vcredist"
if [ -f incomplete ]; then
    rm -rf build
fi
touch incomplete
if [ ! -d build ]; then
    mkdir build
fi
cd build
while true; do
    wget --referer "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170" -N https://aka.ms/vs/17/release/vc_redist.x64.exe
    if ! file vc_redist.x64.exe | grep "Windows" > /dev/null; then
        echo "Looks like we got served garbage, retrying"
        rm -f vc_redist.x64.exe
        sleep 3
    else
        break
    fi
done
while true; do
    wget --referer "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170" -N https://aka.ms/vs/17/release/vc_redist.x86.exe
    if ! file vc_redist.x86.exe | grep "Windows" > /dev/null; then
        echo "Looks like we got served garbage, retrying"
        rm -f vc_redist.x86.exe
        sleep 3
    else
        break
    fi
done
cd ..
rm -f incomplete
echo 2 > state
exit 0
