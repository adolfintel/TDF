#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading reaper (master)"
if [ -f incomplete ]; then
    rm -rf reaper
fi
touch incomplete
if [ -d reaper ]; then
    cd reaper
    git fetch --all -p
    git reset --hard origin/HEAD > /dev/null
    cd ..
else
    git clone https://github.com/Plagman/reaper/
fi
rm -f incomplete
echo 2 > state
exit 0
