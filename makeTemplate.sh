#!/usr/bin/env bash
fail(){
    echo "Build failed: $1"
    exit 1
}
depsCheckFailed=0
for d in "dxvk-async" "dxvk" "d8vk" "vkd3d" "xutils" "futex2test" "vkgpltest" "wine" "prebuilts" "vcredist" "mfplat" "corefonts"; do
    sh "$d/checkDeps.sh"
    if [ $? -ne 0 ]; then
        depsCheckFailed=1;
    fi
done
zstd --version > /dev/null
if [ $? -ne 0 ]; then
    echo "zstd not installed"
    depsCheckFailed=1
fi
if [ $depsCheckFailed -ne 0 ]; then
    fail "deps-check"
fi
version=$(date +"%Y%m%d")
dir="template-$version"
rm -rf "$dir"
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
cd d8vk
d8vkFallbacked=0
./build.sh master
if [ $? -ne 0 ]; then
    d8vkFallbacked=1
    ./build.sh stable
    if [ $? -ne 0 ]; then
        fail "d8vk"
    fi
fi
mv build/* "../$dir/system/d8vk"
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
cd xutils
./build.sh
if [ $? -ne 0 ]; then fail "xutils"; fi
mv build/* "../$dir/system/xutils/"
rm -rf build
cd ..
cd futex2test
./build.sh
if [ $? -ne 0 ]; then fail "futex2test"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
cd vkgpltest
./build.sh
if [ $? -ne 0 ]; then fail "vkgpltest"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
cd wine
./build.sh
if [ $? -ne 0 ]; then fail "wine"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
cd prebuilts
./build.sh
if [ $? -ne 0 ]; then fail "prebuilts"; fi
mv build/* "../$dir/system/"
rm -rf build
cd ..
cd vcredist
./build.sh
if [ $? -ne 0 ]; then fail "vcredist"; fi
mv build/* "../$dir/system/vcredist"
rm -rf build
cd ..
cd mfplat
./build.sh
if [ $? -ne 0 ]; then fail "mfplat"; fi
mv build/* "../$dir/system/mfplat"
rm -rf build
cd ..
cd corefonts
./build.sh
if [ $? -ne 0 ]; then fail "corefonts"; fi
mv build/* "../$dir/system/corefonts"
rm -rf build
cd ..
echo "v$version" > "$dir/system/version"
echo "Compressing template, this will take a few minutes"
chmod -R 777 "$dir"
cd "$dir"
./run.sh archive $1
if [ $? -ne 0 ]; then fail "compress"; fi
cd ..
echo "Cleaning up"
rm -rf "$dir"
echo "All done"
if [ $dxvkAsyncFallbacked -eq 1 ]; then
    echo "WARNING: dxvk-gplasync build failed, using latest prebuilt binary"
fi
if [ $dxvkFallbacked -eq 1 ]; then
    echo "WARNING: dxvk build failed, using latest prebuilt binary"
fi
if [ $d8vkFallbacked -eq 1 ]; then
    echo "WARNING: d8vk build failed, using latest prebuilt binary"
fi
if [ $vkd3dFallbacked -eq 1 ]; then
    echo "WARNING: vkd3d-proton build failed, using latest prebuilt binary"
fi
exit 0
