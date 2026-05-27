#!/usr/bin/env bash
#shellcheck disable=SC2155,SC1090,SC1091
shopt -s nullglob

export LC_ALL=C.UTF-8

source "system/localization/load.sh"

if [ $# -eq 0 ]; then
    _loc "$TDF_LOCALE_DONTRUNDIRECTLY"
    exit
fi
if [ "$(uname -s)" != "Linux" ]; then
    fail "$(_loc "$TDF_LOCALE_OS_WRONGOS")"
fi
if [ "$(uname -m)" != "x86_64" ]; then
    fail "$(_loc "$TDF_LOCALE_OS_WRONGARCH")"
fi

# Settings are explained in vars.conf and README.md

game_exe=''
game_args=()
game_workingDir=''

TDF_ALLOW_HOST_FILESYSTEM=2
TDF_CUSTOM_MOUNTS=()
TDF_BLOCK_NETWORK=1
TDF_BLOCK_BROWSER=1
TDF_BLOCK_SHM=1
TDF_BLOCK_NATIVE_INPUT=0
TDF_WINE_PREFERRED_VERSION="games"
TDF_WINEMONO=0
TDF_WINEGECKO=0
TDF_WINE_ARCH="win64"
TDF_VCREDIST=1
TDF_WINE_HIDE_CRASHES=1
TDF_WINE_AUDIO_DRIVER="default"
TDF_WINE_GRAPHICS_DRIVER="default"
TDF_COREFONTS=1
TDF_WINE_WINVER=""
TDF_WINE_THEME=""
TDF_WINE_NOSMT=0
TDF_WINE_NOECORES=0
TDF_WINE_PREFER_SAMESOCKET=0
TDF_WINE_MAXLOGICALCPUS=0
TDF_WINE_DPI=0
TDF_WINE_LANGUAGE=""
TDF_WINE_DEBUG_RELAY=0
TDF_WINE_DEBUG_GSTREAMER=0
TDF_WINE_SYNC=""
TDF_WINE_LAA=1
TDF_WINE_HEAP_DELAY_FREE=1
TDF_DXVK=1
TDF_DXVK_NVAPI=1
TDF_VKD3D=1
TDF_D7VK=1
TDF_HDR=0
TDF_GL_MAXFPS=0
TDF_WINE_SMOKETEST=1
TDF_IGNORE_EXIST_CHECKS=0
TDF_DND=1
TDF_NOSLEEP=1
TDF_MANGOHUD=0
TDF_GAMESCOPE=0
TDF_GAMESCOPE_PARAMETERS=""
TDF_HIDE_GAME_RUNNING_DIALOG=0
#shellcheck disable=SC2034
TDF_UI_LANGUAGE=""

export QT_SCALE_FACTOR_ROUNDING_POLICY=passthrough #some games don't take input correctly on high DPI displays without this TODO: see if wee still need this

TDF_TITLE="$(_loc "$TDF_LOCALE_DEFAULTTITLE")"
TDF_VERSION="$(cat system/version)"
_tmpDir="/tmp/tdf-$(echo "$PWD" | md5sum | cut -d' ' -f1)-tmp"

_mangohudCommand=()
_gamescopeCommand=()
_relayPath=''
declare -A _envs
_unsets=()
_wineDir=''
_customMounts=()

if [ -d "system/bwrap" ]; then
    export PATH="$PATH:$PWD/system/bwrap"
fi
if [ -d "system/zenity" ]; then
    export PATH="$PATH:$PWD/system/zenity"
fi

function _zenityInfo {
    zenity --title="$TDF_TITLE" --info --width=500 --text="$1"
}

function _zenityWarn {
    zenity --title="$TDF_TITLE" --warning --width=500 --text="$1"
}

function _zenityError {
    zenity --title="$TDF_TITLE" --error --width=500 --text="$1"
}

function _zenityProgressInit {
    exec 3> >(zenity --progress --no-cancel --title="$TDF_TITLE" --text="" --width=250 --auto-close)
    _zenityProgressPid=$!
}
function _zenityProgressOutput {
    echo "$1" >&3
    if [ -n "$2" ]; then
        echo "#$2" >&3
    fi
}
function _zenityProgressStop {
    echo "100" >&3
}

function fail {
    _zenityProgressStop
    _clearDND
    _clearNoSleep
    _stopWinebrowserBridge
    echo "$1"
    _zenityError "$1"
    exit
}

function contains {
    local needle="$1"
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

function copyIfDifferent {
    if ! cmp "$1" "$2" > /dev/null 2>&1; then
        if [ -e "$1" ]; then
            \cp "$1" "$2"
        fi
    fi
}

if [ -d "system/xutils" ]; then
    export PATH="$PATH:$PWD/system/xutils"
fi
source "system/builtinFunctions.sh"
XRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 1)
YRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 2)

function runSandboxed {
    cmdArray=("bwrap" "--die-with-parent" "--chdir" "/tdf" "--unshare-user" "--unshare-uts" "--unshare-cgroup" "--unshare-pid" "--tmpfs" "/")
    for f in "/usr" "/bin" "/lib" "/lib32" "/lib64" "/sys" "/etc/hosts" "/etc/hostname" "/etc/localtime" "/etc/resolv.conf" "/etc/fonts" "/etc/machine-id"; do
        if [ -e "$f" ]; then
            cmdArray+=("--ro-bind" "$f" "$f")
        fi
    done
    if [ ! -d "$_tmpDir" ]; then
        mkdir "$_tmpDir"
    fi
    cmdArray+=("--setenv" "XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" "--ro-bind" "/sys" "/sys" "--dev" "/dev" "--proc" "/proc" "--bind" "$_tmpDir" "/tmp" "--setenv" "USER" "wine" "--dev-bind" "/dev/dri" "/dev/dri" "--dev-bind" "/dev/snd" "/dev/snd" "--setenv" "HOME" "/home/wine" "--ro-bind" "$PWD" "/tdf" "--bind" "$PWD/data" "/tdf/data" "--bind" "$PWD/data/home" "/home" "--setenv" "WINEPREFIX" "/tdf/data/wineprefix")
    if [ -n "$WAYLAND_DISPLAY" ]; then
        cmdArray+=("--bind" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "--setenv" "WAYLAND_DISPLAY" "$WAYLAND_DISPLAY")
    fi
    if [ -n "$DISPLAY" ]; then
        cmdArray+=("--ro-bind" "/tmp/.X11-unix" "/tmp/.X11-unix" "--ro-bind" "$XAUTHORITY" "$XAUTHORITY" "--setenv" "DISPLAY" "$DISPLAY")
    fi
    if [ -e "$XDG_RUNTIME_DIR/pulse/native" ]; then
        cmdArray+=("--bind" "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse" "--setenv" "PULSE_SERVER" "$XDG_RUNTIME_DIR/pulse/native")
    fi
    local pwSockets=("$XDG_RUNTIME_DIR"/pipewire-*)
    pwSocket="${pwSockets[0]:-}"
    if [ -n "$pwSocket" ]; then
        cmdArray+=("--bind" "$pwSocket" "$pwSocket")
    fi
    if [ -e "/dev/ntsync" ]; then
        cmdArray+=("--dev-bind" "/dev/ntsync" "/dev/ntsync")
    fi
    for f in /dev/nvidia*; do
        cmdArray+=("--dev-bind" "$f" "$f")
    done
    if [ "$TDF_BLOCK_SHM" -eq 0 ]; then
        cmdArray+=("--dev-bind" "/dev/shm" "/dev/shm")
    fi
    if [ "$TDF_BLOCK_NATIVE_INPUT" -eq 0 ]; then
        cmdArray+=("--dev-bind" "/dev/input" "/dev/input")
    fi
    cmdArray+=("${_customMounts[@]}")
    local envNames=("${!_envs[@]}")
    for k in "${envNames[@]}"; do
        cmdArray+=("--setenv" "$k" "${_envs[$k]}")
    done
    for k in "${_unsets[@]}"; do
        cmdArray+=("--unsetenv" "$k")
    done
    sandboxMe=("$@")
    if [ "$TDF_BLOCK_NETWORK" -eq 0 ]; then
        cmdArray+=("--share-net")
    elif [ "$TDF_BLOCK_NETWORK" -eq 1 ]; then
        cmdArray+=("--unshare-net")
    elif [ "$TDF_BLOCK_NETWORK" -eq 2 ]; then
        cmdArray+=("--share-net")
        sandboxMe=("unshare" "-nc" "${sandboxMe[@]}")
    else
        fail "$(_loc "$TDF_LOCALE_INVALID_BLOCK_NETWORK")"
    fi
    if [ "$TDF_MANGOHUD" -eq 1 ]; then
        cmdArray=("${_mangohudCommand[@]}" "${cmdArray[@]}")
    fi
    if [ "$TDF_GAMESCOPE" -eq 1 ]; then
        cmdArray=("${_gamescopeCommand[@]}" "${cmdArray[@]}")
    fi
    cmdArray+=("--" "system/reaper/reaper" "--" "${sandboxMe[@]}")
    "${cmdArray[@]}"
}

function _initSandbox {
    _zenityProgressOutput "0" "$(_loc "$TDF_LOCALE_STARTINGWINE")"
    _checkOwner
    if ! _glibcSmokeTest; then
        fail "$(_loc "$TDF_LOCALE_GLIBC_WRONG")"
    fi
    if ! _bwrapSmokeTest; then
        fail "$(_loc "$TDF_LOCALE_BWRAP_FAIL")"
    fi
    if [[ -d "zzprefix" && ! -d "data" ]]; then
        fail "$(_loc "$TDF_LOCALE_CANTUPGRADE")"
    fi
    if [ ! -d "data/home" ]; then
        mkdir -p "data/home"
    fi
    if [ ! -d "$_tmpDir" ]; then
        mkdir "$_tmpDir"
    fi
    _findWine
    local realAllowHostAccess="$TDF_ALLOW_HOST_FILESYSTEM"
    local realBlockNetwork="$TDF_BLOCK_NETWORK"
    local realOverrides="$WINEDLLOVERRIDES"
    local realDebug="$WINEDEBUG"
    local realArch="$TDF_WINE_ARCH"
    TDF_ALLOW_HOST_FILESYSTEM=0
    TDF_BLOCK_NETWORK=1
    _removeWineMounts
    _envs["WINEDLLOVERRIDES"]="mscoree,mshtml=;winemenubuilder.exe=d"
    _envs["WINEDEBUG"]="-all"
    TDF_WINE_ARCH="win64"
    _applyWineArch
    _applyWineSync
    if [ ! -d "data/wineprefix" ]; then
        mkdir -p "data/wineprefix"
        runSandboxed "$_wineDir/wineboot" -i
    else
        runSandboxed "$_wineDir/wineboot"
    fi
    _removeWineMounts
    if ! _wineSmokeTest; then
        fail "$(runSandboxed "system/diagnoseBrokenWine.sh" "$_wineDir")"
    fi
    _zenityProgressOutput "30"
    _applyBlockBrowser
    _applyDLLs
    _zenityProgressOutput "40"
    _applyMSIs
    _zenityProgressOutput "60"
    _applyWinver
    _applyWineTheme
    _applyWineLanguage
    _applyScaling
    _applyWineDrivers
    _applyHideCrashes
    _applyCorefonts
    _zenityProgressOutput "70"
    _applyVCRedists
    _zenityProgressOutput "90"
    _envs["WINEDLLOVERRIDES"]="$realOverrides"
    if [ "$TDF_WINEMONO" -eq 0 ]; then
        _envs["WINEDLLOVERRIDES"]="${_envs["WINEDLLOVERRIDES"]};mscoree="
    fi
    if [ "$TDF_WINEGECKO" -eq 0 ]; then
        _envs["WINEDLLOVERRIDES"]="${_envs["WINEDLLOVERRIDES"]};mshtml="
    fi
    _envs["WINEDLLOVERRIDES"]="${_envs["WINEDLLOVERRIDES"]};winemenubuilder.exe=d"
    _checkPathsInPrefix
    _applyLibStrangle
    _applyDebugGStreamer
    _applyCPULimits
    _apply32bitOptimizations
    _prepareMangohudCommand
    _prepareGamescopeCommand
    TDF_ALLOW_HOST_FILESYSTEM="$realAllowHostAccess"
    TDF_BLOCK_NETWORK="$realBlockNetwork"
    _envs["WINEDEBUG"]="$realDebug"
    TDF_WINE_ARCH="$realArch"
    _removeWineMounts
    _prepareCustomMounts
    _applyFSR4
    _zenityProgressOutput "100"
    if [ "$TDF_WINE_DEBUG_RELAY" -eq 1 ]; then
        local relayPath=$(zenity --file-selection --save --title="$(_loc "$TDF_LOCALE_WINE_RELAYPATH")" --filename="relay.txt")
        if [ -n "$relayPath" ]; then
            _envs["WINEDEBUG"]="${_envs["WINEDEBUG"]},+relay"
            if [[ -w "$relayPath" || -w "$(dirname "$relayPath")" ]]; then
                _relayPath="$relayPath"
            else
                fail "$(_loc "$TDF_LOCALE_WINE_RELAYPATH_UNWRITABLE")"
            fi
        fi
    fi
}

function _checkOwner {
    if [ -d "data" ]; then
        if [ "$(stat -c %u "data")" != "$UID" ]; then
            fail "$(_loc "$TDF_LOCALE_NOTYOURSANDBOX")"
        fi
    fi
}

function _checkPathsInPrefix {
    if [ -n "$game_exe" ]; then
        game_workingDir="${game_workingDir//\//\\}"
        game_exe="${game_exe//\//\\}"
        if [ -z "$game_workingDir" ]; then
            game_workingDir="${game_exe%\\*}"
        fi
        if [[ ${#game_args[@]} -ne 0 ]]; then
            if [[ "$(declare -p game_args)" =~ "declare -a" ]]; then
                readarray -t game_args < <(printf '%s' "game_args" | xargs -n1)
            fi
        fi
        if [ "$TDF_IGNORE_EXIST_CHECKS" -ne 1 ]; then
            local pathInSandbox=""
            if [[ "$game_exe" =~ ^[A-Z,a-z]:.*$ ]]; then
                pathInSandbox="$(runSandboxed "$_wineDir/winepath" "$game_exe" 2>/dev/null)"
            else
                pathInSandbox="$(runSandboxed "$_wineDir/winepath" "$game_workingDir\\$game_exe" 2>/dev/null)"
            fi
            local result="$(runSandboxed test -e "$pathInSandbox" ; echo $?)"
            if [ "$result" -ne 0 ]; then
                fail "$(_loc "$TDF_LOCALE_EXENOTFOUND")"
            fi
        fi
    fi
}

function _bwrapSmokeTest {
    if ! bwrap --die-with-parent --ro-bind "/" "/" -- true > /dev/null 2>&1; then #should succeed
        return 1
    fi
    if bwrap --die-with-parent --ro-bind "/" "/" -- touch "/tdftest-$RANDOM" > /dev/null 2>&1; then #should fail
        return 2
    fi
    return 0
}

function _glibcSmokeTest {
    if [ "$(system/tdfutils/glibcsmoke64)" != "OK" ]; then
        return 1
    fi
    return 0
}

function _findWine {
    local sysWine="$(command -v wine)"
    if [ "$TDF_WINE_PREFERRED_VERSION" = "system" ]; then
        if [ -n "$sysWine" ]; then
            _wineDir="$(dirname "$sysWine")"
        elif [ -e "system/wine-mainline/bin/wine" ]; then
            _wineDir="/tdf/system/wine-mainline/bin"
        else
            fail "$(_loc "$TDF_LOCALE_WINE_NOTINPATH")"
        fi
    elif [[ "$TDF_WINE_PREFERRED_VERSION" = "games" || "$TDF_WINE_PREFERRED_VERSION" = "mainline" ]]; then
        if [ -e "system/wine-$TDF_WINE_PREFERRED_VERSION/bin/wine" ]; then
            _wineDir="/tdf/system/wine-$TDF_WINE_PREFERRED_VERSION/bin"
        else
            if [ -n "$sysWine" ]; then
                _wineDir="$(dirname "$sysWine")"
            else
                fail "$(_loc "$TDF_LOCALE_WINE_NOTINPATH")"
            fi
        fi
    else
        if [ -e "wine-$TDF_WINE_PREFERRED_VERSION" ]; then
            _wineDir="/tdf/wine-$TDF_WINE_PREFERRED_VERSION/bin"
        else
            if [ -n "$sysWine" ]; then
                _wineDir="$(dirname "$sysWine")"
            else
                fail "$(_loc "$TDF_LOCALE_WINE_NOTINPATH")"
            fi
        fi
    fi
}

function _wineSmokeTest {
    if [ "$TDF_WINE_SMOKETEST" -eq 0 ]; then
        return 0
    fi
    if [ -d "data/wineprefix/drive_c" ]; then
        if [ -e "data/wineprefix/drive_c/smoke.txt" ]; then
            rm -f "data/wineprefix/drive_c/smoke.txt"
        fi
        \cp "system/tdfutils/winesmoke32.exe" "data/wineprefix/drive_c/"
        local r=$RANDOM
        runSandboxed "$_wineDir/wine" 'C:\winesmoke32.exe' $r
        rm -f "data/wineprefix/drive_c/winesmoke32.exe"
        if [ -e "data/wineprefix/drive_c/smoke.txt" ]; then
            local out=$(cat "data/wineprefix/drive_c/smoke.txt")
            rm -f "data/wineprefix/drive_c/smoke.txt"
            if [ "$out" != "$r" ]; then
                return 2
            fi
            if [ "$TDF_WINE_ARCH" = "wow64" ]; then
                return 0
            fi
            \cp "system/tdfutils/winesmoke64.exe" "data/wineprefix/drive_c/"
            runSandboxed "$_wineDir/wine" 'C:\winesmoke64.exe' $r
            rm -f "data/wineprefix/drive_c/winesmoke64.exe"
            if [ -e "data/wineprefix/drive_c/smoke.txt" ]; then
                out=$(cat "data/wineprefix/drive_c/smoke.txt")
                rm -f "data/wineprefix/drive_c/smoke.txt"
                if [ "$out" != "$r" ]; then
                    return 3
                fi
            fi
        fi
    else
        return 1
    fi
    return 0
}

function _applyWineSync {
    "system/tdfutils/synctest"
    local support=$?
    if [ -n "$TDF_WINE_SYNC" ]; then
        if [ "$TDF_WINE_SYNC" = "fsync" ]; then
            if [ $support -ge 1 ]; then
                if [ "$TDF_BLOCK_SHM" -ne 0 ]; then
                    fail "$(_loc "$TDF_LOCALE_FSYNCSHM")"
                fi
                _envs["WINEFSYNC"]=1
                _envs["WINEESYNC"]=0
            else
                _envs["WINEFSYNC"]=0
                _envs["WINEESYNC"]=1
            fi
        elif [ "$TDF_WINE_SYNC" = "esync" ]; then
            _envs["WINEFSYNC"]=0
            _envs["WINEESYNC"]=1
        else
            _unsets+=("WINEFSYNC" "WINEESYNC")
        fi
    else
        if [ $support -lt 2 ]; then
            _zenityWarn "$(_loc "$TDF_LOCALE_NONTSYNC")"
        fi
    fi
    #ntsync requires no special treatment, can't be forced, and it's active by default
}

function _applyWineArch {
    if [[ "$TDF_WINE_ARCH" = "win64" || "$TDF_WINE_ARCH" = "win32" || "$TDF_WINE_ARCH" = "wow64" ]]; then
        if [ "$TDF_WINE_ARCH" = "win32" ]; then
            TDF_WINE_ARCH="wow64"
        fi
        _envs["WINEARCH"]="$TDF_WINE_ARCH"
    else
        fail "$(_loc "$TDF_LOCALE_WINE_INVALIDARCH")"
    fi
}

function _applyWinver {
    if [ -n "$TDF_WINE_WINVER" ]; then
        case "$TDF_WINE_WINVER" in
            win11|win10|win81|win8|win2008r2|win7|win2008|vista|win2003|winxp64|winxp|win2k|winme|win98|win95|nt40|nt351|win31|win30|win20)
                runSandboxed "$_wineDir/winecfg" -v "$TDF_WINE_WINVER"
                ;;
            *)
                fail "$(_loc "$TDF_LOCALE_WINE_WINVER_INVALID")"
                ;;
        esac
    fi
}

function _applyWineTheme {
    local themes_dir="system/themes"
    if [ -d "$themes_dir" ]; then
        if [ -n "$TDF_WINE_THEME" ]; then
            if [ -e "$themes_dir/$TDF_WINE_THEME.reg" ]; then
                \cp "$themes_dir/$TDF_WINE_THEME.reg" "data/wineprefix/drive_c/theme.reg"
                runSandboxed "$_wineDir/wine" reg import "C:\\theme.reg"
                rm -f "data/wineprefix/drive_c/theme.reg"
            else
                fail "$(_loc "$TDF_LOCALE_WINE_THEME_NOTFOUND")"
            fi
        fi
    fi
}

function _applyWineLanguage {
    if [ -n "$TDF_WINE_LANGUAGE" ]; then
        _envs["LANG"]="$TDF_WINE_LANGUAGE"
        _envs["LC_ALL"]="$TDF_WINE_LANGUAGE"
    fi
}

function _applyScaling {
    if [ "$TDF_WINE_DPI" -eq -1 ]; then
        TDF_WINE_DPI=$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)
    fi
    if [ "$TDF_WINE_DPI" -ne 0 ]; then
        local currentDpi=0
        if [ -e "data/.dpi" ]; then
            currentDpi=$(cat "data/.dpi")
        fi
        if [ "$TDF_WINE_DPI" != "$currentDpi" ]; then
            runSandboxed "$_wineDir/wine" reg add 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /t REG_DWORD /d "$TDF_WINE_DPI" /f
            runSandboxed "$_wineDir/wine" reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /t REG_DWORD /d "$TDF_WINE_DPI" /f
            echo "$TDF_WINE_DPI" > "data/.dpi"
        fi
    else
        if [ -e "data/.dpi" ]; then
            runSandboxed "$_wineDir/wine" reg delete 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /f
            runSandboxed "$_wineDir/wine" reg delete 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /f
            rm -f "data/.dpi"
        fi
    fi
}

function _applyCorefonts {
    local windows_dir="data/wineprefix/drive_c/windows"
    local corefonts_dir="system/corefonts"
    if [ -d "$corefonts_dir" ]; then
        if [ "$TDF_COREFONTS" -eq 1 ]; then
            if [ ! -e "data/.corefonts-installed" ]; then
                for f in "$corefonts_dir"/*; do
                    \cp -f "$f" "$windows_dir/Fonts"
                done
                touch "data/.corefonts-installed"
            fi
        else
            if [ -e "data/.corefonts-installed" ]; then
                for f in "$corefonts_dir/"*; do
                    rm -f "$windows_dir/Fonts/${f##*/}"
                done
                rm -f "data/.corefonts-installed"
            fi
        fi
    fi
}

function _applyWineDrivers {
    if [ "$TDF_WINE_AUDIO_DRIVER" != "default" ]; then
        runSandboxed "$_wineDir/wine" reg add 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Audio' /t REG_SZ /d "$TDF_WINE_AUDIO_DRIVER" /f
    else
        runSandboxed "$_wineDir/wine" reg delete 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Audio' /f
    fi
    if [ "$TDF_HDR" -eq 1 ]; then
            TDF_WINE_GRAPHICS_DRIVER="wayland"
            export ENABLE_HDR_WSI=1
            _envs["DXVK_HDR"]=1
    else
        if [ "$TDF_WINE_GRAPHICS_DRIVER" == "auto" ]; then
            if [ -n "$WAYLAND_DISPLAY" ]; then
                TDF_WINE_GRAPHICS_DRIVER="wayland"
            elif [ -n "$DISPLAY" ]; then
                TDF_WINE_GRAPHICS_DRIVER="x11"
            else
                TDF_WINE_GRAPHICS_DRIVER="default"
            fi
        fi
    fi
    if [ "$TDF_WINE_GRAPHICS_DRIVER" != "default" ]; then
        runSandboxed "$_wineDir/wine" reg add 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Graphics' /t REG_SZ /d "$TDF_WINE_GRAPHICS_DRIVER" /f
    else
        runSandboxed "$_wineDir/wine" reg delete 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Graphics' /f
    fi
}

function _applyHideCrashes {
    if [ "$TDF_WINE_HIDE_CRASHES" -eq 1 ]; then
        if [ ! -e "data/.crash-hidden" ]; then
            runSandboxed "$_wineDir/wine" reg add 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
            touch "data/.crash-hidden"
        fi
    else
        if [ -e "data/.crash-hidden" ]; then
            runSandboxed "$_wineDir/wine" reg delete 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /f
            rm -f "data/.crash-hidden"
        fi
    fi
}

function _applyDLLs {
    if [[ "$TDF_DXVK_NVAPI" -eq 1 && "$TDF_DXVK" -eq 0 ]]; then
        _zenityWarn "$(_loc "$TDF_LOCALE_NVAPI_NEEDS_DXVK")"
        TDF_DXVK=1
    fi
    if [[ "$TDF_VKD3D" -eq 1 && "$TDF_DXVK" -eq 0 ]]; then
        _zenityWarn "$(_loc "$TDF_LOCALE_VKD3D_NEEDS_DXVK")"
        TDF_DXVK=1
    fi
    if [[ "$TDF_D7VK" -eq 1 && "$TDF_DXVK" -eq 0 ]]; then
        _zenityWarn "$(_loc "$TDF_LOCALE_D7VK_NEEDS_DXVK")"
        TDF_DXVK=1
    fi
    "system/tdfutils/vkgpltest"
    local ok=$?
    if [ $ok -eq 0 ]; then
        fail "$(_loc "$TDF_LOCALE_NOVULKAN")"
    elif [ $ok -eq 1 ]; then
        _zenityWarn "$(_loc "$TDF_LOCALE_NOVULKANGPL")"
    fi
    local windows_dir="data/wineprefix/drive_c/windows"
    local dxvk_dir="system/dxvk"
    local dxvk_dlls=("d3d8" "d3d9" "d3d10" "d3d10_1" "d3d10core" "d3d11" "dxgi" "dxvk_config") #note: some files here may not exist, they are here so that overrides are added, which are useful for mods and older versions of dxvk
    local dxvknvapi_dir="system/dxvk-nvapi"
    local dxvknvapi_dlls=("nvapi" "nvapi64")
    local vkd3d_dir="system/vkd3d"
    local vkd3d_dlls=("d3d12" "d3d12core")
    local d7vk_dir="system/d7vk"
    local d7vk_dlls=("ddraw")
    local toOverride=()
    local toUnoverride=()
    if [ -d "$dxvk_dir" ]; then
        if [ "$TDF_DXVK" -eq 1 ]; then
            for d in "${dxvk_dlls[@]}"; do
                copyIfDifferent "$dxvk_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
                copyIfDifferent "$dxvk_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
            done
            if [ ! -e "data/.dxvk-installed" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "data/.dxvk-installed"
            fi
            if [ "$TDF_DXVK_NVAPI" -eq 1 ]; then
                for d in "${dxvknvapi_dlls[@]}"; do
                    copyIfDifferent "$dxvknvapi_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
                    copyIfDifferent "$dxvknvapi_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
                done
                if [ ! -e "data/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        toOverride+=("$d")
                    done
                    touch "data/.dxvknvapi-installed"
                fi
            else
                if [ -e "data/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        rm -f "$windows_dir/system32/$d.dll"
                        rm -f "$windows_dir/syswow64/$d.dll"
                        toUnoverride+=("$d")
                    done
                    runSandboxed "$_wineDir/wineboot" -u
                    rm -f "data/.dxvknvapi-installed"
                fi
            fi
        else
            if [ -e "data/.dxvk-installed" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                rm -f "data/.dxvk-installed"
                if [ -e "data/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        rm -f "$windows_dir/system32/$d.dll"
                        rm -f "$windows_dir/syswow64/$d.dll"
                        toUnoverride+=("$d")
                    done
                    rm -f "data/.dxvknvapi-installed"
                fi
                runSandboxed "$_wineDir/wineboot" -u
            fi
        fi
    fi
    if [ -d "$d7vk_dir" ]; then
        if [ "$TDF_D7VK" -eq 1 ]; then
            for d in "${d7vk_dlls[@]}"; do
                copyIfDifferent "$d7vk_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
            done
            if [ ! -e "data/.d7vk-installed" ]; then
                for d in "${d7vk_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "data/.d7vk-installed"
            fi
        else
            if [ -e "data/.d7vk-installed" ]; then
                for d in "${d7vk_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                runSandboxed "$_wineDir/wineboot" -u
                rm -f "data/.d7vk-installed"
            fi
        fi
    fi
    if [ -d "$vkd3d_dir" ]; then
        if [ "$TDF_VKD3D" -eq 1 ]; then
            for d in "${vkd3d_dlls[@]}"; do
                copyIfDifferent "$vkd3d_dir/x86/$d.dll" "$windows_dir/syswow64/$d.dll"
                copyIfDifferent "$vkd3d_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
            done
            if [ ! -e "data/.vkd3d-installed" ]; then
                for d in "${vkd3d_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "data/.vkd3d-installed"
            fi
        else
            if [ -e "data/.vkd3d-installed" ]; then
                for d in "${vkd3d_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                runSandboxed "$_wineDir/wineboot" -u
                rm -f "data/.vkd3d-installed"
            fi
        fi
    fi
    local tempBat="data/wineprefix/drive_c/temp_overrides.bat"
    local hasCommands=0
    for d in "${toUnoverride[@]}"; do
        echo "reg delete \"HKEY_CURRENT_USER\Software\Wine\DllOverrides\" /v \"$d\" /f" >> "$tempBat"
        hasCommands=1
    done
    for d in "${toOverride[@]}"; do
        echo "reg add \"HKEY_CURRENT_USER\Software\Wine\DllOverrides\" /v \"$d\" /d \"native,builtin\" /f" >> "$tempBat"
        hasCommands=1
    done
    if [ $hasCommands -eq 1 ]; then
        runSandboxed "$_wineDir/wine" "cmd" "/c" "C:\\temp_overrides.bat"
        rm -f "$tempBat"
    fi
}

function _applyMSIs {
    local msi_dir="system/msi"
    if [ -d "$msi_dir" ]; then
        function installMonoMSI {
            \cp "$msi_dir/winemono.msi" "data/wineprefix/drive_c/winemono.msi"
            runSandboxed "$_wineDir/wine" msiexec /i "C:\\winemono.msi"
            echo "$TDF_VERSION" > "data/.winemono-installed"
        }
        function uninstallMonoMSI {
            runSandboxed "$_wineDir/wine" msiexec /uninstall "C:\\winemono.msi"
            rm -f "data/.winemono-installed"
            rm -f "data/wineprefix/drive_c/winemono.msi"
        }
        if [ "$TDF_WINEMONO" -eq 1 ]; then
            if [ ! -e "data/.winemono-installed" ]; then
                installMonoMSI
            else
                if ! cmp "$msi_dir/winemono.msi" "data/wineprefix/drive_c/winemono.msi" > /dev/null 2>&1; then
                    \cp "$msi_dir/winemono.msi" "data/wineprefix/drive_c/winemono.msi"
                    uninstallMonoMSI
                    installMonoMSI
                fi
            fi
        else
            if [ -e "data/.winemono-installed" ]; then
                uninstallMonoMSI
            fi
        fi
        function installGeckoMSI {
            \cp "$msi_dir/winegecko32.msi" "data/wineprefix/drive_c/winegecko32.msi"
            runSandboxed "$_wineDir/wine" msiexec /i "C:\\winegecko32.msi"
            \cp "$msi_dir/winegecko64.msi" "data/wineprefix/drive_c/winegecko64.msi"
            runSandboxed "$_wineDir/wine" msiexec /i "C:\\winegecko64.msi"
            echo "$TDF_VERSION" > "data/.winegecko-installed"
        }
        function uninstallGeckoMSI {
            runSandboxed "$_wineDir/wine" msiexec /uninstall "C:\\winegecko32.msi"
            runSandboxed "$_wineDir/wine" msiexec /uninstall "C:\\winegecko64.msi"
            rm -f "data/.winegecko-installed"
            rm -f "data/wineprefix/drive_c/winegecko32.msi"
            rm -f "data/wineprefix/drive_c/winegecko64.msi"
        }
        if [ "$TDF_WINEGECKO" -eq 1 ]; then
            if [ ! -e "data/.winegecko-installed" ]; then
                installGeckoMSI
            else
                local mustUpdate=0
                if ! cmp "$msi_dir/winegecko32.msi" "data/wineprefix/drive_c/winegecko32.msi" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if ! cmp "$msi_dir/winegecko64.msi" "data/wineprefix/drive_c/winegecko64.msi" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if [ $mustUpdate -eq 1 ]; then
                    uninstallGeckoMSI
                    installGeckoMSI
                fi
            fi
        else
            if [ -e "data/.winegecko-installed" ]; then
                uninstallGeckoMSI
            fi
        fi
    fi
}

function _applyVCRedists {
    local vc_dir="system/vcredist"
    if [ -d "$vc_dir" ]; then
        function installVCRedists {
            \cp "$vc_dir/vc_redist.x86.exe" "data/wineprefix/drive_c/vc_redist.x86.exe"
            \cp "$vc_dir/vc_redist.x64.exe" "data/wineprefix/drive_c/vc_redist.x64.exe"
            runSandboxed "$_wineDir/wine" "C:\\vc_redist.x86.exe" /install /quiet /norestart
            runSandboxed "$_wineDir/wine" "C:\\vc_redist.x64.exe" /install /quiet /norestart
            echo "$TDF_VERSION" > "data/.vcredist-installed"
        }
        function uninstallVCRedists {
            runSandboxed "$_wineDir/wine" "C:\\vc_redist.x86.exe" /uninstall /quiet /norestart
            runSandboxed "$_wineDir/wine" "C:\\vc_redist.x64.exe" /uninstall /quiet /norestart
            rm -f "data/.vcredist-installed"
            rm -f "data/wineprefix/drive_c/vc_redist.x86.exe"
            rm -f "data/wineprefix/drive_c/vc_redist.x64.exe"
        }
        if [ "$TDF_VCREDIST" -eq 1 ]; then
            if [ ! -e "data/.vcredist-installed" ]; then
                installVCRedists
            else
                local mustUpdate=0
                if ! cmp "$vc_dir/vc_redist.x86.exe" "data/wineprefix/drive_c/vc_redist.x86.exe" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if ! cmp "$vc_dir/vc_redist.x64.exe" "data/wineprefix/drive_c/vc_redist.x64.exe" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if [ $mustUpdate -eq 1 ]; then
                    uninstallVCRedists
                    installVCRedists
                fi
            fi
        else
            if [ -e "data/.vcredist-installed" ]; then
                uninstallVCRedists
            fi
        fi
    fi
}

function _applyLibStrangle {
    if [ -d "system/strangle" ]; then
        if [ "$TDF_GL_MAXFPS" -ne 0 ]; then
            _envs["LD_PRELOAD"]="${_envs["LD_PRELOAD"]}:/tdf/system/strangle/libstrangle64.so:/tdf/system/strangle/libstrangle32.so"
            _envs["STRANGLE_FPS"]="$TDF_GL_MAXFPS"
        fi
    fi
}

function _applyDebugGStreamer {
    if [ "$TDF_WINE_DEBUG_GSTREAMER" -eq 1 ]; then
        _envs["GST_DEBUG_NO_COLOR"]="1"
        _envs["GST_DEBUG"]="4,WINE:9"
    fi
}

function _applyBlockBrowser {
    copyIfDifferent "system/tdfutils/winebrowser.exe" "data/wineprefix/drive_c/windows/system32/winebrowser.exe"
    copyIfDifferent "system/tdfutils/winebrowser.exe" "data/wineprefix/drive_c/windows/syswow64/winebrowser.exe"
}

function _prepareMangohudCommand {
    if [ "$TDF_MANGOHUD" -eq 1 ]; then
        if command -v mangohud > /dev/null; then
            _mangohudCommand=("mangohud")
        else
            _zenityWarn "$(_loc "$TDF_LOCALE_MANGOHUD_MISSING")"
            _mangohudCommand=()
        fi
    else
        _mangohudCommand=()
    fi
}

function _prepareGamescopeCommand {
    if [ "$TDF_GAMESCOPE" -eq 1 ]; then
        if command -v gamescope > /dev/null; then
            _gamescopeCommand=("gamescope")
            if [ "$TDF_MANGOHUD" -eq 1 ]; then
                _mangohudCommand=()
                _gamescopeCommand+=("--mangoapp")
            fi
            if [[ "$(declare -p TDF_GAMESCOPE_PARAMETERS)" =~ "declare -a" ]]; then
                _gamescopeCommand+=("${TDF_GAMESCOPE_PARAMETERS[@]}")
            else
                if [ -n "$TDF_GAMESCOPE_PARAMETERS" ]; then
                    readarray -t TDF_GAMESCOPE_PARAMETERS < <(printf '%s' "$TDF_GAMESCOPE_PARAMETERS" | xargs -n1)
                else
                    TDF_GAMESCOPE_PARAMETERS=("-f" "-r" "60" "-w" "$XRES" "-h" "$YRES")
                fi
                _gamescopeCommand+=("${TDF_GAMESCOPE_PARAMETERS[@]}")
            fi
            if [ "$TDF_HDR" -eq 1 ]; then
                _gamescopeCommand+=("--hdr-enabled")
            fi
            _gamescopeCommand+=("--")
        else
            _zenityWarn "$(_loc "$TDF_LOCALE_GAMESCOPE_MISSING")"
            _gamescopeCommand=()
        fi
    else
        _gamescopeCommand=()
    fi
}

function _apply32bitOptimizations {
    if [ "$TDF_WINE_LAA" -eq 1 ]; then
        _envs["WINE_LARGE_ADDRESS_AWARE"]=1
    fi
    if [ "$TDF_WINE_HEAP_DELAY_FREE" -eq 1 ]; then
        _envs["WINE_HEAP_DELAY_FREE"]=1
    fi
}

function _removeWineMounts {
    find "data/wineprefix/dosdevices" -maxdepth 1 -type l ! -name "c:" -print0 | xargs -0 -r rm -f
}

function _prepareCustomMounts {
    local usedLetters=("c")
    if [ "$TDF_ALLOW_HOST_FILESYSTEM" -eq 1 ]; then
        TDF_CUSTOM_MOUNTS=("${TDF_CUSTOM_MOUNTS[@]}" "h:ro:/")
    elif [ "$TDF_ALLOW_HOST_FILESYSTEM" -eq 2 ]; then
        if [ -z "$game_exe" ]; then
            TDF_CUSTOM_MOUNTS=("${TDF_CUSTOM_MOUNTS[@]}" "h:ro:/")
        fi
    elif [ "$TDF_ALLOW_HOST_FILESYSTEM" -eq 3 ]; then
        TDF_CUSTOM_MOUNTS=("${TDF_CUSTOM_MOUNTS[@]}" "h:rw:/")
    elif [ "$TDF_ALLOW_HOST_FILESYSTEM" -ne 0 ]; then
        fail "$(_loc "$TDF_LOCALE_INVALID_ALLOW_HOST_FILESYSTEM")"
    fi
    for m in "${TDF_CUSTOM_MOUNTS[@]}"; do
        IFS=':' read -ra parts <<< "$m"
        local letter="${parts[0]}"
        letter="${letter,,}"
        if [[ "${#letter}" -ne 1 || ! "$letter" =~ ^[a-z]$ ]]; then
            fail "$(_loc "$TDF_LOCALE_CUSTOMMOUNTS_INVALIDLETTER")"
        fi
        if contains "$letter" "${usedLetters[@]}"; then
            fail "$(_loc "$TDF_LOCALE_CUSTOMMOUNTS_LETTERALREADYUSED")"
        fi
        if [ ${#parts[@]} -eq 3 ]; then
            local hostPath="${parts[2]}"
            if [ -d "$hostPath" ]; then
                local access="${parts[1]}"
                if [ "$access" == "ro" ]; then
                    _customMounts+=("--ro-bind" "$hostPath" "/customMounts/$letter" "--symlink" "/customMounts/$letter" "/tdf/data/wineprefix/dosdevices/$letter:")
                elif [ "$access" == "rw" ]; then
                    _customMounts+=("--bind" "$hostPath" "/customMounts/$letter" "--symlink" "/customMounts/$letter" "/tdf/data/wineprefix/dosdevices/$letter:")
                else
                    fail "$(_loc "$TDF_LOCALE_CUSTOMMOUNTS_INVALIDACCESSLEVEL")"
                fi
            else
                fail "$(_loc "$TDF_LOCALE_CUSTOMMOUNTS_CANTMOUNT")"
            fi
        elif [ ${#parts[@]} -eq 1 ]; then
            if [ ! -d "data/$letter" ]; then
                mkdir "data/$letter"
            fi
            _customMounts+=("--bind" "$PWD/data/$letter" "/customMounts/$letter" "--symlink" "/customMounts/$letter" "/tdf/data/wineprefix/dosdevices/$letter:")
        else
            fail "$(_loc "$TDF_LOCALE_CUSTOMMOUNTS_INVALID")"
        fi
        usedLetters+=("$letter")
    done
}

function _applyFSR4 {
    if [ -e "system/fsr4" ]; then
        if [[ -z "$FSR4_UPGRADE" && "$FSR4_UPGRADE" -eq 1 ]]; then
            copyIfDifferent "system/fsr4/amdxcffx64.dll" "data/wineprefix/drive_c/windows/system32/amdxcffx64.dll"
        else
            rm -f "data/wineprefix/drive_c/windows/system32/amdxcffx64.dll"
        fi
    fi
}

function _applyCPULimits {
    #if the topology is already set by the user, or no settings were changed, do nothing
    if [ -n "$WINE_CPU_TOPOLOGY" ]; then
        return
    fi
    if [[ "$TDF_WINE_MAXLOGICALCPUS" -eq 0 && "$TDF_WINE_NOSMT" -eq 0 && "$TDF_WINE_NOECORES" -eq 0 && "$TDF_WINE_PREFER_SAMESOCKET" -eq 0 ]]; then
        return
    fi
    if ! command -v lscpu > /dev/null; then
        echo "WARNING: lscpu is missing, can't decide CPU topology"
        return
    fi
    local topology=""
    local data=(); local ci=(); local cj=(); local b=(); local c=(); local mi=(); local mj=();
    #fetch CPU topology
    readarray -t data < <(lscpu --all --e=cpu,socket,core,maxmhz|tail -n +2)
    local nCPUs=${#data[@]} #number of logical CPUs in the machine
    #if the number of logical CPUs doesn't exceed TDF_WINE_MAXLOGICALCPUS, do nothing. Continue if TDF_WINE_MAXLOGICALCPUS is set to -1 (force limits even when not necessary)
    if [[ "$nCPUs" -le "$TDF_WINE_MAXLOGICALCPUS" ]]; then
        return
    fi
    #if TDF_WINE_PREFER_SAMESOCKET is set to 2, exclude all logical CPUs from CPUs except for the one in socket 0
    if [ "$TDF_WINE_PREFER_SAMESOCKET" -eq 2 ]; then
        for ((i=0; i<${#data[@]}; ++i)) ; do
            if [ -n "${data[i]}" ]; then
                read -r -a c <<< "${data[i]}"
                if [ "${c[1]}" != "0" ]; then
                    data[i]=""
                fi
            fi
        done
    fi
    #if TDF_WINE_NOSMT is enabled, keep only one logical CPU per physical core. The order of the logical CPUs in lscpu is not guaranteed so we have to do it the dumb way
    if [ "$TDF_WINE_NOSMT" -eq 1 ]; then
        for ((i=0; i<${#data[@]}; ++i)) ; do
            read -r -a ci <<< "${data[i]}"
            if [ -n "${data[i]}" ]; then
                for ((j=i+1; j<${#data[@]}; ++j)); do
                    read -r -a cj <<< "${data[j]}"
                    if [ "${ci[2]}" == "${cj[2]}" ]; then
                        data[j]=""
                    fi
                done
            fi
        done
    fi
    #there is no easy way to identify e-cores on intel, so if TDF_WINE_NOECORES is enabled, exclude all cores whose maximum frequency is <75% than the frequency of any other core of the same CPU
    if [ "$TDF_WINE_NOECORES" -ge 1 ]; then
        for ((i=0; i<${#data[@]}; ++i)) ; do
            if [ -n "${data[i]}" ]; then
                read -r -a ci <<< "${data[i]}"
                IFS="." read -r -a mi <<< "${ci[3]}"
                mhzi="${mi[0]}"
                mhzi=$(((75*mhzi)/100))
                if [ -n "${data[i]}" ]; then
                    for ((j=i+1; j<${#data[@]}; ++j)); do
                        if [ -n "${data[j]}" ]; then
                            read -r -a cj <<< "${data[j]}"
                            if [[ "${ci[1]}" == "${cj[1]}" ]]; then
                                IFS="." read -r -a mj <<< "${cj[3]}"
                                mhzj="${mj[0]}"
                                if [ "$mhzj" -lt "$mhzi" ]; then
                                    data[j]=""
                                fi
                            fi
                        fi
                    done
                fi
            fi
        done
    fi
    #sort the logical CPUs by "desirability", this is a bit complicated...
    local sortedCores=()
    #first, take the first logical CPU of each core. This includes e-cores, because it's better to assign work to a free e-core than to the second thread of a p-core
    for ((i=0; i<${#data[@]}; ++i)) ; do
        if [ -n "${data[i]}" ]; then
            read -r -a c <<< "${data[i]}"
            local addC=1
            for ((j=0; j<${#sortedCores[@]}; ++j)) ; do
                read -r -a b <<< "${sortedCores[j]}"
                if [[ "${b[1]}" == "${c[1]}" && "${b[2]}" == "${c[2]}" ]]; then
                    addC=0
                    break
                fi
            done
            if [ $addC -eq 1 ]; then
                sortedCores+=("${data[i]}")
                data[i]=""
            fi
        fi
    done
    #now sort the list by frequency desc
    for ((i=0; i<${#sortedCores[@]}-1; ++i)) ; do
        for ((j=i+1; j<${#sortedCores[@]}; ++j)) ; do
            read -r -a ci <<< "${sortedCores[i]}"
            IFS="." read -r -a mi <<< "${ci[3]}"
            local mhzi="${mi[0]}"
            read -r -a cj <<< "${sortedCores[j]}"
            IFS="." read -r -a mj <<< "${cj[3]}"
            local mhzj="${mj[0]}"
            if [ "$mhzi" -lt "$mhzj" ]; then
                temp="${sortedCores[j]}"
                sortedCores[j]="${sortedCores[i]}"
                sortedCores[i]="$temp"
            fi
        done
    done
    #then add the remaining, less desirable cores
    for ((i=0; i<${#data[@]}; ++i)) ; do
        if [ -n "${data[i]}" ]; then
            sortedCores+=("${data[i]}")
        fi
    done
    #finally, if TDF_WINE_PREFER_SAMESOCKET is set to 1, sort the list by socket id, giving priority to all the logical CPUs in the first socket, then the second socket, and so on
    if [ "$TDF_WINE_PREFER_SAMESOCKET" -eq 1 ]; then
        for ((i=0; i<${#sortedCores[@]}-1; ++i)) ; do
            for ((j=i+1; j<${#sortedCores[@]}; ++j)) ; do
                read -r -a ci <<< "${sortedCores[i]}"
                read -r -a cj <<< "${sortedCores[j]}"
                if [ "${ci[1]}" -gt "${cj[1]}" ]; then
                    temp="${sortedCores[j]}"
                    sortedCores[j]="${sortedCores[i]}"
                    sortedCores[i]="$temp"
                fi
            done
        done
    fi
    #at this point, sortedCores has a list of all the logical CPUs in the machine sorted by how much we like them and we start assigning them one by one until we reach TDF_WINE_MAXLOGICALCPUS
    local n=0
    for ((i=0; i<${#sortedCores[@]}; ++i)) ; do
        if [[ "$TDF_WINE_MAXLOGICALCPUS" -gt 0 && $n -ge "$TDF_WINE_MAXLOGICALCPUS" ]]; then
            break
        fi
        read -r -a c <<< "${sortedCores[i]}"
        if [ -n "$topology" ]; then
            topology="$topology,${c[0]}"
        else
            topology="${c[0]}"
        fi
        ((n++))
    done
    #failsafe: make sure that the number of assigned logical CPUs is >0 and <=nCPUs in the machine. If this is true, set the topology, otherwise do nothing
    if [[ $n -gt 0 && $n -le $nCPUs ]]; then
        _envs["WINE_CPU_TOPOLOGY"]="$n:$topology"
    else
        unset "_envs[WINE_CPU_TOPOLOGY]"
    fi
}

_dndPid=-1
function _applyDND {
    if [ $TDF_DND -eq 1 ]; then
        "system/tdfutils/dnd" &
        _dndPid=$!
    fi
}
function _clearDND {
    if [ $_dndPid -ne -1 ]; then
        kill $_dndPid
        _dndPid=-1
    fi
}

_nosleepPid=-1
function _applyNoSleep {
    if [ $TDF_NOSLEEP -eq 1 ]; then
        "system/tdfutils/nosleep" &
        _nosleepPid=$!
    fi
}
function _clearNoSleep {
    if [ $_nosleepPid -ne -1 ]; then
        kill $_nosleepPid
        _nosleepPid=-1
    fi
}

function _waitSubshellTermination {
    local subshellPid=$1
    local text="$2"
    if [ "$TDF_HIDE_GAME_RUNNING_DIALOG" -eq 0 ]; then
        zenity --title="$TDF_TITLE" --info --text="$text" --ok-label="$(_loc "$TDF_LOCALE_FORCESTOP")" --width=250 --icon="system/zenity/running.png" &
        local zenityPid=$!
        while true; do
            #shellcheck disable=SC2086
            if ! kill -0 $subshellPid 2>/dev/null; then
                if kill -0 $zenityPid 2>/dev/null; then
                    kill $zenityPid
                fi
                break
            fi
            if ! kill -0 $zenityPid 2>/dev/null; then
                #shellcheck disable=SC2086
                kill $subshellPid
                break
            fi
            sleep 0.5
        done
    else
        #shellcheck disable=SC2086
        wait $subshellPid
    fi
}

winebrowserPid=-1
function _startWinebrowserBridge {
    (
        rm -f "$_tmpDir/winebrowser-"*
        while true; do
            for f in "$_tmpDir/winebrowser-"*; do
                local link="$(cat "$f")"
                if [[ "${link,,}" =~ ^https?:// ]]; then
                    if [ "$TDF_BLOCK_BROWSER" -eq 0 ]; then
                        xdg-open "$link"
                    else
                        echo "BLOCKED: $link"
                    fi
                else
                    echo "INVALID LINK: $link"
                fi
                rm -f "$f"
            done
            sleep 0.5
        done
    ) &
    winebrowserPid=$!
}

function _stopWinebrowserBridge {
    if [ $winebrowserPid -ne -1 ]; then
        #shellcheck disable=SC2086
        kill $winebrowserPid
    fi
    winebrowserPid=-1
}

function _runCommandPrompt {
    _zenityInfo "$(_loc "$TDF_LOCALE_INSTALLMODE_BEFORECMD")"
    _startWinebrowserBridge
    local startDir="C:\\"
    if [ "$TDF_ALLOW_HOST_FILESYSTEM" -ne 0 ]; then
        startDir="H:\\$HOME"
    fi
    wineCommand=("$_wineDir/wine" "start" "/D" "$startDir" "/WAIT" "cmd.exe")
    local subshellPid=-1
    if [ -z "$_relayPath" ]; then
        runSandboxed "${wineCommand[@]}" &
        subshellPid=$!
    else
        runSandboxed "${wineCommand[@]}" > "$_relayPath" 2>&1 &
        subshellPid=$!
    fi
    _waitSubshellTermination $subshellPid "$(_loc "$TDF_LOCALE_CMDRUNNING")"
    _stopWinebrowserBridge
    _zenityInfo "$(_loc "$TDF_LOCALE_INSTALLMODE_AFTERCMD")"
}

_whileRunningPid=-1
function _runGame {
    if [ "$(type -t onGameStart)" = "function" ]; then
        onGameStart &
        wait $!
    fi
    _applyDND
    _applyNoSleep
    _startWinebrowserBridge
    if [ "$(type -t whileGameRunning)" = "function" ]; then
        whileGameRunning &
        _whileRunningPid=$!
    fi
    wineCommand=("$_wineDir/wine" "start" "/D" "$game_workingDir" "/WAIT" "$game_exe" "${game_args[@]}")
    local subshellPid=-1
    if [ -z "$_relayPath" ]; then
        runSandboxed "${wineCommand[@]}" &
        subshellPid=$!
    else
        runSandboxed "${wineCommand[@]}" > "$_relayPath" 2>&1 &
        subshellPid=$!
    fi
    _waitSubshellTermination $subshellPid "$(_loc "$TDF_LOCALE_GAMERUNNING")"
    if [ $_whileRunningPid -ne -1 ]; then
        kill $_whileRunningPid
        _whileRunningPid=-1
    fi
    _clearDND
    _clearNoSleep
    if [ "$(type -t onGameEnd)" = "function" ]; then
        onGameEnd &
        wait $!
    fi
    _stopWinebrowserBridge
}

function _loadConfig {
    if [ -e "vars.conf" ]; then
        source "vars.conf"
    fi
    if [ -d "confs" ]; then
        local confs=()
        if [ -e "confs/_list.txt" ]; then
            # shellcheck disable=SC2162
            while read f; do
                confs+=("$f")
            done < "confs/_list.txt"
        else
            for f in confs/*.conf; do
                f=$(basename "$f" ".conf")
                confs+=("$f")
            done
        fi
        if [ ${#confs[@]} -ne 0 ]; then
            local h=${#confs[@]}
            #shellcheck disable=SC2086
            if [ $h -gt 10 ]; then
                h=10
            fi
            h=$((h * 50 + 200))
            local confToUse=$(zenity --list --width=400 --height="$h" --hide-header --text="$(_loc "$TDF_LOCALE_CHOOSEGAME")" --column="Game" "${confs[@]}")
            if [ -z "$confToUse" ]; then
                exit
            fi
            confToUse="confs/$confToUse.conf"
            source "$confToUse"
        fi
    fi
    if [ "$(type -t customChecks)" = "function" ]; then
        customChecks &
        wait $!
        #shellcheck disable=SC2181
        if [ $? -ne 0 ]; then
            exit
        fi
    fi
}

function _checkAlreadyRunning {
    local lockFile="/tmp/tdf-$(echo "$PWD" | md5sum | cut -d' ' -f1).lock"
    exec 4>"$lockFile"
    chmod 777 "$lockFile"
    if ! flock -n 4; then
        fail "$(_loc "$TDF_LOCALE_ALREADYRUNNING")"
    fi
}

if ! command -v zenity > /dev/null; then
    fail "$(_loc "$TDF_LOCALE_ZENITY_MISSING")"
fi
if ! command -v bwrap > /dev/null; then
    fail "$(_loc "$TDF_LOCALE_BWRAP_MISSING")"
fi
_checkAlreadyRunning
_loadConfig
_zenityProgressInit
_initSandbox
if [ -n "$__TDF_DEBUG_SANDBOX" ]; then #TODO: remove in final version
    runSandboxed "/bin/bash"
    exit
fi
if [ -z "$game_exe" ]; then
    _runCommandPrompt
else
    _runGame
fi

#TODO: add setting to limit network to a specific interface only
