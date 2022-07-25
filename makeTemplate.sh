#!/bin/bash
fail(){
    echo "Build failed: $1"
    exit 1
}
version=$(date +"%Y%m%d")
dir="template-$version"
rm -rf "$dir"
rm -f "$dir.tar.zst"
mkdir "$dir"
cp -r "template-base"/* "$dir"
cd dxvk-async
dxvkAsyncFallbacked=0
./build.sh master
if [ $? -ne 0 ]; then
    dxvkAsyncFallbacked=1
    ./build.sh stable
    if [ $? -ne 0 ]; then
        fail "dxvk-async"
    fi
fi
mv build/* "../$dir/system/dxvk-async"
rm -rf build
cd ..
cd dxvk
dxvkFallbacked=0
./build.sh master
if [ $? -ne 0 ]; then
    dxvkFallbacked=1
    ./build.sh stable
    if [ $? -ne 0 ]; then
        fail "dxvk"
    fi
fi
mv build/* "../$dir/system/dxvk"
rm -rf build
cd ..
cd vkd3d
vkd3dFallbacked=0
./build.sh master
if [ $? -ne 0 ]; then
    vkd3dFallbacked=1
    ./build.sh stable
    if [ $? -ne 0 ]; then
        fail "vkd3d-proton"
    fi
fi
mv build/* "../$dir/system/vkd3d"
rm -rf build
cd ..
cd gamescope
./build.sh master
if [ $? -ne 0 ]; then fail "gamescope"; fi
mv build/* "../$dir/system/gamescope"
rm -rf build
cd ..
cd futex2test
./build.sh
if [ $? -ne 0 ]; then fail "futex2test"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
cd prebuilts
./build.sh $5
if [ $? -ne 0 ]; then fail "prebuilts"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
echo "v$version" > "$dir/system/version"
echo "Compressing template"
chmod -R 777 "$dir"
if [ "$1" == "nocompress" ]; then
    tar -cvf "$dir.tar" "$dir"
else
    tar -I 'zstd --ultra -22' -cvf "$dir.tar.zst" "$dir"
fi
if [ $? -ne 0 ]; then fail 6; fi
echo "Cleaning up"
rm -rf "$dir"
echo "All done"
if [ $dxvkAsyncFallbacked -eq 1 ]; then
    echo "WARNING: dxvk-async build failed, using latest prebuilt binary"
fi
if [ $dxvkFallbacked -eq 1 ]; then
    echo "WARNING: dxvk build failed, using latest prebuilt binary"
fi
if [ $vkd3dFallbacked -eq 1 ]; then
    echo "WARNING: vkd3d-proton build failed, using latest prebuilt binary"
fi
exit 0
