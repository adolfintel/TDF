#!/usr/bin/env bash
shopt -s expand_aliases
source "system/localization/load.sh"
export LC_ALL=C.UTF-8
if [ $# -eq 0 ]; then
    echo "$(_loc "$TDF_LOCALE_DONTRUNDIRECTLY")"
    exit
fi

# --- VARIABLES - Basic configuration ---
game_exe=''
game_args=''
game_workingDir=''

# --- VARIABLES - TDF stuff ---
TDF_VERSION="$(cat system/version)"
TDF_TITLE="$(_loc "$TDF_LOCALE_DEFAULTTITLE")"
TDF_DETAILED_PROGRESS=1
TDF_MULTIPLE_INSTANCES="askcmd" #deny=exit without error messages, error=show an error message and close, askcmd=ask the user if they want to run cmd inside the running prefix, cmd=run command prompt inside the running prefix, allow=allow multiple instances of the game
TDF_IGNORE_EXIST_CHECKS=0
TDF_HIDE_GAME_RUNNING_DIALOG=0
TDF_SHOW_PLAY_TIME=0

# --- VARIABLES - Wine ---
TDF_WINE_PREFERRED_VERSION="games" #games=game-optimized build, mainline=regular wine, custom=the build in the wine-custom folder outside the system folder, system=the version of wine that's installed on the system, or mainline if not installed, any other value will use system/wine-yourValue or system wine if not found
TDF_WINE_HIDE_CRASHES=1
TDF_WINE_AUDIO_DRIVER="default" #pulse,alsa,jack,default (let wine decide)
TDF_WINE_GRAPHICS_DRIVER="default" #x11,wayland,default (let wine decide)
TDF_WINE_DPI=-1 #-1=use system dpi, 0=let wine decide, number=use specified dpi
TDF_WINE_KILL_BEFORE=0
TDF_WINE_KILL_AFTER=0
TDF_START_ARGS='' #additional arguments to pass to wine's start command, such as /affinity 1
TDF_WINE_LANGUAGE=''
TDF_WINE_ARCH="win64" #win64=emulate 64bit windows, win32=emulate 32bit windows (useful for older games). cannot be changed after wineprefix initialization
TDF_WINE_SYNC="fsync" #fsync=use fsync if futex2 is available, otherwise esync, esync=always use esync, default=let wine decide. Only supported by games build, other versions will ignore this parameter
TDF_WINE_DEBUG_RELAY=0
TDF_WINE_DEBUG_GSTREAMER=0
TDF_WINE_SMOKETEST=1
TDF_WINEMONO=0
TDF_WINEGECKO=0
export WINE_LARGE_ADDRESS_AWARE=1
export WINEPREFIX="$(pwd)/zzprefix"
export WINEDEBUG=-all
export USER="wine"

# --- VARIABLES - DXVK ---
TDF_DXVK=1
TDF_DXVK_NVAPI=0 #set to 1 to enable nvapi (nvidia gpus only)
TDF_DXVK_ASYNC=2 #0=always use regular dxvk, 1=always use async version, 2=use regular dxvk if the gpu supports gpl, async if it doesn't0
export DXVK_ASYNC=1 #enables async features when using the async version of dxvk, ignored by the regular version

# --- VARIABLES - VKD3D ---
TDF_VKD3D=1
#since november 2023, vkd3d enabled dxr11 by default on GPUs that support ray tracing, so there's no need to enable it here anymore

# --- VARIABLES - Sandboxing ---
TDF_BLOCK_NETWORK=1 #0=allow network access, 1=block with unshare -nc, 2=block with firejail if available, unshare -nc if it's not
TDF_BLOCK_BROWSER=1
TDF_BLOCK_ZDRIVE=1
TDF_BLOCK_EXTERNAL_DRIVES=1
TDF_BLOCK_SYMLINKS_IN_CDRIVE=1
TDF_FAKE_HOMEDIR=0
TDF_PROTECT_DOSDEVICES=0

# --- VARIABLES - Gamescope ---
TDF_GAMESCOPE=0
TDF_GAMESCOPE_PARAMETERS='' #if not changed in config, this will become -f -r 60 -w $XRES -h $YRES -- where $XRES and $YRES are the resolution of the main display

# --- VARIABLES - Miscellaneous ---
TDF_GAMEMODE=1
TDF_MANGOHUD=0
TDF_COREFONTS=1
TDF_VCREDIST=1

# Note: there are a few other variables defined elsewhere, see the documentation for a complete list

if [ -d "./system/zenity" ]; then
    export PATH="$PATH:$(pwd)/system/zenity"
fi
function _outputDetail {
    if [ "$TDF_DETAILED_PROGRESS" -eq 1 ];then
        echo "#$1"
    fi
}
function _dosdevices_unprotect {
    chmod 777 "$WINEPREFIX/dosdevices"
}
function _dosdevices_protect {
    if [ "$TDF_PROTECT_DOSDEVICES" -eq 1 ]; then
        if [[ -n "$1" || "$TDF_BLOCK_ZDRIVE" -ge 1 || "$TDF_BLOCK_EXTERNAL_DRIVES" -ge 1 ]]; then
            chmod 555 "$WINEPREFIX/dosdevices"
        fi
    fi
}
function _killWine {
    wineserver -k -w
    wait
}
function _applyLocale {
    if [ -n "$TDF_WINE_LANGUAGE" ]; then
        export LC_ALL="$TDF_WINE_LANGUAGE"
    else
        if [ -n "$LANG" ]; then
            export LC_ALL="$LANG"
        fi
    fi
}
function _restoreLocale {
    export LC_ALL=C.UTF-8
}
function _realRunManualCommand {
    eval "$_blockNetworkCommand wine start /WAIT \"$1\""
}
function _realRunCommandPrompt {
    eval "$_blockNetworkCommand wine start /D \"C:\Windows\System32\" /WAIT \"cmd.exe\""
}
function _runCommandPrompt {
    zenity --info --width=500 --text="$(_loc "$TDF_LOCALE_INSTALLMODE_BEFORECMD")" &
    _applyLocale
    _realRunCommandPrompt
    _restoreLocale
    zenity --info --width=500 --text="$(_loc "$TDF_LOCALE_INSTALLMODE_AFTERCMD")"
}
function _realRunGame {
    _applyLocale
    if [ "$(type -t onGameStart)" = "function" ]; then
        wineserver -k -w
        onGameStart
    fi
    if [ "$(type -t whileGameRunning)" = "function" ]; then
        (
            whileGameRunning
        ) &
    fi
    local command="$_gamemodeCommand $_gamescopeCommand $_mangohudCommand $_blockNetworkCommand wine start /D \"$game_workingDir\" /WAIT $TDF_START_ARGS \"$game_exe\" $game_args"
    if [ "$TDF_WINE_DEBUG_RELAY" -eq 1 ]; then
        local relayPath=$(zenity --file-selection --save --title="$(_loc "$TDF_LOCALE_WINE_RELAYPATH")" --filename="relay.txt")
        if [ -n "$relayPath" ]; then
            export WINEDEBUG="$WINEDEBUG,+relay"
            command="$command > \"$relayPath\" 2>&1"
        fi
    fi
    command="${command//\\/\\\\}"
    eval $command
    if [ "$(type -t onGameEnd)" = "function" ]; then
        onGameEnd
    fi
    if [ "$TDF_GAMESCOPE" -eq 1 ]; then
        wineserver -k -w
    fi
    _restoreLocale
}
function _runGame {
    if [ $_manualInit -eq 1 ]; then
        return
    fi
    local wdir=$(winepath -u "$game_workingDir" 2> /dev/null)
    if [[ -d "$wdir" || "$TDF_IGNORE_EXIST_CHECKS" -eq 1 ]]; then
        local fpath=""
        if [[ "$game_exe" =~ ^[A-Z,a-z]:.*$ ]]; then
            fpath=$(winepath -u "$game_exe" 2> /dev/null)
        else
            fpath=$(winepath -u "$game_workingDir\\$game_exe" 2> /dev/null)
        fi
        if [[ -f "$fpath" || "$TDF_IGNORE_EXIST_CHECKS" -eq 1 ]]; then
            local startedAt=$SECONDS
            if [ $TDF_HIDE_GAME_RUNNING_DIALOG -eq 1 ]; then
                _realRunGame
            else
                (
                    _realRunGame
                ) | zenity --progress --no-cancel --text="$(_loc "$TDF_LOCALE_GAMERUNNING")" --width=250 --auto-kill --auto-close
            fi
            wait
            local playedTime=$((SECONDS - startedAt))
            local ss=$((playedTime % 60))
            local mm=$(( ( playedTime / 60 ) % 60 ))
            local hh=$((playedTime/3600))
            if [ $ss -lt 10 ]; then
                ss="0$ss"
            fi
            if [ $mm -lt 10 ]; then
                mm="0$mm"
            fi
            if [ $hh -lt 10 ]; then
                hh="0$hh"
            fi
            if [ "$TDF_SHOW_PLAY_TIME" -eq 1 ]; then
                zenity --info --width=300 --text="$(_loc "$TDF_LOCALE_PLAYEDFOR")"
            fi
        else
            zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_EXENOTFOUND")"
        fi
    else
        zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_DIRNOTFOUND")"
    fi
}
function _applyDLLs {
    _outputDetail "$(_loc "$TDF_LOCALE_COPYINGDLLS")"
    local windows_dir="$WINEPREFIX/drive_c/windows"
    if [ "$TDF_DXVK_ASYNC" -eq 2 ]; then
        ./system/tdfutils/vkgpltest
        if [ $? -eq 2 ]; then
            TDF_DXVK_ASYNC=0
        else
            TDF_DXVK_ASYNC=1
        fi
    fi
    local dxvk_dir="system/dxvk"
    if [ "$TDF_DXVK_ASYNC" -eq 1 ]; then
        dxvk_dir="$dxvk_dir-async"
    fi
    local dxvk_dlls=("d3d8" "d3d9" "d3d10" "d3d10_1" "d3d10core" "d3d11" "dxgi" "dxvk_config") #note: some files here may not exist, they are here so that overrides are added, which are useful for mods and older versions of dxvk
    local dxvknvapi_dir="system/dxvk-nvapi"
    local dxvknvapi_dlls=("nvapi" "nvapi64")
    local vkd3d_dir="system/vkd3d"
    local vkd3d_dlls=("d3d12" "d3d12core")
    local toOverride=()
    local toUnoverride=()
    function overrideDll {
        wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v "$1" /d 'native,builtin' /f
    }
    function unoverrideDll {
        wine reg delete 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v "$1" /f
    }
    function copyIfDifferent {
        if ! cmp "$1" "$2" > /dev/null 2>&1; then
            if [ -e "$1" ]; then
                \cp "$1" "$2"
            fi
        fi
    }
    if [ -d "$dxvk_dir" ]; then
        if [ "$TDF_DXVK" -eq 1 ]; then
            _outputDetail "$(_loc "$TDF_LOCALE_DXVK_INSTALL")"
            if [ "$WINEARCH" = "win32" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    copyIfDifferent "$dxvk_dir/x32/$d.dll" "$windows_dir/system32/$d.dll"
                done
            else
                for d in "${dxvk_dlls[@]}"; do
                    copyIfDifferent "$dxvk_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
                    copyIfDifferent "$dxvk_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
                done
            fi
            if [ ! -f "$WINEPREFIX/.dxvk-installed" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "$WINEPREFIX/.dxvk-installed"
            fi
            if [ "$TDF_DXVK_NVAPI" -eq 1 ]; then
                if [ "$WINEARCH" = "win32" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        copyIfDifferent "$dxvknvapi_dir/x32/$d.dll" "$windows_dir/system32/$d.dll"
                    done
                else
                    for d in "${dxvknvapi_dlls[@]}"; do
                        copyIfDifferent "$dxvknvapi_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
                        copyIfDifferent "$dxvknvapi_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
                    done
                fi
                if [ ! -f "$WINEPREFIX/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        toOverride+=("$d")
                    done
                    touch "$WINEPREFIX/.dxvknvapi-installed"
                fi
            else
                if [ -f "$WINEPREFIX/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        rm -f "$windows_dir/system32/$d.dll"
                        rm -f "$windows_dir/syswow64/$d.dll"
                        toUnoverride+=("$d")
                    done
                    wineboot -u
                    wait
                    rm -f "$WINEPREFIX/.dxvknvapi-installed"
                fi
            fi
        else
            _outputDetail "$(_loc "$TDF_LOCALE_DXVK_REMOVE")"
            if [ -f "$WINEPREFIX/.dxvk-installed" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                rm -f "$WINEPREFIX/.dxvk-installed"
                if [ -f "$WINEPREFIX/.dxvknvapi-installed" ]; then
                    for d in "${dxvknvapi_dlls[@]}"; do
                        rm -f "$windows_dir/system32/$d.dll"
                        rm -f "$windows_dir/syswow64/$d.dll"
                        toUnoverride+=("$d")
                    done
                    rm -f "$WINEPREFIX/.dxvknvapi-installed"
                fi
                wineboot -u
                wait
            fi
        fi
    fi
    if [ -d "$vkd3d_dir" ]; then
        if [ "$TDF_VKD3D" -eq 1 ]; then
            _outputDetail "$(_loc "$TDF_LOCALE_VKD3D_INSTALL")"
            if [ "$WINEARCH" = "win32" ]; then    
                for d in "${vkd3d_dlls[@]}"; do
                    copyIfDifferent "$vkd3d_dir/x86/$d.dll" "$windows_dir/system32/$d.dll"
                done
            else
                for d in "${vkd3d_dlls[@]}"; do
                    copyIfDifferent "$vkd3d_dir/x86/$d.dll" "$windows_dir/syswow64/$d.dll"
                    copyIfDifferent "$vkd3d_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
                done
            fi
            if [ ! -f "$WINEPREFIX/.vkd3d-installed" ]; then
                for d in "${vkd3d_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "$WINEPREFIX/.vkd3d-installed"
            fi
        else
            _outputDetail "$(_loc "$TDF_LOCALE_VKD3D_REMOVE")"
            if [ -f "$WINEPREFIX/.vkd3d-installed" ]; then
                for d in "${vkd3d_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                wineboot -u
                wait
                rm -f "$WINEPREFIX/.vkd3d-installed"
            fi
        fi
    fi
    _outputDetail "$(_loc "$TDF_LOCALE_REGISTERINGDLLS")"
    for d in "${toUnoverride[@]}"; do
        unoverrideDll "$d"
    done
    for d in "${toOverride[@]}"; do
        overrideDll "$d"
    done
}
function _applyMSIs {
    local msi_dir="system/msi"
    if [ -d "$msi_dir" ]; then
        function installMonoMSI {
            \cp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi"
            wine msiexec /i "C:\\winemono.msi"
            wait
            echo "$TDF_VERSION" > "$WINEPREFIX/.winemono-installed"
        }
        function uninstallMonoMSI {
            wine msiexec /uninstall "C:\\winemono.msi"
            wait
            rm -f "$WINEPREFIX/.winemono-installed"
            rm -f "$WINEPREFIX/drive_c/winemono.msi"
        }
        if [ "$TDF_WINEMONO" -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winemono-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_WINEMONO_INSTALL")"
                installMonoMSI
            else
                if ! cmp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi" > /dev/null 2>&1; then
                    \cp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi"
                    _outputDetail "$(_loc "$TDF_LOCALE_WINEMONO_UPDATE")"
                    uninstallMonoMSI
                    installMonoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winemono-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_WINEMONO_REMOVE")"
                uninstallMonoMSI
            fi
        fi
        function installGeckoMSI {
            if [ "$WINEARCH" = "win32" ]; then
                \cp "$msi_dir/winegecko32.msi" "$WINEPREFIX/drive_c/winegecko32.msi"
                wine msiexec /i "C:\\winegecko32.msi"
            else
                \cp "$msi_dir/winegecko32.msi" "$WINEPREFIX/drive_c/winegecko32.msi"
                wine msiexec /i "C:\\winegecko32.msi"
                \cp "$msi_dir/winegecko64.msi" "$WINEPREFIX/drive_c/winegecko64.msi"
                wine msiexec /i "C:\\winegecko64.msi"
            fi
            wait
            echo "$TDF_VERSION" > "$WINEPREFIX/.winegecko-installed"
        }
        function uninstallGeckoMSI {
            wine msiexec /uninstall "C:\\winegecko32.msi"
            wine msiexec /uninstall "C:\\winegecko64.msi"
            wait
            rm -f "$WINEPREFIX/.winegecko-installed"
            rm -f "$WINEPREFIX/drive_c/winegecko32.msi"
            rm -f "$WINEPREFIX/drive_c/winegecko64.msi"
        }
        if [ "$TDF_WINEGECKO" -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winegecko-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_WINEGECKO_INSTALL")"
                installGeckoMSI
            else
                local mustUpdate=0
                if ! cmp "$msi_dir/winegecko32.msi" "$WINEPREFIX/drive_c/winegecko32.msi" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if [ "$WINEARCH" != "win32" ]; then
                    if ! cmp "$msi_dir/winegecko64.msi" "$WINEPREFIX/drive_c/winegecko64.msi" > /dev/null 2>&1; then
                        mustUpdate=1
                    fi
                fi
                if [ $mustUpdate -eq 1 ]; then
                    _outputDetail "$(_loc "$TDF_LOCALE_WINEGECKO_UPDATE")"
                    uninstallGeckoMSI
                    installGeckoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winegecko-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_WINEGECKO_REMOVE")"
                uninstallGeckoMSI
            fi
        fi
    fi
}
function _applyVCRedists {
    local vc_dir="system/vcredist"
    if [ -d "$vc_dir" ]; then
        function installVCRedists {
            wineserver -k -w
            wait
            if [ -e "$WINEPREFIX/dosdevices/z:" ]; then
                _dosdevices_unprotect
                mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/.templink"
                _dosdevices_protect "always"
            fi
            if [ "$WINEARCH" = "win32" ]; then
                \cp "$vc_dir/vc_redist.x86.exe" "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                unshare -nc wine "C:\\vc_redist.x86.exe" /install /quiet /norestart
            else
                \cp "$vc_dir/vc_redist.x86.exe" "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                \cp "$vc_dir/vc_redist.x64.exe" "$WINEPREFIX/drive_c/vc_redist.x64.exe"
                unshare -nc wine "C:\\vc_redist.x86.exe" /install /quiet /norestart
                unshare -nc wine "C:\\vc_redist.x64.exe" /install /quiet /norestart
            fi
            wait
            wineserver -k -w
            wait
            if [ -e "$WINEPREFIX/.templink" ]; then
                _dosdevices_unprotect
                mv "$WINEPREFIX/.templink" "$WINEPREFIX/dosdevices/z:"
                _dosdevices_protect
            fi
            echo "$TDF_VERSION" > "$WINEPREFIX/.vcredist-installed"
        }
        function uninstallVCRedists {
            wineserver -k -w
            wait
            if [ -e "$WINEPREFIX/dosdevices/z:" ]; then
                _dosdevices_unprotect
                mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/.templink"
                _dosdevices_protect "always"
            fi
            unshare -nc wine "C:\\vc_redist.x86.exe" /uninstall /quiet /norestart
            unshare -nc wine "C:\\vc_redist.x64.exe" /uninstall /quiet /norestart
            wait
            wineserver -k -w
            wait
            if [ -e "$WINEPREFIX/.templink" ]; then
                _dosdevices_unprotect
                mv "$WINEPREFIX/.templink" "$WINEPREFIX/dosdevices/z:"
                _dosdevices_protect
            fi
            rm -f "$WINEPREFIX/.vcredist-installed"
            rm -f "$WINEPREFIX/drive_c/vc_redist.x86.exe"
            rm -f "$WINEPREFIX/drive_c/vc_redist.x64.exe"
        }
        if [ "$TDF_VCREDIST" -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.vcredist-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_VCREDIST_INSTALL")"
                installVCRedists
            else
                local mustUpdate=0
                if ! cmp "$vc_dir/vc_redist.x86.exe" "$WINEPREFIX/drive_c/vc_redist.x86.exe" > /dev/null 2>&1; then
                    mustUpdate=1
                fi
                if [ "$WINEARCH" != "win32" ]; then
                    if ! cmp "$vc_dir/vc_redist.x64.exe" "$WINEPREFIX/drive_c/vc_redist.x64.exe" > /dev/null 2>&1; then
                        mustUpdate=1
                    fi
                fi
                if [ $mustUpdate -eq 1 ]; then
                    _outputDetail "$(_loc "$TDF_LOCALE_VCREDIST_UPDATE")"
                    uninstallVCRedists
                    installVCRedists
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.vcredist-installed" ]; then
                _outputDetail "$(_loc "$TDF_LOCALE_VCREDIST_REMOVE")"
                uninstallVCRedists
            fi
        fi    
        
    fi
}
function _removeIntegrations {
    _outputDetail "$(_loc "$TDF_LOCALE_DEINTEGRATING")"
    local _pfxversion=""
    if [ -f "$WINEPREFIX/.initialized" ]; then
        _pfxversion=$(cat "$WINEPREFIX/.initialized")
    fi
    if [ "$_pfxversion" != "$TDF_VERSION" ]; then
        if [ "$WINEARCH" = "win32" ]; then
            wine reg delete 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine reg delete 'HKEY_CLASSES_ROOT\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
        else
            wine64 reg delete 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine64 reg delete 'HKEY_CLASSES_ROOT\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine64 reg delete 'HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
        fi
    fi
    function deIntegrate {
        if [ -L "$WINEPREFIX/drive_c/users/$USER/$1" ]; then
            unlink "$WINEPREFIX/drive_c/users/$USER/$1"
            mkdir "$WINEPREFIX/drive_c/users/$USER/$1"
        fi
        if [ -L "$WINEPREFIX/drive_c/users/$USER/Documents/$1" ]; then
            unlink "$WINEPREFIX/drive_c/users/$USER/Documents/$1"
        fi
    }
    deIntegrate "Documents"
    deIntegrate "Desktop"
    deIntegrate "Downloads"
    deIntegrate "Pictures"
    deIntegrate "Music"
    deIntegrate "Videos"
    deIntegrate "Templates"
    if [ -L "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Microsoft/Windows/Templates" ]; then
        unlink "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Microsoft/Windows/Templates"
        mkdir "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Microsoft/Windows/Templates"
    fi
    if [ "$TDF_BLOCK_SYMLINKS_IN_CDRIVE" -eq 1 ]; then
        ( find -L "$WINEPREFIX/drive_c/" -xtype l -exec rm {} + ) &
    fi
}
function _applyScaling {
    _outputDetail "$(_loc "$TDF_LOCALE_SCALING")"
    if [ "$TDF_WINE_DPI" -eq -1 ]; then
        TDF_WINE_DPI=$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)
    fi
    if [ "$TDF_WINE_DPI" -ne 0 ]; then
        local currentDpi=0
        if [ -e "$WINEPREFIX/.dpi" ]; then
            currentDpi=$(cat "$WINEPREFIX/.dpi")
        fi
        if [ "$TDF_WINE_DPI" != "$currentDpi" ]; then
            wine reg add 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /t REG_DWORD /d "$TDF_WINE_DPI" /f
            echo "$TDF_WINE_DPI" > "$WINEPREFIX/.dpi"
        fi
    else
        if [ -e "$WINEPREFIX/.dpi" ]; then
            wine reg delete 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /f
            rm -f "$WINEPREFIX/.dpi"
        fi
    fi
}
function _applyHideCrashes {
    _outputDetail "$(_loc "$TDF_LOCALE_WINE_HIDECRASHES")"
    if [ "$TDF_WINE_HIDE_CRASHES" -eq 1 ]; then
        export WINEDEBUG=-all
        if [ ! -f "$WINEPREFIX/.crash-hidden" ]; then
            wine reg add 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
            touch "$WINEPREFIX/.crash-hidden"
        fi
    else
        if [ -f "$WINEPREFIX/.crash-hidden" ]; then
            wine reg delete 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /f
            rm -f "$WINEPREFIX/.crash-hidden"
        fi
    fi
}
function _applyWineDrivers {
    _outputDetail "$(_loc "$TDF_LOCALE_WINE_DRIVERS")"
    if [ "$TDF_WINE_AUDIO_DRIVER" != "default" ]; then
        wine reg add 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Audio' /t REG_SZ /d "$TDF_WINE_AUDIO_DRIVER" /f
    else
        wine reg delete 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Audio' /f
    fi
    if [ "$TDF_WINE_GRAPHICS_DRIVER" != "default" ]; then
        wine reg add 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Graphics' /t REG_SZ /d "$TDF_WINE_GRAPHICS_DRIVER" /f
    else
        wine reg delete 'HKEY_CURRENT_USER\Software\Wine\Drivers' /v 'Graphics' /f
    fi
}
function _removeBrokenDosdevices {
    _outputDetail "$(_loc "$TDF_LOCALE_LINKS_CHECK")"
    _dosdevices_unprotect
    local before="$(pwd)"
    cd "$WINEPREFIX/dosdevices"
    find -L . -name . -o -type d -prune -o -type l -exec rm {} +
    cd "$before"
    _dosdevices_protect
}
function _removeUnwantedDosdevices {
    _outputDetail "$(_loc "$TDF_LOCALE_LINKS_CHECK")"
    _dosdevices_unprotect
    local driveC=$(realpath "$WINEPREFIX/dosdevices/c:")
    for f in "$WINEPREFIX"/dosdevices/* ; do
        if [[ $(basename "$f") =~ (com)[0-9]* ]]; then
            unlink "$f"
        else
            if [ "$TDF_BLOCK_EXTERNAL_DRIVES" -ge 1 ]; then
                local rp=$(realpath "$f")
                if [[ "$rp" != "$driveC"  &&  "$rp" != "/" ]]; then
                    unlink "$f"
                fi
            fi
        fi
    done
    if [[ "$TDF_BLOCK_ZDRIVE" -ge 2  || "$TDF_BLOCK_ZDRIVE" -eq 1 && -n "$game_exe" ]]; then
        unlink "$WINEPREFIX/dosdevices/z:"
    fi
    _dosdevices_protect
}
function _checkAndRepairCDrive {
    _outputDetail "$(_loc "$TDF_LOCALE_LINKS_CHECK")"
    local link=$(realpath "$WINEPREFIX/dosdevices/c:")
    local target=$(realpath "$WINEPREFIX/drive_c")
    if [ "$link" != "$target" ]; then
        link="$WINEPREFIX/dosdevices/c:"
        _dosdevices_unprotect
        rm -rf "$link"
        ln -s "$target" "$link"
        _dosdevices_protect
        link=$(realpath "$link")
        if [ "$link" != "$target" ]; then
            touch "$WINEPREFIX/.abort"
            zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_LINKS_CDRIVEBROKEN")"
            exit
        fi
    fi
}
function _checkAndRepairZDrive {
    _outputDetail "$(_loc "$TDF_LOCALE_LINKS_CHECK")"
    if [[ "$TDF_BLOCK_ZDRIVE" -ge 2 || "$TDF_BLOCK_ZDRIVE" -eq 1 && -n "$game_exe" ]]; then
        return
    fi
    local link=$(realpath "$WINEPREFIX/dosdevices/z:")
    local target="/"
    if [ "$link" != "$target" ]; then
        _dosdevices_unprotect
        link="$WINEPREFIX/dosdevices/z:"
        rm -rf "$link"
        ln -s "$target" "$link"
        _dosdevices_protect
        link=$(realpath "$link")
        if [ "$link" != "$target" ]; then
            touch "$WINEPREFIX/.abort"
            zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_LINKS_ZDRIVEBROKEN")"
            exit
        fi
    fi
}
function _applyBlockBrowser {
    _outputDetail "$(_loc "$TDF_LOCALE_WINE_BLOCKBROWSER")"
    if [ "$TDF_BLOCK_BROWSER" -eq 1 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winebrowser.exe=d"
    fi
}
function _applyCorefonts {
    local windows_dir="$WINEPREFIX/drive_c/windows"
    local corefonts_dir="system/corefonts"
    local corefonts_info=("AndaleMo.TTF:Andale Mono" "Arial.TTF:Arial" "Arialbd.TTF:Arial Bold" "Arialbi.TTF:Arial Bold Italic" "Ariali.TTF:Arial Italic" "AriBlk.TTF:Arial Black" "Comic.TTF:Comic Sans MS" "Comicbd.TTF:Comic Sans MS Bold" "cour.ttf:Courier New" "courbd.ttf:Courier New Bold" "courbi.ttf:Courier New Bold Italic" "couri.ttf:Courier New Italic" "Georgia.TTF:Georgia" "Georgiab.TTF:Georgia Bold" "Georgiai.TTF:Georgia Italic" "Georgiaz.TTF:Georgia Bold Italic" "Impact.TTF:Impact" "Times.TTF:Times New Roman" "Timesbd.TTF:Times New Roman Bold" "Timesbi.TTF:Times New Roman Bold Italic" "Timesi.TTF:Times New Roman Italic" "trebuc.ttf:Trebuchet MS" "Trebucbd.ttf:Trebuchet MS Bold" "trebucbi.ttf:Trebuchet MS Bold Italic" "trebucit.ttf:Trebuchet MS Italic" "Verdana.TTF:Verdana" "Verdanab.TTF:Verdana Bold" "Verdanai.TTF:Verdana Italic" "Verdanaz.TTF:Verdana Bold Italic" "Webdings.TTF:Webdings")
    if [ -d "$corefonts_dir" ]; then
        if [ "$TDF_COREFONTS" -eq 1 ]; then
            _outputDetail "$(_loc "$TDF_LOCALE_COREFONTS_INSTALL")"
            if [ ! -f "$WINEPREFIX/.corefonts-installed" ]; then
                local commands=""
                function copyAndRegister {
                    cp -f "$corefonts_dir/$1" "$windows_dir/Fonts"
                    commands="$commands /v '$2' /t REG_SZ /d '$1' "
                }
                for f in "${corefonts_info[@]}"; do
                    copyAndRegister "$(echo $f | cut -d ':' -f 1)" "$(echo $f | cut -d ':' -f 2)"
                done
                wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' $commands /f
                wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' /v '$2' /t REG_SZ /d '$1' $commands /f
                touch "$WINEPREFIX/.corefonts-installed"
            fi
        else
            _outputDetail "$(_loc "$TDF_LOCALE_COREFONTS_REMOVE")"
            if [ -f "$WINEPREFIX/.corefonts-installed" ]; then
                local commands=""
                function deleteAndUnregister {
                    rm -f "$windows_dir/Fonts/$1"
                    commands="$commands /v '$2'"
                }
                for f in "${corefonts_info[@]}"; do
                    deleteAndUnregister "$(echo $f | cut -d ':' -f 1)" "$(echo $f | cut -d ':' -f 2)"
                done
                wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' $commands /f
                wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' $commands /f
                rm -f "$WINEPREFIX/.corefonts-installed"
            fi
        fi
    fi
}
function _applyFakeHomeDir {
    if [ "$TDF_FAKE_HOMEDIR" -eq 1 ]; then
        export HOME="$(pwd)/zzhome"
        if [ ! -d "$HOME" ]; then
            mkdir "$HOME"
        fi
    else
        if [ -d "$(pwd)/zzhome" ]; then
            rm -rf "$(pwd)/zzhome"
        fi
    fi
}
function _wineSmokeTest {
    if [[ "$TDF_WINE_SMOKETEST" -eq 0 ]]; then
        return 0
    fi
    if [ -d "$WINEPREFIX/drive_c" ]; then
        if [ -e "$WINEPREFIX/drive_c/smoke.txt" ]; then
            rm "$WINEPREFIX/drive_c/smoke.txt"
        fi
        \cp "system/tdfutils/smoke32.exe" "$WINEPREFIX/drive_c/"
        local _r=$RANDOM
        wine 'C:\smoke32.exe' $_r
        wait
        rm "$WINEPREFIX/drive_c/smoke32.exe"
        if [ -f "$WINEPREFIX/drive_c/smoke.txt" ]; then
            local _out=$(cat "$WINEPREFIX/drive_c/smoke.txt")
            rm "$WINEPREFIX/drive_c/smoke.txt"
            if [ "$_out" != "$_r" ]; then
                return 2
            fi
            if [ "$WINEARCH" = "win32" ]; then
                return 0
            fi
            \cp "system/tdfutils/smoke64.exe" "$WINEPREFIX/drive_c/"
            wine 'C:\smoke64.exe' $_r
            wait
            rm "$WINEPREFIX/drive_c/smoke64.exe"
            if [ -f "$WINEPREFIX/drive_c/smoke.txt" ]; then
                _out=$(cat "$WINEPREFIX/drive_c/smoke.txt")
                rm "$WINEPREFIX/drive_c/smoke.txt"
                if [ "$_out" != "$_r" ]; then
                    return 3
                fi
            fi
        fi
    else
        return 1
    fi
    return 0
}
function _showWineError {
    zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_WINE_BROKEN")"
}

function _tdfmain {
    local _manualInit=0
    if [ "$1" = "manualInit" ]; then
        _manualInit=1
    fi
    ./system/tdfutils/vkgpltest
    local _res=$?
    if [[ $_res -eq 0 || $_res -gt 2 || $_res -lt 0 ]]; then
        zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_NOVULKAN")"
        exit
    fi
    if [ -d "system/xutils" ]; then
        export PATH="$PATH:$(pwd)/system/xutils"
    fi
    source "$(pwd)/system/builtinFunctions.sh"
    XRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 1)
    YRES=$(cat /sys/class/graphics/*/virtual_size | cut -d ',' -f 2)
    if [ -f "vars.conf" ]; then
        source "./vars.conf"
    fi
    if [ -d "confs" ]; then
        local _confs=()
        if [ -f "confs/_list.txt" ]; then
            while read f; do
                _confs+=("$f")
            done < "confs/_list.txt"
        else
            for f in confs/*.conf; do
                if [ -f "$f" ]; then
                    f=$(basename "$f" ".conf")
                    _confs+=("$f")
                fi
            done
        fi
        if [ ${#_confs[@]} -ne 0 ]; then
            local h=${#_confs[@]}
            if [ $h -gt 10 ]; then
                h=10
            fi
            h=$((h * 50 + 200))
            local _confToUse=$(zenity --list --width=400 --height="$h" --hide-header --text="$(_loc "$TDF_LOCALE_CHOOSEGAME")" --column="Game" "${_confs[@]}")
            if [ -z "$_confToUse" ]; then
                exit
            fi
            _confToUse="confs/$_confToUse.conf"
            source "$_confToUse"
        fi
    fi
    game_workingDir="${game_workingDir//\//\\}"
    game_exe="${game_exe//\//\\}"
    if [ -z "$game_workingDir" ]; then
        game_workingDir="${game_exe%\\*}"
    fi
    _applyFakeHomeDir
    if [ "$(type -t customChecks)" = "function" ]; then
        customChecks
        if [ $? -ne 0 ]; then
            exit
        fi
    fi
    if [ "$TDF_WINE_DEBUG_GSTREAMER" -eq 1 ]; then
        export GST_DEBUG_NO_COLOR=1
        export GST_DEBUG=4,WINE:9
    fi
    if [ "$TDF_WINE_PREFERRED_VERSION" = "custom" ]; then
       export PATH="$(pwd)/wine-custom/bin:$PATH"
    elif [ "$TDF_WINE_PREFERRED_VERSION" = "system" ]; then
       export PATH="$PATH:$(pwd)/system/wine-mainline/bin"
    else
       export PATH="$(pwd)/system/wine-$TDF_WINE_PREFERRED_VERSION/bin:$PATH"
    fi
    if [ "$TDF_WINEMONO" -eq 0 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree="
    fi
    if [ "$TDF_WINEGECKO" -eq 0 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mshtml="
    fi
    export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winemenubuilder.exe=d"
    if [ "$TDF_BLOCK_EXTERNAL_DRIVES" -ge 2 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winedevice.exe=d"
    fi
    _applyFakeHomeDir
    local _blockNetworkCommand="unshare -nc"
    if [ "$TDF_BLOCK_NETWORK" -eq 2 ]; then
        command -v firejail > /dev/null
        if [ $? -eq 0 ]; then
            _blockNetworkCommand="firejail --noprofile --net=none"
        fi
    fi
    if [ "$TDF_BLOCK_NETWORK" -eq 0 ]; then
        _blockNetworkCommand=""
    fi
    local _gamescopeCommand=""
    if [ "$TDF_GAMESCOPE" -ge 1 ]; then
        command -v gamescope > /dev/null
        if [ $? -eq 0 ]; then
            if [ -z "$TDF_GAMESCOPE_PARAMETERS" ]; then
                TDF_GAMESCOPE_PARAMETERS="-f -r 60 -w $XRES -h $YRES"
            fi
            _gamescopeCommand="gamescope $TDF_GAMESCOPE_PARAMETERS --"
            export INTEL_DEBUG="noccs,$INTEL_DEBUG"
        fi
    fi
    local _gamemodeCommand="gamemoderun"
    if [ "$TDF_GAMEMODE" -eq 1 ]; then
        command -v gamemoderun > /dev/null
        if [ $? -ne 0 ]; then
            _gamemodeCommand=""
        fi
    else
        _gamemodeCommand=""
    fi
    local _mangohudCommand="mangohud"
    if [ "$TDF_MANGOHUD" -eq 1 ]; then
        command -v mangohud > /dev/null
        if [ $? -ne 0 ]; then
            _mangohudCommand=""
        fi
    else
        _mangohudCommand=""
    fi
    wine --version > /dev/null
    if [ $? -ne 0 ]; then
        _showWineError
        exit
    fi
    if [ "$TDF_WINE_SYNC" = "fsync" ]; then
        ./system/tdfutils/futex2test
        if [ $? -eq 1 ]; then
            export WINEFSYNC=1
            export WINEESYNC=0
        else
            export WINEFSYNC=0
            export WINEESYNC=1
        fi
    elif [ "$TDF_WINE_SYNC" = "esync" ]; then
        export WINEFSYNC=0
        export WINEESYNC=1
    else
        export WINEFSYNC=0
        export WINEESYNC=0
    fi
    if [ "$TDF_WINE_ARCH" = "win64" ]; then
        export WINEARCH="win64"
    elif [ "$TDF_WINE_ARCH" = "win32" ]; then
        export WINEARCH="win32"
    else
        zenity --error --text="$(_loc "$TDF_LOCALE_WINE_INVALIDARCH")"
        exit
    fi
    local _flockid=0
    if [ -f "$WINEPREFIX/.flockid" ]; then
        _flockid=$(cat "$WINEPREFIX/.flockid")
        _flockid=$(( _flockid ))
    else
        _flockid=$(( RANDOM % 10000 + 400 ))
    fi
    local _skipInitializations=0
    exec {_flockid}<"$0"
    flock -n -e $_flockid
    if [ $? -ne 0 ]; then
        if [ -e "$WINEPREFIX/.initialized" ]; then
            local _pfxversion=$(cat "$WINEPREFIX/.initialized")
            if [ "$_pfxversion" = "$TDF_VERSION" ]; then
                if [ "$TDF_MULTIPLE_INSTANCES" = "close" ]; then
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" = "error" ]; then
                    zenity --error --text="$(_loc "$TDF_LOCALE_ALREADYRUNNING_ERROR")"
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" = "askcmd" ]; then
                    zenity --question --width=400 --text="$(_loc "$TDF_LOCALE_ALREADYRUNNING_ASKCMD")"
                    if [ $? -eq 0 ]; then
                        _realRunCommandPrompt
                    fi
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" = "cmd" ]; then
                    _realRunCommandPrompt
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" = "allow" ]; then
                    _skipInitializations=1
                else
                    exit
                fi
            else
                exit
            fi
        else
            exit
        fi
    fi
    if [ "$TDF_WINE_KILL_BEFORE" -eq 1 ]; then
        _killWine
    fi
    if [[ "$TDF_DXVK" -eq 1 && "$TDF_DXVK_NVAPI" -eq 1 && -z "$DXVK_ENABLE_NVAPI" ]]; then
        export DXVK_ENABLE_NVAPI=1
    fi
    if [ -d "$WINEPREFIX" ]; then
        if [ -n "$WINEARCH" ]; then
            local _pfxarch=$(cat "$WINEPREFIX/system.reg" | grep -m 1 '#arch' | cut -d '=' -f2)
            if [ "$_pfxarch" != "$WINEARCH" ]; then
                zenity --error --width=500 --text="$(_loc "$TDF_LOCALE_WINE_WRONGARCH")"
                exit
            fi
        fi
        rm -f "$WINEPREFIX/.abort"
        (
            echo "1"
            if [ $_skipInitializations -eq 0 ]; then
                _removeBrokenDosdevices
                _checkAndRepairCDrive
                _checkAndRepairZDrive
                echo "10"
                _outputDetail "$(_loc "$TDF_LOCALE_STARTINGWINE")"
                local _realOverrides="$WINEDLLOVERRIDES"
                export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
                wineboot
                wait
                _wineSmokeTest
                if [ $? -ne 0 ]; then
                    _showWineError
                    touch "$WINEPREFIX/.abort"
                    exit
                fi
                echo "30"
                _applyDLLs
                echo "40"
                _applyMSIs
                echo "55"
                _applyWineDrivers
                _applyHideCrashes
                echo "60"
                _applyCorefonts
                echo "70"
                _removeIntegrations
                echo "75"
                _applyScaling
                echo "80"
                _applyVCRedists
                echo "90"
                _removeUnwantedDosdevices
                echo "95"
                wait
                export WINEDLLOVERRIDES="$_realOverrides"
                _outputDetail "$(_loc "$TDF_LOCALE_LAUNCHINGGAME")"
                wineserver -k -w
                wait
                echo "100"
                echo "$TDF_VERSION" > "$WINEPREFIX/.initialized"
            fi
        ) | zenity --progress --no-cancel --text="$(_loc "$TDF_LOCALE_LAUNCHING")" --width=250 --auto-close --auto-kill
        wait
        if [ -f "$WINEPREFIX/.abort" ]; then
            rm -f "$WINEPREFIX/.abort"
            exit
        fi
        _applyBlockBrowser
        if [ $_manualInit -eq 1 ]; then
            if [ -n "$2" ]; then
                _realRunManualCommand "$2"
            fi
        else
            if [ -z "$game_exe" ]; then
                _runCommandPrompt
            else
                _runGame
            fi
        fi
    else
        (
            echo "10"
            _outputDetail "$(_loc "$TDF_LOCALE_STARTINGWINE")"
            local _realOverrides="$WINEDLLOVERRIDES"
            export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
            mkdir -p "$WINEPREFIX"
            echo $_flockid > "$WINEPREFIX/.flockid"
            wineboot -i
            wait
            _wineSmokeTest
            if [ $? -ne 0 ]; then
                _showWineError
                touch "$WINEPREFIX/.abort"
                exit
            fi
            echo "30"
            while ! test -f "$WINEPREFIX/system.reg"; do
                sleep 1
            done
            echo "30"
            _applyDLLs
            echo "40"
            _applyMSIs
            echo "55"
            _applyWineDrivers
            _applyHideCrashes
            echo "60"
            _applyCorefonts
            echo "70"
            _removeIntegrations
            echo "75"
            _applyScaling
            echo "80"
            _applyVCRedists
            echo "90"
            _removeUnwantedDosdevices
            echo "95"
            wait
            export WINEDLLOVERRIDES="$_realOverrides"
            _outputDetail "$(_loc "$TDF_LOCALE_STARTING")"
            wineserver -k -w
            wait
            echo "100"
            echo "$TDF_VERSION" > "$WINEPREFIX/.initialized"
        ) | zenity --progress --no-cancel --text="$(_loc "$TDF_LOCALE_INITPREFIX")" --width=500 --auto-close --auto-kill
        wait
        _applyBlockBrowser
        if [ $_manualInit -eq 1 ]; then
            if [ -n "$2" ]; then
                _realRunManualCommand "$2"
            fi
        else
            _runCommandPrompt
        fi
    fi
    if [ "$TDF_WINE_KILL_AFTER" -eq 1 ]; then
        _killWine
    fi
}

_tdfmain $@
