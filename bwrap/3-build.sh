#!/usr/bin/env bash
set -e
echo 3 > state
echo "Building bubblewrap (master)"
rm -rf build
mkdir build
cd bubblewrap
rm -rf _builddir
meson _builddir
meson compile -C _builddir
mv _builddir/bwrap ../build
rm -rf _builddir
echo 4 > state
exit 0
