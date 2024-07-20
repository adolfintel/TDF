#!/usr/bin/env bash
# shellcheck disable=SC2164,SC2103,SC2317

modules=("vkd3d" "dxvk" "dxvk-async" "dxvk-nvapi" "wine-games" "wine-mainline" "tdfutils" "xutils" "zenity" "msi" "vcredist" "corefonts")
fail(){
    echo "Build failed: $1"
    exit 1
}
hasCommand(){
    command -v "$1" > /dev/null
    return $?
}
export -f fail
export -f hasCommand
if [[ "$PWD" = *" "* ]]; then
    fail "The current path ($PWD) contains spaces, this will cause Wine to fail to build, move TDF somewhere else"
fi
if [ "$1" = "clean" ]; then
    echo "Cleaning up"
    rm -f state
    for module in "${modules[@]}"; do
        cd "$module"
        if ! ./clean.sh; then
            fail "Clean failed for module $module"
        fi
        cd ..
    done
    echo "Done!"
fi
if [ -z "$TDF_BUILD_STARTED" ]; then
    if [ -n "$TDF_BUILD_AUTOUPDATE" ]; then
        if [ -d .git ]; then
            echo "Checking for TDF updates"
            git fetch --all -p
            git reset --hard origin/"$(git branch --show-current)" > /dev/null
            TDF_BUILD_STARTED=1 ./makeTemplate.sh && exit 0
            exit 0
        else
            echo "Not a git repo, please check for TDF updates manually"
        fi
    else
        echo "This is a git repo, use TDF_BUILD_AUTOUPDATE=1 ./makeTemplate.sh to automatically download TDF updates"
        sleep 1
    fi
fi
failedDepsCheck=0
for module in "${modules[@]}"; do
    cd "$module"
    for f in ./0-*.sh; do
        if ! "$f"; then
            failedDepsCheck=1
        fi
    done
    cd ..
done
if ! command -v zstd > /dev/null; then
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
    echo "$state" > state
    for module in "${modules[@]}"; do
        skip=0
        for f in "${failedModules[@]}"; do
            if [ "$module" = "$f" ]; then
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
        if [ "$modState" -gt "$state" ]; then
            echo "RESUME: $module is in state $modState, current state is $state, skipping this phase"
            cd ..
            continue
        fi
        ok=0
        for f in "./$state"-*.sh; do
            if [ ! -f "$f" ]; then
                continue
            fi
            ok=1
            if ! "$f"; then
                echo "FAILED: $module, phase $state, script $f"
                if [ -x fallback.sh ]; then
                    echo "Attempting fallback for module $module"
                    failedModules+=("$module")
                    if ! ./fallback.sh; then
                        fail "$module, both the regular build and the fallback have failed"
                    fi
                    break
                else
                    echo "No fallback available for this module"
                    fail "$module"
                fi
            fi
        done
        if [ "$ok" -ne 1 ]; then
            echo "$module has no scripts for phase $state, skipping"
            echo "$((state+1))" > state
        fi
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
echo "v$version" > "$dir/system/version"
echo "Compressing template, this will take a few minutes"
cd "$dir"
chmod -R 777 .
./run.sh archive
cd ..
echo "Cleaning up"
for module in "${modules[@]}"; do
    rm -f "$module/state"
done
rm -rf "$dir"
echo "Done!"
exit 0
