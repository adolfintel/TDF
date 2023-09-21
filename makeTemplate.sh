#!/usr/bin/env bash
if [ -z "$TDF_BUILD_NOUPDATES" ]; then
    if [ -d .git ]; then
        echo "This is a git repo, checking for TDF updates"
        git fetch --all -p
        git reset --hard origin/newbuild > /dev/null
        TDF_BUILD_NOUPDATES=1 ./makeTemplate.sh && exit 0
        exit 0
    else
        echo "Not a git repo, please check for TDF updates manually"
    fi
fi
fail(){
    echo "Build failed: $1"
    exit 1
}
modules=("vkd3d" "dxvk" "dxvk-async" "d8vk" "wine-games" "wine-mainline" "winesmoketest" "xutils" "futex2test" "vkgpltest" "msi" "steamrt" "vcredist" "corefonts")
if [ "$1" == "clean" ]; then
    echo "Cleaning up"
    rm -f state
    for module in "${modules[@]}"; do
        cd "$module"
        ./clean.sh
        if [ $? -ne 0 ]; then
            fail "Clean failed for module $module"
        fi
        cd ..
    done
    echo "Done!"
    exit 0
fi
failedDepsCheck=0
for module in "${modules[@]}"; do
    cd "$module"
    for f in ./0-*.sh; do
        "$f"
        if [ $? -ne 0 ]; then
            failedDepsCheck=1
        fi
    done
    cd ..
done
command -v zstd > /dev/null
if [ $? -ne 0 ]; then
    echo "zstd not installed"
    failedDepsCheck=1
fi
if [ $failedDepsCheck -eq 1 ]; then
    fail "missing dependencies"
fi
failedModules=()
version=$(date +"%Y%m%d")
startState=0
if [ -f state ]; then
    startState="$(cat state)"
    startState=$((startState))
fi
for state in {1..3}; do
    echo $state > state
    for module in "${modules[@]}"; do
        skip=0
        for f in "${failedModules[@]}"; do
            if [ "$module" == "$f" ]; then
                skip=1
                break
            fi
        done
        if [ $skip -eq 1 ]; then
            echo "WARNING: $module has fallbacked, skipping state $state"
            continue
        fi
        cd "$module"
        modState=0
        if [ -f state ]; then
            modState="$(cat state)"
            modState=$((modState))
        fi
        if [ $modState -gt $state ]; then
            echo "RESUME: $module is in state $modState, current state is $state, skipping this phase"
            cd ..
            continue
        fi
        for f in "./$state"-*.sh; do
            "$f"
            if [ $? -ne 0 ]; then
                echo "FAILED: $module, phase $state, script $f"
                if [ -x fallback.sh ]; then
                    echo "Attempting fallback for module $module"
                    failedModules+=("$module")
                    ./fallback.sh
                    if [ $? -ne 0 ]; then
                        fail "$module, both the regular build and the fallback have failed"
                    fi
                    break
                else
                    echo "No fallback available for this module"
                    fail "$module"
                fi
            fi
        done
        cd ..
    done
done
rm -f state
echo "Copying files"
dir="template-$version"
rm -rf "$dir"
cp -r template-base "$dir"
for module in "${modules[@]}"; do
    cp -r "$module/build" "$dir/system/$module"
done
if [ ${#failedModules[@]} -ne 0 ]; then
    echo "WARNING: The following modules failed to build, a fallback version was used instead"
    for module in "${failedModules[@]}"; do
        echo "* $module"
    done
fi
echo "Compressing template, this will take a few minutes"
cd "$dir"
./run.sh archive
cd ..
echo "Cleaning up"
for module in "${modules[@]}"; do
    rm -f "$module/state"
done
rm -rf "$dir"
echo "Done!"
exit 0
