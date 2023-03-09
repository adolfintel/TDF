#!/bin/bash
shopt -s expand_aliases
export LC_ALL=C

LAUNCHER_VERSION="$(cat system/version)"

game_workingDir=''
game_exe=''
game_args=''

USE_DXVK=1
USE_DXVK_ASYNC=2
USE_D8VK=0
USE_VKD3D=1
USE_WINEMONO=0
USE_WINEGECKO=0
USE_VCREDIST=1
USE_GAMESCOPE=0
GAMESCOPE_PREFER_SYSTEM=1
USE_GAMEMODE=1
USE_MANGOHUD=0
USE_COREFONTS=1
USE_MICROSOFT_MFPLAT=0
HIDE_CRASHES=1
BLOCK_NETWORK=1
BLOCK_NETWORK_PREFER_FIREJAIL=0
BLOCK_BROWSER=1
BLOCK_ZDRIVE=2
BLOCK_EXTERNAL_DRIVES=1
USE_FAKE_HOMEDIR=0
WINE_PREFER_SYSTEM=0
WINE_DPI=-1
KILL_WINE_BEFORE=0
KILL_WINE_AFTER=0
IGNORE_EXIST_CHECKS=0
HIDE_GAME_RUNNING_DIALOG=0
SHOW_PLAY_TIME=0
export DXVK_ASYNC=1
#export VKD3D_FEATURE_LEVEL=12_2
export VKD3D_CONFIG=dxr11
export WINEARCH=win64
export WINEESYNC=0
export WINEFSYNC=1
export WINE_LARGE_ADDRESS_AWARE=1
additionalStartArgs=''
export WINEPREFIX="$(pwd)/zzprefix"
export USER="wine"
export DXVK_CONFIG_FILE="$WINEPREFIX/dxvk.conf"
export D8VK_CONFIG_FILE="$WINEPREFIX/d8vk.conf"
SYSTEM_LANGUAGE=''
ENABLE_RELAY=0
ZENITY_PREFER_SYSTEM=1
DETAILED_ZENITY_OUTPUT=1
LAUNCHER_TITLE="Launcher"

if [ -z $1 ]; then
    echo "This script should not be run directly, use run.sh instead"
    exit
fi

alias zenity='zenity --title="$LAUNCHER_TITLE"'

if [ $ZENITY_PREFER_SYSTEM -eq 1 ] && [ -f "/usr/bin/zenity" ]; then
    alias zenity='/usr/bin/zenity --title="$LAUNCHER_TITLE"'
fi

outputDetail(){
    if [ $DETAILED_ZENITY_OUTPUT -eq 1 ];then
        echo "#$1"
    fi
}

manualInit=0
if [ $1 == "manualInit" ]; then
    manualInit=1
fi
./system/vkgpltest
if [ $? -eq 0 ] || [ $? -gt 2 ] || [ $? -lt 0 ]; then
    zenity --error --width=500 --text="Couldn't find a GPU with Vulkan support, make sure the drivers are installed"
    exit
fi
if [ -e "system/xdotool" ]; then
    export PATH="$PATH:$(pwd)/system/xdotool"
fi
if [ -f "vars.conf" ]; then
    source "./vars.conf"
fi
if [ -d "confs" ]; then
    confs=()
    for f in confs/*.conf; do
        if [ -f "$f" ]; then 
            f=$(basename "$f" ".conf")
            confs+=("$f")
        fi
    done
    if [ ${#confs[@]} -ne 0 ]; then
        confToUse=$(zenity --list --width=400 --hide-header --text="Choose a game to launch" --column="Game" "${confs[@]}")
        if [ -z "$confToUse" ]; then
            exit
        fi
        confToUse="confs/$confToUse.conf"
        source "$confToUse"
    fi
fi
game_workingDir=$( echo ${game_workingDir//\//\\} )
game_exe=$( echo ${game_exe//\//\\} )
if [ -z "$game_workingDir" ]; then
    game_workingDir=$( echo ${game_exe%\\*} )
    game_exe=$( echo ${game_exe##*\\} )
fi
if [ $WINE_PREFER_SYSTEM -eq 1 ]; then
    export PATH="$PATH:$(pwd)/system/wine/bin"
else
    export PATH="$(pwd)/system/wine/bin:$PATH"
fi
if [ $USE_WINEMONO -eq 0 ]; then
    export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree="
fi
if [ $USE_WINEGECKO -eq 0 ]; then
    export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mshtml="
fi
export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winemenubuilder.exe=d"
if [ $BLOCK_EXTERNAL_DRIVES -ge 2 ]; then
    export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winedevice.exe=d"
fi
if [ $USE_FAKE_HOMEDIR -eq 1 ]; then
    export HOME="$(pwd)/zzhome"
    if [ ! -d "$HOME" ]; then
        mkdir "$HOME"
    fi
else
    if [ -d "$(pwd)/zzhome" ]; then
        rm -rf "$(pwd)/zzhome"
    fi
fi
debotnetPrefix="unshare -nr "
if [ $BLOCK_NETWORK_PREFER_FIREJAIL -eq 1 ]; then
    command -v firejail > /dev/null
    if [ $? -eq 0 ]; then
        debotnetPrefix="firejail --net=none "
    fi
fi
if [ $BLOCK_NETWORK -eq 0 ]; then
    debotnetPrefix=""
fi
if [ $USE_GAMESCOPE -ge 1 ]; then
    gamescopePrefix="./system/gamescope/runInsideGS.sh"
    if [ $GAMESCOPE_PREFER_SYSTEM -eq 1 ]; then
        export PATH="$PATH:$(pwd)/system/gamescope"
    else
        export PATH="$(pwd)/system/gamescope:$PATH"
    fi
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/system/gamescope"
else
    gamescopePrefix=""
fi
gamemodePrefix="gamemoderun "
if [ $USE_GAMEMODE -eq 1 ]; then
    command -v gamemoderun > /dev/null
    if [ $? -ne 0 ]; then
        gamemodePrefix=""
    fi
else
    gamemodePrefix=""
fi
mangohudPrefix="mangohud "
if [ $USE_MANGOHUD -eq 1 ]; then
    command -v mangohud > /dev/null
    if [ $? -ne 0 ]; then
        mangohudPrefix=""
    fi
else
    mangohudPrefix=""
fi
if [ $WINEFSYNC -eq 1 ]; then
    ./system/futex2test
    if [ $? -ne 0 ]; then
        export WINEFSYNC=0
    fi
fi
wine --version
if [ $? -ne 0 ]; then
    zenity --error --width=500 --text="Failed to load Wine\nThis is usually caused by missing libraries (especially 32 bit libs) or broken permissions"
    exit
fi
if [ "$(type -t customChecks)" == "function" ]; then
    customChecks
fi
justRunManualCommand(){
    $debotnetPrefix wine start /WAIT $1
}
justLaunchCommandPrompt(){
    $debotnetPrefix wine start /D "C:\\Windows\\System32" /WAIT "cmd.exe"
}
launchCommandPrompt(){
    if [ $manualInit -eq 1 ]; then
        return
    fi
    zenity --info --width=500 --text="A Wine command prompt will now open, use it to install the game and then close it.\nDo not launch the game yet" &
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL="$SYSTEM_LANGUAGE"
    fi
    justLaunchCommandPrompt
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL=C
    fi
    zenity --info --width=500 --text="Good, now edit vars.conf and set game_exe to the Windows-style path to the game's exe file"
}
justLaunchGame(){
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL="$SYSTEM_LANGUAGE"
    fi
    if [ "$(type -t onGameStart)" == "function" ]; then
        onGameStart
    fi
    if [ "$(type -t whileGameRunning)" == "function" ]; then
        (
            whileGameRunning
        ) &
    fi
    if [ $ENABLE_RELAY -eq 1 ]; then
        relayPath=$(zenity --file-selection --save --title="Where do you want to save the trace?" --filename="relay.txt")
        if [ ! -z "$relayPath" ]; then
            WINEDEBUG=+relay $gamemodePrefix $gamescopePrefix $mangohudPrefix $debotnetPrefix wine start /D "$game_workingDir" /WAIT $additionalStartArgs "$game_exe" $game_args > $relayPath 2>&1
        fi
    else
        $gamemodePrefix $gamescopePrefix $mangohudPrefix $debotnetPrefix wine start /D "$game_workingDir" /WAIT $additionalStartArgs "$game_exe" $game_args
    fi
    if [ "$(type -t onGameEnd)" == "function" ]; then
        onGameEnd
    fi
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL=C
    fi
}
launchGame(){
    if [ $manualInit -eq 1 ]; then
        return
    fi
    wdir=$(winepath -u "$game_workingDir" 2> /dev/null)
    if [ -d "$wdir" ] || [ $IGNORE_EXIST_CHECKS -eq 1 ]; then
        fpath=$(winepath -u "$game_workingDir\\$game_exe" 2> /dev/null)
        if [ -f "$fpath" ]  || [ $IGNORE_EXIST_CHECKS -eq 1 ] ; then
            startedAt=$SECONDS
            if [ $HIDE_GAME_RUNNING_DIALOG -eq 1 ]; then
                justLaunchGame
            else
                (
                    justLaunchGame
                ) | zenity --progress --no-cancel --text="Game running" --width=250 --auto-kill --auto-close
            fi
            wait
            playedTime=$((SECONDS - startedAt))
            ss=$((playedTime % 60))
            mm=$(( ( playedTime / 60 ) % 60 ))
            hh=$((playedTime/3600))
            if [ $ss -lt 10 ]; then
                ss="0$ss"
            fi
            if [ $mm -lt 10 ]; then
                mm="0$mm"
            fi
            if [ $hh -lt 10 ]; then
                hh="0$hh"
            fi
            if [ $SHOW_PLAY_TIME -eq 1 ]; then
                zenity --info --width=300 --text="Played for $hh:$mm:$ss"
            fi
        else
            zenity --error --width=500 --text="Configuration error: the specified game_exe does not exist"
        fi
    else
        zenity --error --width=500 --text="Configuration error: the specified game_workingDir does not exist"
    fi
}
applyDllsIfNeeded(){
    outputDetail "Copying DLLs..."
    windows_dir="$WINEPREFIX/drive_c/windows"
    if [ $USE_DXVK_ASYNC -eq 2 ]; then
        ./system/vkgpltest
        if [ $? -eq 2 ]; then
            USE_DXVK_ASYNC=0
        else
            USE_DXVK_ASYNC=1
        fi
    fi
    dxvk_dir="system/dxvk"
    if [ $USE_DXVK_ASYNC -eq 1 ]; then
        dxvk_dir="$dxvk_dir-async"
    fi
    dxvk_dlls=("d3d9" "d3d10" "d3d10_1" "d3d10core" "d3d11" "dxgi")
    d8vk_dir="system/d8vk"
    d8vk_dlls=("d3d8" "d3d9" "d3d10core" "d3d11" "dxgi")
    vkd3d_dir="system/vkd3d"
    vkd3d_dlls=("d3d12")
    mfplat_dir="system/mfplat"
    mfplat_dlls=("colorcnv" "mf" "mferror" "mfplat" "mfplay" "mfreadwrite" "msmpeg2adec" "msmpeg2vdec" "sqmapi")
    toOverride=()
    toUnoverride=()
    overrideDll() {
        wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $1 /d 'native,builtin' /f
    }
    unoverrideDll() {
        wine reg delete 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $1 /f
    }
    copyIfDifferent(){
        if ! cmp "$1" "$2" > /dev/null 2>&1; then
            yes | cp "$1" "$2"
        fi
    }
    if [ -e "$d8vk_dir" ]; then
        if [ $USE_D8VK -eq 1 ]; then
            outputDetail "Installing d8vk..."
            USE_DXVK=0
            USE_VKD3D=0
            if [ ! -f "$D8VK_CONFIG_FILE" ]; then
                cp -f "$d8vk_dir/d8vk.conf.template" "$D8VK_CONFIG_FILE"
                export DXVK_CONFIG_FILE="$D8VK_CONFIG_FILE"
            fi
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
            outputDetail "Removing d8vk..."
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
    if [ -e "$dxvk_dir" ]; then
        if [ $USE_DXVK -eq 1 ]; then
            outputDetail "Installing dxvk..."
            if [ ! -f "$DXVK_CONFIG_FILE" ]; then
                cp -f "$dxvk_dir/dxvk.conf.template" "$DXVK_CONFIG_FILE"
            fi
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
            outputDetail "Removing dxvk..."
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
    if [ -e "$vkd3d_dir" ]; then
        if [ $USE_VKD3D -eq 1 ]; then
            outputDetail "Installing vkd3d..."
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
            outputDetail "Removing vkd3d..."
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
    if [ -e "$mfplat_dir" ]; then
        if [ $USE_MICROSOFT_MFPLAT -eq 1 ]; then
            outputDetail "Installing MS mfplat..."
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
            mfplatVer="$(cat "$WINEPREFIX/.msmfplat-installed")"
            if [ "$mfplatVer" != "$LAUNCHER_VERSION" ]; then
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
                echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.msmfplat-installed"
                rm -f "regsvr32_d3d9.log"
            fi
        else
            outputDetail "Removing MS mfplat..."
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
    outputDetail "Registering DLLs..."
    for d in "${toUnoverride[@]}"; do
        unoverrideDll "$d"
    done
    for d in "${toOverride[@]}"; do
        overrideDll "$d"
    done
}
applyMsisIfNeeded(){
    msi_dir="system/msi"
    if [ -e "$msi_dir" ]; then
        installMonoMSI(){
            yes | cp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi"
            wine msiexec /i "C:\\winemono.msi"
            wait
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.winemono-installed"
        }
        uninstallMonoMSI(){
            wine msiexec /uninstall "C:\\winemono.msi"
            wait
        }
        if [ $USE_WINEMONO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winemono-installed" ]; then
                outputDetail "Installing winemono..."
                installMonoMSI
            else
                winemonoVer="$(cat "$WINEPREFIX/.winemono-installed")"
                if [ "$winemonoVer" != "$LAUNCHER_VERSION" ]; then
                    outputDetail "Updating winemono..."
                    uninstallMonoMSI
                    installMonoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winemono-installed" ]; then
                outputDetail "Removing winemono..."
                uninstallMonoMSI
                rm -f "$WINEPREFIX/.winemono-installed"
                rm -f "$WINEPREFIX/drive_c/winemono.msi"
            fi
        fi
        installGeckoMSI(){
            if [ "$WINEARCH" == "win32" ]; then
                yes | cp "$msi_dir/winegecko32.msi" "$WINEPREFIX/drive_c/winegecko32.msi"
                wine msiexec /i "C:\\winegecko32.msi"
            else
                yes | cp "$msi_dir/winegecko32.msi" "$WINEPREFIX/drive_c/winegecko32.msi"
                wine msiexec /i "C:\\winegecko32.msi"
                yes | cp "$msi_dir/winegecko64.msi" "$WINEPREFIX/drive_c/winegecko64.msi"
                wine msiexec /i "C:\\winegecko64.msi"
            fi
            wait
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.winegecko-installed"
        }
        uninstallGeckoMSI(){
            wine msiexec /uninstall "C:\\winegecko32.msi"
            wine msiexec /uninstall "C:\\winegecko64.msi"
            wait
        }
        if [ $USE_WINEGECKO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winegecko-installed" ]; then
                outputDetail "Installing winegecko..."
                installGeckoMSI
            else
                winegeckoVer="$(cat "$WINEPREFIX/.winegecko-installed")"
                if [ "$winegeckoVer" != "$LAUNCHER_VERSION" ]; then
                    outputDetail "Updating winegecko..."
                    uninstallGeckoMSI
                    installGeckoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winegecko-installed" ]; then
                outputDetail "Removing winegecko..."
                uninstallGeckoMSI
                rm -f "$WINEPREFIX/.winegecko-installed"
                rm -f "$WINEPREFIX/drive_c/winegecko32.msi"
                rm -f "$WINEPREFIX/drive_c/winegecko64.msi"
            fi
        fi
    fi
}
applyVCRedistsIfNeeded(){
    vc_dir="system/vcredist"
    if [ -e "$vc_dir" ]; then
        installVCRedists(){
            wineserver -k -w
            wait
            mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/.templink"
            if [ $WINEARCH == "win32" ]; then
                yes | cp "$vc_dir/vc_redist.x86.exe" "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                wine "C:\\vc_redist.x86.exe" /install /quiet /norestart
            else
                yes | cp "$vc_dir/vc_redist.x86.exe" "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                yes | cp "$vc_dir/vc_redist.x64.exe" "$WINEPREFIX/drive_c/vc_redist.x64.exe"
                wine "C:\\vc_redist.x86.exe" /install /quiet /norestart
                wine "C:\\vc_redist.x64.exe" /install /quiet /norestart
            fi
            wait
            wineserver -k -w
            wait
            mv "$WINEPREFIX/.templink" "$WINEPREFIX/dosdevices/z:"
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.vcredist-installed"
        }
        uninstallVCRedists(){
            wineserver -k -w
            wait
            mv "$WINEPREFIX/dosdevices/z:" "$WINEPREFIX/.templink"
            wine "C:\\vc_redist.x86.exe" /uninstall /quiet /norestart
            wine "C:\\vc_redist.x64.exe" /uninstall /quiet /norestart
            wait
            wineserver -k -w
            wait
            mv "$WINEPREFIX/.templink" "$WINEPREFIX/dosdevices/z:"
        }
        if [ $USE_VCREDIST -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.vcredist-installed" ]; then
                outputDetail "Installing vcredist..."
                installVCRedists
            else
                vcredistVer="$(cat "$WINEPREFIX/.vcredist-installed")"
                if [ "$vcredistVer" != "$LAUNCHER_VERSION" ]; then
                    outputDetail "Updating vcredist..."
                    uninstallVCRedists
                    installVCRedists
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.vcredist-installed" ]; then
                outputDetail "Removing vcredist..."
                uninstallVCRedists
                rm -f "$WINEPREFIX/.vcredist-installed"
                rm -f "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                rm -f "$WINEPREFIX/drive_c/vc_redist.x64.exe"
            fi
        fi    
        
    fi
}
deIntegrateIfNeeded(){
    outputDetail "Removing integrations..."
    prefixVersion=$(cat "$WINEPREFIX/.initialized")
    if [ "$prefixVersion" != "$LAUNCHER_VERSION" ]; then
        if [ $WINEARCH == "win32" ]; then
            wine reg delete 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine reg delete 'HKEY_CLASSES_ROOT\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
        else
            wine64 reg delete 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine64 reg delete 'HKEY_CLASSES_ROOT\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
            wine64 reg delete 'HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' /f
        fi
    fi
    deIntegrate(){
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
}
applyDpi(){
    outputDetail "Configuring scaling..."
    if [ $WINE_DPI -eq -1 ]; then
        if [ $XDG_SESSION_TYPE == "x11" ]; then
            WINE_DPI=$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)
        else #TODO: wayland support
            WINE_DPI=0
        fi
    fi
    if [ "$WINE_DPI" -ne 0 ]; then
        currentDpi=0
        if [ -e "$WINEPREFIX/.dpi" ]; then
            currentDpi=$(cat "$WINEPREFIX/.dpi")
        fi
        if [ "$WINE_DPI" != "$currentDpi" ]; then
            wine reg add 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /t REG_DWORD /d "$WINE_DPI" /f
            echo "$WINE_DPI" > "$WINEPREFIX/.dpi"
        fi
    else
        if [ -e "$WINEPREFIX/.dpi" ]; then
            wine reg delete 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' /v 'LogPixels' /f
            rm -f "$WINEPREFIX/.dpi"
        fi
    fi
}
hideCrashesIfNeeded(){
    outputDetail "Configuring winedbg..."
    if [ $HIDE_CRASHES -eq 1 ]; then
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
removeBrokenSymlinks(){
    outputDetail "Checking symlinks..."
    cd "$WINEPREFIX/dosdevices"
    find -L . -name . -o -type d -prune -o -type l -exec rm {} +
    cd ../..
}
removeUnnecessarySymlinks(){
    outputDetail "Removing symlinks..."
    driveC=$(realpath "$WINEPREFIX/dosdevices/c:")
        for f in "$WINEPREFIX"/dosdevices/* ; do
            if [[ $(basename "$f") =~ (com)[0-9]* ]]; then
                unlink "$f"
            else
                if [ $BLOCK_EXTERNAL_DRIVES -ge 1 ]; then
                    rp=$(realpath "$f")
                    if [ "$rp" != "$driveC" -a "$rp" != "/" ] ; then
                        unlink "$f"
                    fi
                fi
            fi
        done
    if [[ $BLOCK_ZDRIVE -eq 1  || ( "$1" == "game"  && $BLOCK_ZDRIVE -eq 2 ) ]]; then
        unlink "$WINEPREFIX/dosdevices/z:"
    fi
}
repairDriveCIfNeeded(){
    outputDetail "Checking symlinks..."
    link=$(realpath "$WINEPREFIX/dosdevices/c:")
    target=$(realpath "$WINEPREFIX/drive_c")
    if [ "$link" != "$target" ]; then
        link="$WINEPREFIX/dosdevices/c:"
        rm -rf "$link"
        ln -s "$target" "$link"
        link=$(realpath "$link")
        if [ "$link" != "$target" ]; then
            touch "$WINEPREFIX/.abort"
            zenity --error --width=500 --text="Virtual C drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
repairDriveZIfNeeded(){
    outputDetail "Checking symlinks..."
    if [ $BLOCK_ZDRIVE -ge 1 ]; then
        return
    fi
    link=$(realpath "$WINEPREFIX/dosdevices/z:")
    target="/"
    if [ "$link" != "$target" ]; then
        link="$WINEPREFIX/dosdevices/z:"
        rm -rf "$link"
        ln -s "$target" "$link"
        link=$(realpath "$link")
        if [ "$link" != "$target" ]; then
            touch "$WINEPREFIX/.abort"
            zenity --error --width=500 --text="Z drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
blockBrowserIfNeeded(){
    outputDetail "Configuring winebrowser..."
    if [ $BLOCK_BROWSER -eq 1 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winebrowser.exe=d"
    fi
}
killWine(){
    #ls -l /proc/*/exe 2>/dev/null | grep -E 'wine(64)?-preloader|wineserver' | perl -pe 's;^.*/proc/(\d+)/exe.*$;$1;g;' | xargs -n 1 kill -9
    wineserver -k -w
    wait
}
applyCorefontsIfNeeded(){
    windows_dir="$WINEPREFIX/drive_c/windows"
    corefonts_dir="system/corefonts"
    corefonts_info=("AndaleMo.TTF:Andale Mono" "Arial.TTF:Arial" "Arialbd.TTF:Arial Bold" "Arialbi.TTF:Arial Bold Italic" "Ariali.TTF:Arial Italic" "AriBlk.TTF:Arial Black" "Comic.TTF:Comic Sans MS" "Comicbd.TTF:Comic Sans MS Bold" "cour.ttf:Courier New" "courbd.ttf:Courier New Bold" "courbi.ttf:Courier New Bold Italic" "couri.ttf:Courier New Italic" "Georgia.TTF:Georgia" "Georgiab.TTF:Georgia Bold" "Georgiai.TTF:Georgia Italic" "Georgiaz.TTF:Georgia Bold Italic" "Impact.TTF:Impact" "Times.TTF:Times New Roman" "Timesbd.TTF:Times New Roman Bold" "Timesbi.TTF:Times New Roman Bold Italic" "Timesi.TTF:Times New Roman Italic" "trebuc.ttf:Trebuchet MS" "Trebucbd.ttf:Trebuchet MS Bold" "trebucbi.ttf:Trebuchet MS Bold Italic" "trebucit.ttf:Trebuchet MS Italic" "Verdana.TTF:Verdana" "Verdanab.TTF:Verdana Bold" "Verdanai.TTF:Verdana Italic" "Verdanaz.TTF:Verdana Bold Italic" "Webdings.TTF:Webdings")
    if [ -e "$corefonts_dir" ]; then
        if [ $USE_COREFONTS -eq 1 ]; then
            outputDetail "Installing corefonts..."
            if [ ! -f "$WINEPREFIX/.corefonts-installed" ]; then
                commands=""
                copyAndRegister(){
                    cp -f "$corefonts_dir/$1" "$windows_dir/Fonts"
                    commands="$commands /v '$2' /t REG_SZ /d '$1' "
                }
                oldIFS=$IFS
                IFS=':'
                for f in "${corefonts_info[@]}"; do
                    for d in $f; do
                        copyAndRegister ${d[0]} ${d[1]}
                    done
                done
                IFS=$oldIFS
                wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' $commands /f
                wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' /v '$2' /t REG_SZ /d '$1' $commands /f
                touch "$WINEPREFIX/.corefonts-installed"
            fi
        else
            outputDetail "Removing corefonts..."
            if [ -f "$WINEPREFIX/.corefonts-installed" ]; then
                commands=""
                deleteAndUnregister(){
                    windows_dir="$WINEPREFIX/drive_c/windows"
                    corefonts_dir="system/corefonts"
                    rm -f "$windows_dir/Fonts/$1"
                    commands="$commands /v '$2'"
                }
                oldIFS=$IFS
                IFS=':'
                for f in "${corefonts_info[@]}"; do
                    for d in $f; do
                        deleteAndUnregister ${d[0]} ${d[1]}
                    done
                done
                IFS=$oldIFS
                wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' $commands /f
                wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' $commands /f
                rm -f "$WINEPREFIX/.corefonts-installed"
            fi
        fi
    fi
}
RANDOM=$(date +%s%N | cut -b10-19)
flockid=$(( $RANDOM % 10000 + 400 ))
if [ -f "$WINEPREFIX/.flockid" ]; then
    flockid=$(cat "$WINEPREFIX/.flockid")
    flockid=$(( $flockid ))
else
    echo $flockid > "$WINEPREFIX/.flockid"
fi
exec {flockid}<"$0"
flock -n -e $flockid
if [ $? -ne 0 ]; then
    if [ -e "$WINEPREFIX/.initialized" ]; then
        prefixVersion=$(cat "$WINEPREFIX/.initialized")
        if [ "$prefixVersion" == "$LAUNCHER_VERSION" ]; then
            zenity --question --width=400 --text="This wineprefix is already running\nOpen a command prompt inside it?"
            if [ $? -eq 0 ]; then
                justLaunchCommandPrompt
            fi
        fi
    fi
    exit
fi
if [ $KILL_WINE_BEFORE -eq 1 ]; then
    killWine
fi
if [ -d "$WINEPREFIX" ]; then
    if [ ! -z $WINEARCH ]; then
        architecture=$(cat "$WINEPREFIX/system.reg" | grep -m 1 '#arch' | cut -d '=' -f2)
        if [ "$architecture" != "$WINEARCH" ]; then
            zenity --error --width=500 --text="WINEARCH mismatch\n\nThis wineprefix:$architecture\nRequested:$WINEARCH\n\nWINEARCH cannot be changed after initialization"
            exit
        fi
    fi
    rm -f "$WINEPREFIX/.abort"
    (
        echo "1"
        removeBrokenSymlinks
        repairDriveCIfNeeded
        repairDriveZIfNeeded
        echo "10"
        outputDetail "Starting wine..."
        realOverrides="$WINEDLLOVERRIDES"
        export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
        wineboot
        wait
        export WINEDLLOVERRIDES="$realOverrides"
        echo "30"
        applyDllsIfNeeded
        echo "40"
        applyMsisIfNeeded
        echo "55"
        hideCrashesIfNeeded
        echo "60"
        applyCorefontsIfNeeded
        echo "70"
        deIntegrateIfNeeded
        echo "75"
        applyDpi
        echo "80"
        applyVCRedistsIfNeeded
        echo "90"
        removeUnnecessarySymlinks "game"
        echo "95"
        wait
        outputDetail "Launching game..."
        wineserver -k -w
        wait
        echo "100"
        echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.initialized"
    ) | zenity --progress --no-cancel --text="Launching..." --width=250 --auto-close --auto-kill
    wait
    if [ -f "$WINEPREFIX/.abort" ]; then
        rm -f "$WINEPREFIX/.abort"
        exit
    fi
    blockBrowserIfNeeded
    if [ $manualInit -eq 1 ]; then
        if [ ! -z "$2" ]; then
            justRunManualCommand $2
        fi
    fi
    if [ -z "$game_exe" ]; then
        launchCommandPrompt
    else
        launchGame
    fi
else
    (
        echo "10"
        outputDetail "Starting wine..."
        realOverrides="$WINEDLLOVERRIDES"
        export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
        wineboot -i
        wait
        echo "30"
        while ! test -f "$WINEPREFIX/system.reg"; do
            sleep 1
        done
        export WINEDLLOVERRIDES="$realOverrides"
        echo "30"
        applyDllsIfNeeded
        echo "40"
        applyMsisIfNeeded
        echo "55"
        hideCrashesIfNeeded
        echo "60"
        applyCorefontsIfNeeded
        echo "70"
        deIntegrateIfNeeded
        echo "75"
        applyDpi
        echo "80"
        applyVCRedistsIfNeeded
        echo "90"
        removeUnnecessarySymlinks "init"
        echo "95"
        wait
        outputDetail "Starting..."
        wineserver -k -w
        wait
        echo "100"
        echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.initialized"
    ) | zenity --progress --no-cancel --text="Initializing a new wineprefix, this may take a while" --width=500 --auto-close --auto-kill
    wait
    blockBrowserIfNeeded
    if [ $manualInit -eq 1 ]; then
        if [ ! -z "$2" ]; then
            justRunManualCommand $2
        fi
    else
        launchCommandPrompt
    fi
fi
if [ $KILL_WINE_AFTER -eq 1 ]; then
    killWine
fi
