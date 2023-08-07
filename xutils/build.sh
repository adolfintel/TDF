#!/usr/bin/env bash
set -e
echo "Building xdotool (master)"
rm -rf build repo temp
mkdir build
mkdir repo
cd repo
git clone --recursive https://github.com/jordansissel/xdotool.git
cd xdotool
make static
cd ..
cp -r "xdotool/xdotool.static"* ../build/xdotool
cd ..
rm -rf repo
echo "Downloading xrandr (from Debian 11)"
mkdir temp
cd temp
url=$(curl --silent "https://packages.debian.org/bullseye/amd64/x11-xserver-utils/download" | grep "amd64.deb" | sed 1,2d | grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | head -n 1)
wget -O xutils.deb "$url"
ar x xutils.deb
tar -xvf data.tar.xz > /dev/null
mv ./usr/bin/xrandr ../build/
cd ..
rm -rf temp
exit 0
