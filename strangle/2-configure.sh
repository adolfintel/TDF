#!/usr/bin/env bash
set -e
echo 2 > state
echo "Patching libstrangle (master)"
cd libstrangle
git -c advice.detachedHead=false checkout --force --no-track -B temp origin/HEAD
patch -p1 --forward < "../0001-Threading-fixes.patch"
cd ..
echo 3 > state
exit 0
