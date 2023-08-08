#!/usr/bin/env bash
shopt -s expand_aliases
export LC_ALL=C.UTF-8
if [[ $# -eq 0 ]]; then
    echo "This script should not be run directly, use run.sh instead"
    exit
fi

# --- VARIABLES - Basic configuration ---
game_exe=''
game_args=''
game_workingDir=''

# --- VARIABLES - TDF stuff ---
TDF_VERSION="$(cat system/version)"
TDF_TITLE="Launcher"
TDF_DETAILED_PROGRESS=1
TDF_ZENITY_PREFER_SYSTEM=1
TDF_MULTIPLE_INSTANCES="askcmd" #deny=exit without error messages, error=show an error message and close, askcmd=ask the user if they want to run cmd inside the running prefix, cmd=run command prompt inside the running prefix, allow=allow multiple instances of the game
TDF_IGNORE_EXIST_CHECKS=0
TDF_HIDE_GAME_RUNNING_DIALOG=0
TDF_SHOW_PLAY_TIME=0

# --- VARIABLES - Wine ---
TDF_WINE_PREFERRED_VERSION="games" #games=game-optimized build, mainline=regular wine, system=the version of wine that's installed on the system, or mainline if not installed
TDF_WINE_HIDE_CRASHES=1
TDF_WINE_DPI=-1 #-1=use system dpi (xorg only, wayland will use wine's default), 0=let wine decide, number=use specified dpi
TDF_WINE_KILL_BEFORE=0
TDF_WINE_KILL_AFTER=0
TDF_START_ARGS='' #additional arguments to pass to wine's start command, such as /affinity 1
TDF_WINE_LANGUAGE=''
TDF_WINE_ARCH="win64" #win64=emulate 64bit windows, win32=emulate 32bit windows (useful for older games). cannot be changed after wineprefix initialization
TDF_WINE_SYNC="fsync" #fsync=use fsync if futex2 is available, otherwise esync, esync=always use esync, default=let wine decide. Only supported by wine-ge-proton, other versions will ignore this parameter
TDF_WINE_DEBUG_RELAY=0
TDF_WINEMONO=0
TDF_WINEGECKO=0
export WINE_LARGE_ADDRESS_AWARE=1
export WINEPREFIX="$(pwd)/zzprefix"
export WINEDEBUG=-all
export USER="wine"

# --- VARIABLES - DXVK and D8VK ---
TDF_DXVK=1
TDF_DXVK_ASYNC=2 #0=always use regular dxvk, 1=always use async version, 2=use regular dxvk if the gpu supports gpl, async if it doesn't
TDF_D8VK=0
export DXVK_ASYNC=1 #enables async features when using the async version of dxvk, ignored by the regular version

# --- VARIABLES - VKD3D ---
TDF_VKD3D=1
export VKD3D_CONFIG=dxr11 #enables dx12 ray tracing on supported cards

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
TDF_MSMFPLAT=0

# Note: there are a few other variables defined elsewhere, see the documentation for a complete list

alias zenity='zenity --title="$TDF_TITLE"'
if [ $TDF_ZENITY_PREFER_SYSTEM -eq 1 ] && [ -f "/usr/bin/zenity" ]; then
    alias zenity='/usr/bin/zenity --title="$TDF_TITLE"'
fi
function _outputDetail {
    if [ $TDF_DETAILED_PROGRESS -eq 1 ];then
        echo "#$1"
    fi
}
function _dosdevices_unprotect {
    chmod 777 "$WINEPREFIX/dosdevices"
}
function _dosdevices_protect {
    if [ $TDF_PROTECT_DOSDEVICES -eq 1 ]; then
        if [[ -n "$1" || $TDF_BLOCK_ZDRIVE -ge 1 || $TDF_BLOCK_EXTERNAL_DRIVES -ge 1 ]]; then
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
    zenity --info --width=500 --text="A Wine command prompt will now open, use it to install the game and then close it.\nDo not launch the game yet" &
    _applyLocale
    _realRunCommandPrompt
    _restoreLocale
    zenity --info --width=500 --text="Good, now edit vars.conf and set game_exe to the Windows-style path to the game's exe file"
}
function _realRunGame {
    _applyLocale
    if [ "$(type -t onGameStart)" == "function" ]; then
        onGameStart
    fi
    if [ "$(type -t whileGameRunning)" == "function" ]; then
        (
            whileGameRunning
        ) &
    fi
    local command="$_gamemodeCommand $_gamescopeCommand $_mangohudCommand $_blockNetworkCommand wine start /D \"$game_workingDir\" /WAIT $TDF_START_ARGS \"$game_exe\" $game_args"
    if [ $TDF_WINE_DEBUG_RELAY -eq 1 ]; then
        local relayPath=$(zenity --file-selection --save --title="Where do you want to save the trace?" --filename="relay.txt")
        if [ -n "$relayPath" ]; then
            export WINEDEBUG="$WINEDEBUG,+relay"
            command="$command > \"$relayPath\" 2>&1"
        fi
    fi
    eval $command
    if [ "$(type -t onGameEnd)" == "function" ]; then
        onGameEnd
    fi
    if [ $TDF_GAMESCOPE -eq 1 ]; then
        wineserver -k -w
    fi
    _restoreLocale
}
function _runGame {
    if [ $_manualInit -eq 1 ]; then
        return
    fi
    local wdir=$(winepath -u "$game_workingDir" 2> /dev/null)
    if [ -d "$wdir" ] || [ $TDF_IGNORE_EXIST_CHECKS -eq 1 ]; then
        local fpath=$(winepath -u "$game_workingDir\\$game_exe" 2> /dev/null)
        if [ -f "$fpath" ]  || [ $TDF_IGNORE_EXIST_CHECKS -eq 1 ] ; then
            local startedAt=$SECONDS
            if [ $TDF_HIDE_GAME_RUNNING_DIALOG -eq 1 ]; then
                _realRunGame
            else
                (
                    _realRunGame
                ) | zenity --progress --no-cancel --text="Game running" --width=250 --auto-kill --auto-close
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
            if [ $TDF_SHOW_PLAY_TIME -eq 1 ]; then
                zenity --info --width=300 --text="Played for $hh:$mm:$ss"
            fi
        else
            zenity --error --width=500 --text="Configuration error: the specified game_exe does not exist"
        fi
    else
        zenity --error --width=500 --text="Configuration error: the specified game_workingDir does not exist"
    fi
}
function _applyDLLs {
    _outputDetail "Copying DLLs..."
    local windows_dir="$WINEPREFIX/drive_c/windows"
    if [ $TDF_DXVK_ASYNC -eq 2 ]; then
        ./system/vkgpltest
        if [ $? -eq 2 ]; then
            TDF_DXVK_ASYNC=0
        else
            TDF_DXVK_ASYNC=1
        fi
    fi
    local dxvk_dir="system/dxvk"
    if [ $TDF_DXVK_ASYNC -eq 1 ]; then
        dxvk_dir="$dxvk_dir-async"
    fi
    local dxvk_dlls=("d3d9" "d3d10" "d3d10_1" "d3d10core" "d3d11" "dxgi" "dxvk_config")
    local d8vk_dir="system/d8vk"
    local d8vk_dlls=("d3d8" "d3d9" "d3d10core" "d3d11" "dxgi")
    local vkd3d_dir="system/vkd3d"
    local vkd3d_dlls=("d3d12" "d3d12core")
    local mfplat_dir="system/mfplat"
    local mfplat_dlls=("colorcnv" "mf" "mferror" "mfplat" "mfplay" "mfreadwrite" "msmpeg2adec" "msmpeg2vdec" "sqmapi")
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
            \cp "$1" "$2"
        fi
    }
    if [ -d "$d8vk_dir" ]; then
        if [ $TDF_D8VK -eq 1 ]; then
            _outputDetail "Installing d8vk..."
            TDF_DXVK=0
            TDF_VKD3D=0
            if [ "$WINEARCH" == "win32" ]; then
                for d in "${d8vk_dlls[@]}"; do
                    copyIfDifferent "$d8vk_dir/x32/$d.dll" "$windows_dir/system32/$d.dll"
                done
            else
                for d in "${d8vk_dlls[@]}"; do
                    copyIfDifferent "$d8vk_dir/x32/$d.dll" "$windows_dir/syswow64/$d.dll"
                    copyIfDifferent "$d8vk_dir/x64/$d.dll" "$windows_dir/system32/$d.dll"
                done
            fi
            if [ ! -f "$WINEPREFIX/.d8vk-installed" ]; then
                for d in "${d8vk_dlls[@]}"; do
                    toOverride+=("$d")
                done
                touch "$WINEPREFIX/.d8vk-installed"
            fi
        else
            _outputDetail "Removing d8vk..."
            if [ -f "$WINEPREFIX/.d8vk-installed" ]; then
                for d in "${d8vk_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                wineboot -u
                wait
                rm -f "$WINEPREFIX/.d8vk-installed"
            fi
        fi
    fi
    if [ -d "$dxvk_dir" ]; then
        if [ $TDF_DXVK -eq 1 ]; then
            _outputDetail "Installing dxvk..."
            if [ "$WINEARCH" == "win32" ]; then
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
        else
            _outputDetail "Removing dxvk..."
            if [ -f "$WINEPREFIX/.dxvk-installed" ]; then
                for d in "${dxvk_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                wineboot -u
                wait
                rm -f "$WINEPREFIX/.dxvk-installed"
            fi
        fi
    fi
    if [ -d "$vkd3d_dir" ]; then
        if [ $TDF_VKD3D -eq 1 ]; then
            _outputDetail "Installing vkd3d..."
            if [ "$WINEARCH" == "win32" ]; then    
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
            _outputDetail "Removing vkd3d..."
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
    if [ -d "$mfplat_dir" ]; then
        if [ $TDF_MSMFPLAT -eq 1 ]; then
            _outputDetail "Installing MS mfplat..."
            if [ "$WINEARCH" == "win32" ]; then
                for d in "${mfplat_dlls[@]}"; do
                    copyIfDifferent "$mfplat_dir/syswow64/$d.dll" "$windows_dir/system32/$d.dll"
                done
            else
                for d in "${mfplat_dlls[@]}"; do
                    copyIfDifferent "$mfplat_dir/syswow64/$d.dll" "$windows_dir/syswow64/$d.dll"
                    copyIfDifferent "$mfplat_dir/system32/$d.dll" "$windows_dir/system32/$d.dll"
                done
            fi
            local mfplatVer="$(cat "$WINEPREFIX/.msmfplat-installed")"
            if [ "$mfplatVer" != "$TDF_VERSION" ]; then
                if [ "$WINEARCH" == "win32" ]; then
                    wine reg import "$mfplat_dir/mf.reg"
                    wine reg import "$mfplat_dir/wmf.reg"
                    wine regsvr32 colorcnv.dll
                    wine regsvr32 msmpeg2adec.dll
                    wine regsvr32 msmpeg2vdec.dll
                else
                    wine reg import "$mfplat_dir/mf.reg" /reg:32
                    wine reg import "$mfplat_dir/wmf.reg" /reg:32
                    wine reg import "$mfplat_dir/mf.reg" /reg:64
                    wine reg import "$mfplat_dir/wmf.reg" /reg:64
                    wine regsvr32 colorcnv.dll
                    wine regsvr32 msmpeg2adec.dll
                    wine regsvr32 msmpeg2vdec.dll
                    wine64 regsvr32 colorcnv.dll
                    wine64 regsvr32 msmpeg2adec.dll
                    wine64 regsvr32 msmpeg2vdec.dll
                fi
                for d in "${mfplat_dlls[@]}"; do
                    toOverride+=("$d")
                done
                echo "$TDF_VERSION" > "$WINEPREFIX/.msmfplat-installed"
                rm -f "regsvr32_d3d9.log"
            fi
        else
            _outputDetail "Removing MS mfplat..."
            if [ -f "$WINEPREFIX/.msmfplat-installed" ]; then
                for d in "${mfplat_dlls[@]}"; do
                    rm -f "$windows_dir/system32/$d.dll"
                    rm -f "$windows_dir/syswow64/$d.dll"
                    toUnoverride+=("$d")
                done
                wineboot -u
                wait
                rm -f "$WINEPREFIX/.msmfplat-installed"
            fi
        fi
    fi
    _outputDetail "Registering DLLs..."
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
        if [ $TDF_WINEMONO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winemono-installed" ]; then
                _outputDetail "Installing winemono..."
                installMonoMSI
            else
                if ! cmp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi" > /dev/null 2>&1; then
                    \cp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi"
                    _outputDetail "Updating winemono..."
                    uninstallMonoMSI
                    installMonoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winemono-installed" ]; then
                _outputDetail "Removing winemono..."
                uninstallMonoMSI
            fi
        fi
        function installGeckoMSI {
            if [ "$WINEARCH" == "win32" ]; then
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
        if [ $TDF_WINEGECKO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winegecko-installed" ]; then
                _outputDetail "Installing winegecko..."
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
                    _outputDetail "Updating winegecko..."
                    uninstallGeckoMSI
                    installGeckoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winegecko-installed" ]; then
                _outputDetail "Removing winegecko..."
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
            if [ "$WINEARCH" == "win32" ]; then
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
        if [ $TDF_VCREDIST -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.vcredist-installed" ]; then
                _outputDetail "Installing vcredist..."
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
                    _outputDetail "Updating vcredist..."
                    uninstallVCRedists
                    installVCRedists
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.vcredist-installed" ]; then
                _outputDetail "Removing vcredist..."
                uninstallVCRedists
            fi
        fi    
        
    fi
}
function _removeIntegrations {
    _outputDetail "Removing integrations..."
    local _pfxversion=$(cat "$WINEPREFIX/.initialized")
    if [ "$_pfxversion" != "$TDF_VERSION" ]; then
        if [ "$WINEARCH" == "win32" ]; then
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
    if [ $TDF_BLOCK_SYMLINKS_IN_CDRIVE -eq 1 ]; then
        ( find -L "$WINEPREFIX/drive_c/" -xtype l -exec rm {} + ) &
    fi
}
function _applyScaling {
    _outputDetail "Configuring scaling..."
    if [ $TDF_WINE_DPI -eq -1 ]; then
        if [ "$XDG_SESSION_TYPE" == "x11" ]; then
            TDF_WINE_DPI=$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)
        else #TODO: wayland support
            TDF_WINE_DPI=0
        fi
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
    _outputDetail "Configuring winedbg..."
    if [ $TDF_WINE_HIDE_CRASHES -eq 1 ]; then
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
function _removeBrokenDosdevices {
    _outputDetail "Checking symlinks..."
    _dosdevices_unprotect
    local before="$(pwd)"
    cd "$WINEPREFIX/dosdevices"
    find -L . -name . -o -type d -prune -o -type l -exec rm {} +
    cd "$before"
    _dosdevices_protect
}
function _removeUnwantedDosdevices {
    _outputDetail "Removing symlinks..."
    _dosdevices_unprotect
    local driveC=$(realpath "$WINEPREFIX/dosdevices/c:")
    for f in "$WINEPREFIX"/dosdevices/* ; do
        if [[ $(basename "$f") =~ (com)[0-9]* ]]; then
            unlink "$f"
        else
            if [ $TDF_BLOCK_EXTERNAL_DRIVES -ge 1 ]; then
                local rp=$(realpath "$f")
                if [ "$rp" != "$driveC" ] && [ "$rp" != "/" ] ; then
                    unlink "$f"
                fi
            fi
        fi
    done
    if [[ $TDF_BLOCK_ZDRIVE -ge 2  || $TDF_BLOCK_ZDRIVE -eq 1 && -n "$game_exe" ]]; then
        unlink "$WINEPREFIX/dosdevices/z:"
    fi
    _dosdevices_protect
}
function _checkAndRepairCDrive {
    _outputDetail "Checking symlinks..."
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
            zenity --error --width=500 --text="Virtual C drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
function _checkAndRepairZDrive {
    _outputDetail "Checking symlinks..."
    if [[ $TDF_BLOCK_ZDRIVE -ge 2 || $TDF_BLOCK_ZDRIVE -eq 1 && -n "$game_exe" ]]; then
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
            zenity --error --width=500 --text="Z drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
function _applyBlockBrowser {
    _outputDetail "Configuring winebrowser..."
    if [ $TDF_BLOCK_BROWSER -eq 1 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winebrowser.exe=d"
    fi
}
function _applyCorefonts {
    local windows_dir="$WINEPREFIX/drive_c/windows"
    local corefonts_dir="system/corefonts"
    local corefonts_info=("AndaleMo.TTF:Andale Mono" "Arial.TTF:Arial" "Arialbd.TTF:Arial Bold" "Arialbi.TTF:Arial Bold Italic" "Ariali.TTF:Arial Italic" "AriBlk.TTF:Arial Black" "Comic.TTF:Comic Sans MS" "Comicbd.TTF:Comic Sans MS Bold" "cour.ttf:Courier New" "courbd.ttf:Courier New Bold" "courbi.ttf:Courier New Bold Italic" "couri.ttf:Courier New Italic" "Georgia.TTF:Georgia" "Georgiab.TTF:Georgia Bold" "Georgiai.TTF:Georgia Italic" "Georgiaz.TTF:Georgia Bold Italic" "Impact.TTF:Impact" "Times.TTF:Times New Roman" "Timesbd.TTF:Times New Roman Bold" "Timesbi.TTF:Times New Roman Bold Italic" "Timesi.TTF:Times New Roman Italic" "trebuc.ttf:Trebuchet MS" "Trebucbd.ttf:Trebuchet MS Bold" "trebucbi.ttf:Trebuchet MS Bold Italic" "trebucit.ttf:Trebuchet MS Italic" "Verdana.TTF:Verdana" "Verdanab.TTF:Verdana Bold" "Verdanai.TTF:Verdana Italic" "Verdanaz.TTF:Verdana Bold Italic" "Webdings.TTF:Webdings")
    if [ -d "$corefonts_dir" ]; then
        if [ $TDF_COREFONTS -eq 1 ]; then
            _outputDetail "Installing corefonts..."
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
            _outputDetail "Removing corefonts..."
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
    if [ $TDF_FAKE_HOMEDIR -eq 1 ]; then
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

function _tdfmain {
    local _manualInit=0
    if [ "$1" == "manualInit" ]; then
        _manualInit=1
    fi
    ./system/vkgpltest
    local _res=$?
    if [ $_res -eq 0 ] || [ $_res -gt 2 ] || [ $_res -lt 0 ]; then
        zenity --error --width=500 --text="Couldn't find a GPU with Vulkan support, make sure the drivers are installed"
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
            local _confToUse=$(zenity --list --width=400 --hide-header --text="Choose a game to launch" --column="Game" "${_confs[@]}")
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
        game_exe="${game_exe##*\\}"
    fi
    _applyFakeHomeDir
    if [ "$(type -t customChecks)" == "function" ]; then
        customChecks
        if [ $? -ne 0 ]; then
            exit
        fi
    fi
    if [ "$TDF_WINE_PREFERRED_VERSION" == "games" ]; then
        export PATH="$(pwd)/system/wine-games/bin:$PATH:$(pwd)/system/wine-mainline/bin"
    elif [ "$TDF_WINE_PREFERRED_VERSION" == "mainline" ]; then
        export PATH="$(pwd)/system/wine-mainline/bin:$PATH:$(pwd)/system/wine-games/bin"
    elif [ "$TDF_WINE_PREFERRED_VERSION" == "system" ]; then
        export PATH="$PATH:$(pwd)/system/wine-mainline/bin:$(pwd)/system/wine-games/bin"
    fi
    if [ $TDF_WINEMONO -eq 0 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree="
    fi
    if [ $TDF_WINEGECKO -eq 0 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mshtml="
    fi
    export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winemenubuilder.exe=d"
    if [ $TDF_BLOCK_EXTERNAL_DRIVES -ge 2 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winedevice.exe=d"
    fi
    _applyFakeHomeDir
    local _blockNetworkCommand="unshare -nc"
    if [ $TDF_BLOCK_NETWORK -eq 2 ]; then
        command -v firejail > /dev/null
        if [ $? -eq 0 ]; then
            _blockNetworkCommand="firejail --noprofile --net=none"
        fi
    fi
    if [ $TDF_BLOCK_NETWORK -eq 0 ]; then
        _blockNetworkCommand=""
    fi
    local _gamescopeCommand=""
    if [ $TDF_GAMESCOPE -ge 1 ]; then
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
    if [ $TDF_GAMEMODE -eq 1 ]; then
        command -v gamemoderun > /dev/null
        if [ $? -ne 0 ]; then
            _gamemodeCommand=""
        fi
    else
        _gamemodeCommand=""
    fi
    local _mangohudCommand="mangohud"
    if [ $TDF_MANGOHUD -eq 1 ]; then
        command -v mangohud > /dev/null
        if [ $? -ne 0 ]; then
            _mangohudCommand=""
        fi
    else
        _mangohudCommand=""
    fi
    wine --version > /dev/null
    if [ $? -ne 0 ]; then
        zenity --error --width=500 --text="Failed to load Wine\nThis is usually caused by missing libraries (especially 32 bit libs) or broken permissions"
        exit
    fi
    if [ "$TDF_WINE_SYNC" = "fsync" ]; then
        ./system/futex2test
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
        zenity --error --text="Invalid TDF_WINE_ARCH. Must be win32 or win64"
        exit
    fi
    local _flockid=$(( RANDOM % 10000 + 400 ))
    if [ -f "$WINEPREFIX/.flockid" ]; then
        _flockid=$(cat "$WINEPREFIX/.flockid")
        _flockid=$(( _flockid ))
    else
        echo $_flockid > "$WINEPREFIX/.flockid"
    fi
    local _skipInitializations=0
    exec {_flockid}<"$0"
    flock -n -e $_flockid
    if [ $? -ne 0 ]; then
        if [ -e "$WINEPREFIX/.initialized" ]; then
            local _pfxversion=$(cat "$WINEPREFIX/.initialized")
            if [ "$_pfxversion" == "$TDF_VERSION" ]; then
                if [ "$TDF_MULTIPLE_INSTANCES" == "close" ]; then
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" == "error" ]; then
                    zenity --error --text="This application is already running"
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" == "askcmd" ]; then
                    zenity --question --width=400 --text="This wineprefix is already running\nOpen a command prompt inside it?"
                    if [ $? -eq 0 ]; then
                        _realRunCommandPrompt
                    fi
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" == "cmd" ]; then
                    _realRunCommandPrompt
                    exit
                elif [ "$TDF_MULTIPLE_INSTANCES" == "allow" ]; then
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
    if [ $TDF_WINE_KILL_BEFORE -eq 1 ]; then
        _killWine
    fi
    if [ -d "$WINEPREFIX" ]; then
        if [ -n "$WINEARCH" ]; then
            local _pfxarch=$(cat "$WINEPREFIX/system.reg" | grep -m 1 '#arch' | cut -d '=' -f2)
            if [ "$_pfxarch" != "$WINEARCH" ]; then
                zenity --error --width=500 --text="WINEARCH mismatch\n\nThis wineprefix:$_pfxarch\nRequested:$WINEARCH\n\nWINEARCH cannot be changed after initialization"
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
                _outputDetail "Starting wine..."
                local _realOverrides="$WINEDLLOVERRIDES"
                export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
                wineboot
                wait
                echo "30"
                _applyDLLs
                echo "40"
                _applyMSIs
                echo "55"
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
                _outputDetail "Launching game..."
                wineserver -k -w
                wait
                echo "100"
                echo "$TDF_VERSION" > "$WINEPREFIX/.initialized"
            fi
        ) | zenity --progress --no-cancel --text="Launching..." --width=250 --auto-close --auto-kill
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
            _outputDetail "Starting wine..."
            local _realOverrides="$WINEDLLOVERRIDES"
            export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
            wineboot -i
            wait
            echo "30"
            while ! test -f "$WINEPREFIX/system.reg"; do
                sleep 1
            done
            echo "30"
            _applyDLLs
            echo "40"
            _applyMSIs
            echo "55"
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
            _outputDetail "Starting..."
            wineserver -k -w
            wait
            echo "100"
            echo "$TDF_VERSION" > "$WINEPREFIX/.initialized"
        ) | zenity --progress --no-cancel --text="Initializing a new wineprefix, this may take a while" --width=500 --auto-close --auto-kill
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
    if [ $TDF_WINE_KILL_AFTER -eq 1 ]; then
        _killWine
    fi
}

_tdfmain $@
