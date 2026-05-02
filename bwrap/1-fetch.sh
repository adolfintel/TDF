#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading bubblewrap (master)"
if [ -f incomplete ]; then
    rm -rf bubblewrap build
fi
touch incomplete
if [ -d bubblewrap ]; then
    cd bubblewrap
    git fetch --all -p
    git reset --hard origin/main > /dev/null
    cd ..
else
    git clone https://github.com/containers/bubblewrap
    cd bubblewrap
    cd ..
fi
rm -f incomplete
echo 2 > state
exit 0
