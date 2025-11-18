#!/usr/bin/env bash
set -e
echo 2 > state
cd vkd3d-proton
git -c advice.detachedHead=false checkout --force --no-track -B temp origin/HEAD
if [ "$(ls ../patches)" ]; then
    for f in ../patches/*; do
        patch -p1 --forward < "$f"
    done
fi
cd ..
echo 3 > state
exit 0
