#!/bin/bash
export LC_ALL=C

LAUNCHER_VERSION="$(cat system/version)"

game_workingDir=''
game_exe=''
game_args=''

USE_DXVK=1
USE_DXVK_ASYNC=2
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
BLOCK_ZDRIVE=0
BLOCK_EXTERNAL_DRIVES=1
USE_FAKE_HOMEDIR=0
WINE_PREFER_SYSTEM=0
KILL_WINE_BEFORE=0
KILL_WINE_AFTER=0
IGNORE_EXIST_CHECKS=0
HIDE_GAME_RUNNING_DIALOG=0
SHOW_PLAY_TIME=0
export DXVK_ASYNC=1
export VKD3D_CONFIG=dxr11
export WINEARCH=win64
export WINEESYNC=0
export WINEFSYNC=1
gamescopeParameters="-f"
additionalStartArgs=''
export WINEPREFIX="$(pwd)/zzprefix"
export USER="wine"
export DXVK_CONFIG_FILE="$WINEPREFIX/dxvk.conf"
SYSTEM_LANGUAGE=''
ENABLE_RELAY=0

alias zenity='zenity --title "Launcher $LAUNCHER_VERSION"'

if [ -z $1 ]; then
    echo "This script should not be run directly, use run.sh instead"
    exit
fi

manualInit=0
if [ $1 == "manualInit" ]; then
    manualInit=1
fi
./system/vkgpltest
if [ $? -eq 0 ] || [ $? -gt 2 ] || [ $? -lt 0 ]; then
    zenity --error --width 500 --text "Couldn't find a GPU with Vulkan support, make sure the drivers are installed"
    exit
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
        confToUse=$(zenity --list --width 400 --hide-header --text "Choose a game to launch" --column="Game" "${confs[@]}")
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
    command -v wine > /dev/null
    if [ $?-ne 0 ]; then
        export PATH="$(pwd)/system/wine/bin:$PATH"
    fi
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
gamescopePrefix="gamescope $gamescopeParameters -- "
if [ $USE_GAMESCOPE -ge 1 ]; then
    if [ $GAMESCOPE_PREFER_SYSTEM -eq 1 ]; then
        command -v gamescope > /dev/null
        if [ $? -ne 0 ]; then
            export PATH="$(pwd)/system/gamescope:$PATH"
        fi
    else
        export PATH="$(pwd)/system/gamescope:$PATH"
    fi
    gamescope -f -- sleep 0.1
    if [ $? -ne 0 ]; then 
        gamescopePrefix=""
    fi
else
    gamescopePrefix=""
fi
if [ $USE_GAMESCOPE -eq 2 ]; then
    if [ -z "$gamescopePrefix" ]; then
        zenity --error --width 400 --text "Gamescope is required for this game but it's not working"
        exit
    fi
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
    zenity --error --width 500 --text "Failed to load Wine\nThis is usually caused by missing libraries (especially 32 bit libs) or broken permissions"
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
    zenity --info --width 500 --text "A Wine command prompt will now open, use it to install the game and then close it.\nDo not launch the game yet"
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL="$SYSTEM_LANGUAGE"
    fi
    justLaunchCommandPrompt
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL=C
    fi
    zenity --info --width 500 --text "Good, now edit vars.conf and set game_exe to the Windows-style path to the game's exe file"
}
justLaunchGame(){
    if [ $WINEESYNC -eq 1 ] || [ $WINEFSYNC -eq 1 ]; then
        wineserver -k -w
        wait
    fi
    if [ ! -z "$SYSTEM_LANGUAGE" ]; then
        export LC_ALL="$SYSTEM_LANGUAGE"
    fi
    if [ "$(type -t onGameStart)" == "function" ]; then
        onGameStart
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
                ) | zenity --progress --no-cancel --text="Game running" --width=200 --auto-kill --auto-close
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
                zenity --info --width 300 --text "Played for $hh:$mm:$ss"
            fi
        else
            zenity --error --width 500 --text "Configuration error: the specified game_exe does not exist"
        fi
    else
        zenity --error --width 500 --text "Configuration error: the specified game_workingDir does not exist"
    fi
}
applyDllsIfNeeded(){
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
    vkd3d_dir="system/vkd3d"
    mfplat_dir="system/mfplat"
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
    if [ -e "$dxvk_dir" ]; then
        if [ $USE_DXVK -eq 1 ]; then
            if [ ! -f "$DXVK_CONFIG_FILE" ]; then
                touch "$DXVK_CONFIG_FILE"
            fi
            if [ "$WINEARCH" == "win32" ]; then
                copyIfDifferent "$dxvk_dir/x32/d3d9.dll" "$windows_dir/system32/d3d9.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10.dll" "$windows_dir/system32/d3d10.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10_1.dll" "$windows_dir/system32/d3d10_1.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10core.dll" "$windows_dir/system32/d3d10core.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d11.dll" "$windows_dir/system32/d3d11.dll"
                copyIfDifferent "$dxvk_dir/x32/dxgi.dll" "$windows_dir/system32/dxgi.dll"
            else
                copyIfDifferent "$dxvk_dir/x32/d3d9.dll" "$windows_dir/syswow64/d3d9.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10.dll" "$windows_dir/syswow64/d3d10.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10_1.dll" "$windows_dir/syswow64/d3d10_1.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d10core.dll" "$windows_dir/syswow64/d3d10core.dll"
                copyIfDifferent "$dxvk_dir/x32/d3d11.dll" "$windows_dir/syswow64/d3d11.dll"
                copyIfDifferent "$dxvk_dir/x32/dxgi.dll" "$windows_dir/syswow64/dxgi.dll"
                copyIfDifferent "$dxvk_dir/x64/d3d9.dll" "$windows_dir/system32/d3d9.dll"
                copyIfDifferent "$dxvk_dir/x64/d3d10.dll" "$windows_dir/system32/d3d10.dll"
                copyIfDifferent "$dxvk_dir/x64/d3d10_1.dll" "$windows_dir/system32/d3d10_1.dll"
                copyIfDifferent "$dxvk_dir/x64/d3d10core.dll" "$windows_dir/system32/d3d10core.dll"
                copyIfDifferent "$dxvk_dir/x64/d3d11.dll" "$windows_dir/system32/d3d11.dll"
                copyIfDifferent "$dxvk_dir/x64/dxgi.dll" "$windows_dir/system32/dxgi.dll"
            fi
            if [ ! -f "$WINEPREFIX/.dxvk-installed" ]; then
                overrideDll "d3d9"
                overrideDll "d3d10"
                overrideDll "d3d10_1"
                overrideDll "d3d10core"
                overrideDll "d3d11"
                overrideDll "dxgi"
                wait
                wineserver -k
                wait
                touch "$WINEPREFIX/.dxvk-installed"
            fi
        else
            if [ -f "$WINEPREFIX/.dxvk-installed" ]; then
                rm -f "$windows_dir/system32/d3d9.dll"
                rm -f "$windows_dir/system32/d3d10.dll"
                rm -f "$windows_dir/system32/d3d10core.dll"
                rm -f "$windows_dir/system32/d3d10_1.dll"
                rm -f "$windows_dir/system32/d3d11.dll"
                rm -f "$windows_dir/syswow64/d3d9.dll"
                rm -f "$windows_dir/syswow64/d3d10.dll"
                rm -f "$windows_dir/syswow64/d3d10core.dll"
                rm -f "$windows_dir/syswow64/d3d10_1.dll"
                rm -f "$windows_dir/syswow64/d3d11.dll"
                wineboot -u
                wait
                unoverrideDll "d3d9"
                unoverrideDll "d3d10"
                unoverrideDll "d3d10_1"
                unoverrideDll "d3d10core"
                unoverrideDll "d3d11"
                unoverrideDll "dxgi"
                wait
                wineserver -k
                wait
                rm -f "$WINEPREFIX/.dxvk-installed"
            fi
        fi
    fi
    if [ -e "$vkd3d_dir" ]; then
        if [ $USE_VKD3D -eq 1 ]; then
            if [ "$WINEARCH" == "win32" ]; then    
                copyIfDifferent "$vkd3d_dir/x86/d3d12.dll" "$windows_dir/system32/d3d12.dll"
            else
                copyIfDifferent "$vkd3d_dir/x86/d3d12.dll" "$windows_dir/syswow64/d3d12.dll"
                copyIfDifferent "$vkd3d_dir/x64/d3d12.dll" "$windows_dir/system32/d3d12.dll"
            fi
            if [ ! -f "$WINEPREFIX/.vkd3d-installed" ]; then
                overrideDll "d3d12"
                wait
                wineserver -k
                wait
                touch "$WINEPREFIX/.vkd3d-installed"
            fi
        else
            if [ -f "$WINEPREFIX/.vkd3d-installed" ]; then
                rm -f "$windows_dir/system32/d3d12.dll"
                rm -f "$windows_dir/syswow64/d3d12.dll"
                wineboot -u
                wait
                unoverrideDll "d3d12"
                wait
                wineserver -k
                wait
                rm -f "$WINEPREFIX/.vkd3d-installed"
            fi
        fi
    fi
    if [ -e "$mfplat_dir" ]; then
        if [ $USE_MICROSOFT_MFPLAT -eq 1 ]; then
            if [ "$WINEARCH" == "win32" ]; then
                copyIfDifferent "$mfplat_dir/syswow64/colorcnv.dll" "$windows_dir/system32/colorcnv.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mf.dll" "$windows_dir/system32/mf.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mferror.dll" "$windows_dir/system32/mferror.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfplat.dll" "$windows_dir/system32/mfplat.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfplay.dll" "$windows_dir/system32/mfplay.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfreadwrite.dll" "$windows_dir/system32/mfreadwrite.dll"
                copyIfDifferent "$mfplat_dir/syswow64/msmpeg2adec.dll" "$windows_dir/system32/msmpeg2adec.dll"
                copyIfDifferent "$mfplat_dir/syswow64/msmpeg2vdec.dll" "$windows_dir/system32/msmpeg2vdec.dll"
                copyIfDifferent "$mfplat_dir/syswow64/sqmapi.dll" "$windows_dir/system32/sqmapi.dll"
            else
                copyIfDifferent "$mfplat_dir/syswow64/colorcnv.dll" "$windows_dir/syswow64/colorcnv.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mf.dll" "$windows_dir/syswow64/mf.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mferror.dll" "$windows_dir/syswow64/mferror.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfplat.dll" "$windows_dir/syswow64/mfplat.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfplay.dll" "$windows_dir/syswow64/mfplay.dll"
                copyIfDifferent "$mfplat_dir/syswow64/mfreadwrite.dll" "$windows_dir/syswow64/mfreadwrite.dll"
                copyIfDifferent "$mfplat_dir/syswow64/msmpeg2adec.dll" "$windows_dir/syswow64/msmpeg2adec.dll"
                copyIfDifferent "$mfplat_dir/syswow64/msmpeg2vdec.dll" "$windows_dir/syswow64/msmpeg2vdec.dll"
                copyIfDifferent "$mfplat_dir/syswow64/sqmapi.dll" "$windows_dir/syswow64/sqmapi.dll"
                copyIfDifferent "$mfplat_dir/system32/colorcnv.dll" "$windows_dir/system32/colorcnv.dll"
                copyIfDifferent "$mfplat_dir/system32/mf.dll" "$windows_dir/system32/mf.dll"
                copyIfDifferent "$mfplat_dir/system32/mferror.dll" "$windows_dir/system32/mferror.dll"
                copyIfDifferent "$mfplat_dir/system32/mfplat.dll" "$windows_dir/system32/mfplat.dll"
                copyIfDifferent "$mfplat_dir/system32/mfplay.dll" "$windows_dir/system32/mfplay.dll"
                copyIfDifferent "$mfplat_dir/system32/mfreadwrite.dll" "$windows_dir/system32/mfreadwrite.dll"
                copyIfDifferent "$mfplat_dir/system32/msmpeg2adec.dll" "$windows_dir/system32/msmpeg2adec.dll"
                copyIfDifferent "$mfplat_dir/system32/msmpeg2vdec.dll" "$windows_dir/system32/msmpeg2vdec.dll"
                copyIfDifferent "$mfplat_dir/system32/sqmapi.dll" "$windows_dir/system32/sqmapi.dll"
            fi
            mfplatVer="$(cat "$WINEPREFIX/.msmfplat-installed")"
            if [ "$mfplatVer" != "$LAUNCHER_VERSION" ]; then
                overrideDll "colorcnv"
                overrideDll "mf"
                overrideDll "mferror"
                overrideDll "mfplat"
                overrideDll "mfplay"
                overrideDll "mfreadwrite"
                overrideDll "msmpeg2adec"
                overrideDll "msmpeg2vdec"
                overrideDll "sqmapi"
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
                wait
                wineserver -k
                wait
                echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.msmfplat-installed"
                rm -f "regsvr32_d3d9.log"
            fi
        else
            if [ -f "$WINEPREFIX/.msmfplat-installed" ]; then
                rm -f "$windows_dir/system32/colorcnv.dll"
                rm -f "$windows_dir/system32/mf.dll"
                rm -f "$windows_dir/system32/mferror.dll"
                rm -f "$windows_dir/system32/mfplat.dll"
                rm -f "$windows_dir/system32/mfplay.dll"
                rm -f "$windows_dir/system32/mfreadwrite.dll"
                rm -f "$windows_dir/system32/msmpeg2adec.dll"
                rm -f "$windows_dir/system32/msmpeg2vdec.dll"
                rm -f "$windows_dir/system32/sqmapi.dll"
                rm -f "$windows_dir/syswow64/colorcnv.dll"
                rm -f "$windows_dir/syswow64/mf.dll"
                rm -f "$windows_dir/syswow64/mferror.dll"
                rm -f "$windows_dir/syswow64/mfplat.dll"
                rm -f "$windows_dir/syswow64/mfplay.dll"
                rm -f "$windows_dir/syswow64/mfreadwrite.dll"
                rm -f "$windows_dir/syswow64/msmpeg2adec.dll"
                rm -f "$windows_dir/syswow64/msmpeg2vdec.dll"
                rm -f "$windows_dir/syswow64/sqmapi.dll"
                wineboot -u
                wait
                unoverrideDll "colorcnv"
                unoverrideDll "mf"
                unoverrideDll "mferror"
                unoverrideDll "mfplat"
                unoverrideDll "mfplay"
                unoverrideDll "mfreadwrite"
                unoverrideDll "msmpeg2adec"
                unoverrideDll "msmpeg2vdec"
                unoverrideDll "sqmapi"
                wait
                wineserver -k
                wait
                rm -f "$WINEPREFIX/.msmfplat-installed"
            fi
        fi
    fi
}
applyMsisIfNeeded(){
    msi_dir="system/msi"
    if [ -e "$msi_dir" ]; then
        installMonoMSI(){
            yes | cp "$msi_dir/winemono.msi" "$WINEPREFIX/drive_c/winemono.msi"
            wine msiexec /i "C:\\winemono.msi"
            wait
            wineserver -k
            wait
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.winemono-installed"
        }
        uninstallMonoMSI(){
            wine msiexec /uninstall "C:\\winemono.msi"
            wait
            wineserver -k
            wait
        }
        if [ $USE_WINEMONO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winemono-installed" ]; then
                installMonoMSI
            else
                winemonoVer="$(cat "$WINEPREFIX/.winemono-installed")"
                if [ "$winemonoVer" != "$LAUNCHER_VERSION" ]; then
                    uninstallMonoMSI
                    installMonoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winemono-installed" ]; then
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
            wineserver -k
            wait
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.winegecko-installed"
        }
        uninstallGeckoMSI(){
            wine msiexec /uninstall "C:\\winegecko32.msi"
            wine msiexec /uninstall "C:\\winegecko64.msi"
            wait
            wineserver -k
            wait
        }
        if [ $USE_WINEGECKO -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.winegecko-installed" ]; then
                installGeckoMSI
            else
                $winegeckoVer="$(cat "$WINEPREFIX/.winegecko-installed")"
                if [ "$winegeckoVer" != "$LAUNCHER_VERSION" ]; then
                    uninstallGeckoMSI
                    installGeckoMSI
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.winegecko-installed" ]; then
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
            wineserver -k
            wait
            mv "$WINEPREFIX/.templink" "$WINEPREFIX/dosdevices/z:"
            echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.vcredist-installed"
        }
        uninstallVCRedists(){
            wine "C:\\vc_redist.x86.exe" /uninstall /quiet /norestart
            wine "C:\\vc_redist.x64.exe" /uninstall /quiet /norestart
            wait
            wineserver -k -w
            wait
        }
        if [ $USE_VCREDIST -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.vcredist-installed" ]; then
                installVCRedists
            else
                vcredistVer="$(cat "$WINEPREFIX/.vcredist-installed")"
                if [ "$vcredistVer" != "$LAUNCHER_VERSION" ]; then
                    uninstallVCRedists
                    installVCRedists
                fi
            fi
        else
            if [ -f "$WINEPREFIX/.vcredist-installed" ]; then
                uninstallVCRedists
                rm -f "$WINEPREFIX/.vcredist-installed"
                rm -f "$WINEPREFIX/drive_c/vc_redist.x86.exe"
                rm -f "$WINEPREFIX/drive_c/vc_redist.x64.exe"
            fi
        fi    
        
    fi
}
deIntegrateIfNeeded(){
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
}
hideCrashesIfNeeded(){
    if [ $HIDE_CRASHES -eq 1 ]; then
        export WINEDEBUG=-all
        if [ ! -f "$WINEPREFIX/.crash-hidden" ]; then
            wine reg add 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
            wineserver -k
            wait
            touch "$WINEPREFIX/.crash-hidden"
        fi
    else
        if [ -f "$WINEPREFIX/.crash-hidden" ]; then
            wine reg delete 'HKEY_CURRENT_USER\Software\Wine\WineDbg' /v 'ShowCrashDialog' /f
            wineserver -k
            wait
            rm -f "$WINEPREFIX/.crash-hidden"
        fi
    fi
}
removeBrokenSymlinks(){
    cd "$WINEPREFIX/dosdevices"
    find -L . -name . -o -type d -prune -o -type l -exec rm {} +
    cd ../..
}
removeUnnecessarySymlinks(){
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
    if [ $BLOCK_ZDRIVE -eq 1 ]; then
        unlink "$WINEPREFIX/dosdevices/z:"
    fi
}
repairDriveCIfNeeded(){
    link=$(realpath "$WINEPREFIX/dosdevices/c:")
    target=$(realpath "$WINEPREFIX/drive_c")
    if [ "$link" != "$target" ]; then
        link="$WINEPREFIX/dosdevices/c:"
        rm -rf "$link"
        ln -s "$target" "$link"
        link=$(realpath "$link")
        if [ "$link" != "$target" ]; then
            touch "$WINEPREFIX/.abort"
            zenity --error --width 500 --text "Virtual C drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
repairDriveZIfNeeded(){
    if [ $BLOCK_ZDRIVE -eq 1 ]; then
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
            zenity --error --width 500 --text "Z drive is broken and attempts to repair it failed.\n\nPlease check $link"
            exit
        fi
    fi
}
blockBrowserIfNeeded(){
    if [ $BLOCK_BROWSER -eq 1 ]; then
        export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;winebrowser.exe=d"
    fi
}
killWine(){
    ls -l /proc/*/exe 2>/dev/null | grep -E 'wine(64)?-preloader|wineserver' | perl -pe 's;^.*/proc/(\d+)/exe.*$;$1;g;' | xargs -n 1 kill -9
}
applyCorefontsIfNeeded(){
    windows_dir="$WINEPREFIX/drive_c/windows"
    corefonts_dir="system/corefonts"
    if [ -e "$corefonts_dir" ]; then
        if [ $USE_COREFONTS -eq 1 ]; then
            if [ ! -f "$WINEPREFIX/.corefonts-installed" ]; then
                copyAndRegister(){
                    cp -f "$corefonts_dir/$1" "$windows_dir/Fonts"
                    wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' /v '$2' /t REG_SZ /d '$1' /f
                    wine reg add 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' /v '$2' /t REG_SZ /d '$1' /f
                }
                copyAndRegister "AndaleMo.TTF" "Andale Mono"
                copyAndRegister "Arial.TTF" "Arial"
                copyAndRegister "Arialbd.TTF" "Arial Bold"
                copyAndRegister "Arialbi.TTF" "Arial Bold Italic"
                copyAndRegister "Ariali.TTF" "Arial Italic"
                copyAndRegister "AriBlk.TTF" "Arial Black"
                copyAndRegister "Comic.TTF" "Comic Sans MS"
                copyAndRegister "Comicbd.TTF" "Comic Sans MS Bold"
                copyAndRegister "cour.ttf" "Courier New"
                copyAndRegister "courbd.ttf" "Courier New Bold"
                copyAndRegister "courbi.ttf" "Courier New Bold Italic"
                copyAndRegister "couri.ttf" "Courier New Italic"
                copyAndRegister "Georgia.TTF" "Georgia"
                copyAndRegister "Georgiab.TTF" "Georgia Bold"
                copyAndRegister "Georgiai.TTF" "Georgia Italic"
                copyAndRegister "Georgiaz.TTF" "Georgia Bold Italic"
                copyAndRegister "Impact.TTF" "Impact"
                copyAndRegister "Times.TTF" "Times New Roman"
                copyAndRegister "Timesbd.TTF" "Times New Roman Bold"
                copyAndRegister "Timesbi.TTF" "Times New Roman Bold Italic"
                copyAndRegister "Timesi.TTF" "Times New Roman Italic"
                copyAndRegister "trebuc.ttf" "Trebuchet MS"
                copyAndRegister "Trebucbd.ttf" "Trebuchet MS Bold"
                copyAndRegister "trebucbi.ttf" "Trebuchet MS Bold Italic"
                copyAndRegister "trebucit.ttf" "Trebuchet MS Italic"
                copyAndRegister "Verdana.TTF" "Verdana"
                copyAndRegister "Verdanab.TTF" "Verdana Bold"
                copyAndRegister "Verdanai.TTF" "Verdana Italic"
                copyAndRegister "Verdanaz.TTF" "Verdana Bold Italic"
                copyAndRegister "Webdings.TTF" "Webdings"
                wait
                wineserver -k
                wait
                touch "$WINEPREFIX/.corefonts-installed"
            fi
        else
            if [ -f "$WINEPREFIX/.corefonts-installed" ]; then
                deleteAndUnregister(){
                    windows_dir="$WINEPREFIX/drive_c/windows"
                    corefonts_dir="system/corefonts"
                    rm -f "$windows_dir/Fonts/$1"
                    wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts' /v '$2' /f
                    wine reg del 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Fonts' /v '$2' /f
                }
                deleteAndUnregister "AndaleMo.TTF" "Andale Mono"
                deleteAndUnregister "Arial.TTF" "Arial"
                deleteAndUnregister "Arialbd.TTF" "Arial Bold"
                deleteAndUnregister "Arialbi.TTF" "Arial Bold Italic"
                deleteAndUnregister "Ariali.TTF" "Arial Italic"
                deleteAndUnregister "AriBlk.TTF" "Arial Black"
                deleteAndUnregister "Comic.TTF" "Comic Sans MS"
                deleteAndUnregister "Comicbd.TTF" "Comic Sans MS Bold"
                deleteAndUnregister "cour.ttf" "Courier New"
                deleteAndUnregister "courbd.ttf" "Courier New Bold"
                deleteAndUnregister "courbi.ttf" "Courier New Bold Italic"
                deleteAndUnregister "couri.ttf" "Courier New Italic"
                deleteAndUnregister "Georgia.TTF" "Georgia"
                deleteAndUnregister "Georgiab.TTF" "Georgia Bold"
                deleteAndUnregister "Georgiai.TTF" "Georgia Italic"
                deleteAndUnregister "Georgiaz.TTF" "Georgia Bold Italic"
                deleteAndUnregister "Impact.TTF" "Impact"
                deleteAndUnregister "Times.TTF" "Times New Roman"
                deleteAndUnregister "Timesbd.TTF" "Times New Roman Bold"
                deleteAndUnregister "Timesbi.TTF" "Times New Roman Bold Italic"
                deleteAndUnregister "Timesi.TTF" "Times New Roman Italic"
                deleteAndUnregister "trebuc.ttf" "Trebuchet MS"
                deleteAndUnregister "Trebucbd.ttf" "Trebuchet MS Bold"
                deleteAndUnregister "trebucbi.ttf" "Trebuchet MS Bold Italic"
                deleteAndUnregister "trebucit.ttf" "Trebuchet MS Italic"
                deleteAndUnregister "Verdana.TTF" "Verdana"
                deleteAndUnregister "Verdanab.TTF" "Verdana Bold"
                deleteAndUnregister "Verdanai.TTF" "Verdana Italic"
                deleteAndUnregister "Verdanaz.TTF" "Verdana Bold Italic"
                deleteAndUnregister "Webdings.TTF" "Webdings"
                wait
                wineserver -k
                wait
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
            zenity --info --width 500 --text "This wineprefix is already running\nA command prompt will now be opened inside it"
            justLaunchCommandPrompt
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
        realOverrides="$WINEDLLOVERRIDES"
        export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
        wineboot
        wait
        wineserver -k
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
        applyVCRedistsIfNeeded
        echo "85"
        removeUnnecessarySymlinks
        echo "100"
        echo "$LAUNCHER_VERSION" > "$WINEPREFIX/.initialized"
    ) | zenity --progress --no-cancel --text="Launching..." --width=200 --auto-close --auto-kill
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
        realOverrides="$WINEDLLOVERRIDES"
        export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=d"
        wineboot -i
        wait
        echo "30"
        while ! test -f "$WINEPREFIX/system.reg"; do
            sleep 1
        done
        wineserver -k
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
        applyVCRedistsIfNeeded
        echo "85"
        removeUnnecessarySymlinks
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
