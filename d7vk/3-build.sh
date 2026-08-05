#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building d7vk (master)"
rm -rf build
cd d7vk
bash package-release.sh master ../build --no-package
cd ../build
mv d7vk-master/x* .
rm -rf d7vk-master
cd ..
echo 4 > state
exit 0
