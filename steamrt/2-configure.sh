#!/usr/bin/env bash
set -e
echo 2 > state
cd build
patch -p1 --forward < ../steamrt-misleading-message.patch || true #doesn't matter if this patch fails
patch -p1 --forward < ../fix-openssl.patch || true #doesn't matter if this patch fails
cd ..
echo 3 > state
exit 0
