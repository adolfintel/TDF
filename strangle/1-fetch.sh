#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading libstrangle (master)"
if [ -f incomplete ]; then
    rm -rf libstrangle
fi
touch incomplete
if [ -d libstrangle ]; then
    cd libstrangle
    git fetch --all -p
    git reset --hard origin/HEAD > /dev/null
    cd ..
else
    git clone git@gitlab.com:Infernio/libstrangle.git
fi
rm -f incomplete
echo 2 > state
exit 0
