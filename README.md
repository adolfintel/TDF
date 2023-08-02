# TDF - Manual
TDF is a small project aiming to make it easy to install, package and safely run Windows games on GNU/Linux. You can think of it as a portable (as in requiring no installation) version of Proton, based on most of the same technology.

__TDF is based on the following awesome projects:__  
* [Wine](https://winehq.org), for Windows emulation, more specifically it includes two custom builds made with [tkg](https://github.com/Frogging-Family/wine-tkg-git), one best suited for modern games, and one more suited for applications and older games
* [DXVK](https://github.com/doitsujin/dxvk), for DirectX 9-11 emulation, more specifically it includes both the regular version of DXVK built from source, as well as the [gplasync version](https://gitlab.com/Ph42oN/dxvk-gplasync) for cards that don't support the Vulkan GPL extension
* [D8VK](https://github.com/AlpyneDreams/d8vk), for DirectX 8 emulation (soon to be merged into DXVK), built from source
* [VKD3D-Proton](https://github.com/HansKristian-Work/vkd3d-proton), for DirectX 12 emulation, built from source
* [Steam Runtime](https://github.com/ValveSoftware/steam-runtime), to make the Wine dependency hell a bit easier (it still depends on some things of course)
* [xdotool](https://github.com/jordansissel/xdotool), a useful tool to handle games with problematic window/fullscreen behaviors
* ...and a handful of other useful things

__TDF's main goals are are:__  
* Being able to easily install and run games that you can't or don't want to play through Steam: things like GOG installers, ISOs, repacks, etc.
* Sandboxing: by default, network and file system access are blocked to games running inside a TDF instance (note that this will not protect against malware that specifically targets Wine or the Linux kernel)
* Being as lightweight and portable as possible: virtually any modern GNU/Linux distro with a GUI can run TDF instances out of the box
* Being able to easly update TDF instances as well as testing different versions of the main components, making it possible to help their respective developers
* Being able to easily package and transfer a TDF instance to another computer or redistribute it (legally)
* Focus on modern games, but a lot of older titles will work as well with some tinkering

If you're happy with Lutris, you probably don't need TDF.

## Usage
This section explains how to use TDF to install, play and optionally package a game.

### Requirements
* A relatively recent PC that's fast enough to run modern games. An x86_64 CPU is required, as well as a GPU with support for Vulkan 1.3 or newer
* Linux kernel 5.16 or newer is strongly recommended, but it will work on older versions (tested as low as 4.19)
* A modern-ish distro with basic stuff like the GNU coreutils, glibc, systemd, X11, etc. installed, __both 32 and 64 bit versions__. Arch-based distros will work best.
* An AMD graphics card with the latest Mesa 23.1 driver or newer is recommended, but it will also work on nVidia and Intel cards
* An SSD is strongly recommended, with a file system like ext4 or btrfs. Do not use NTFS, FAT or exFAT
* You must be able to use a Linux system, do file and folder management, know how to install games manually, know some basic shell scripting, etc.

### Basic usage
* Download the latest build of TDF (or built it yourself)
* Extract the archive somewhere, optionally renaming the folder from template-YYYYMMDD to something more useful. We'll call this folder a TDF instance, you can have as many instances as you want
    * Inside this folder, you'll see 4 things:
        * `run.sh`: the script that starts all the TDF magic, we'll use this in a moment
        * `vars.conf`: TDF's main configuration file for this instance, you'll use this to tell TDF where to find the game and to change emulation settings
        * `system`: a folder containing all the TDF files and scripts, leave it alone for now
        * `confs`: we'll talk about folder this later
* Launch `run.sh`, it will automatically initialize everything for you and open a Windows command prompt
    * Once everything is ready, the TDF instance folder will contain a new folder called zzprefix, this is your "fake Windows", inside it you'll find, among other things, a folder called drive_C, this is the fake C drive, you can enter it to copy game files, mods, etc. at any time
    * Depending on the system and the configuration, other folders may also be created, like zzhome and fontcache
    * If you're not familiar with the Windows command prompt, just type explorer and press enter to have a more familiar file manager interface, but don't close the command prompt until you're finished
* Use the command prompt to install the game like you would on Windows but without launching it
    * During the installation, you won't need to install things like DirectX, the Visual C++ Redistributables, etc. because TDF has already done it during the initialization
    * If you need to copy or modify some files inside the fake C drive, do it through the Linux file manager, it's easier
    * Once you're done, close the command prompt
* Edit `vars.conf` and place the location of the game's exe file in the game_exe variable
* Launch run.sh again and hopefully the game will start
    * From now on, you can just launch `run.sh` (or create links to it) to launch this game.
    * About 85% of games will work out of the box, some will require some tinkering, usually in the form of changing some variables in `vars.conf`, which we'll discuss later
    * Online games that require anticheat software will usually not work (and that's probably for the best)

TODO: VIDEO

### Configuration variables
The following lists contain all the variables that can be added in `vars.conf` to configure emulation settings, work around issues, improve performance, etc.

### Essential variables
__`game_exe`__  
Specifies the Windows-style path to the game's exe file. If no value is set, the command prompt will be launched instead.

Example: `game_exe='C:\GTAV\PlayGTAV.exe'`

__`game_args`__  
Arguments to be passed to the game.

Example: `game_args='-iwad doom2.wad -file mymod.wad'`

__`game_workingDir`__  
The working directory of the game. By default this is set to the same folder where the `game_exe` resides. If you need to change this, `game_exe` will have to be set to a path relative to this folder. All paths must be Windows-style.

Example:  
```
game_exe='bin\indy.exe'`
game_workingDir='C:\Indy'
```

### TDF variables
__`TDF_TITLE`__  
The title to show on the title bar of the TDF windows. By default it's set to `"Launcher"`.

__`TDF_DETAILED_PROGRESS`__  
Whether to show the details of what's happening above the progress bar in the TDF window.

Possible values:  
* `1` (default): show details like "Starting wine", "Registering DLLs", etc.
* `0`: show a generic message like "Launching..." or "Creating a new wineprefix, this will take a while..."

__`TDF_ZENITY_PREFER_SYSTEM`__  
Zenity is the tool that displays the TDF windows with the progress bar and the various messages. TDF comes with its own version of Zenity but it can use the one in the system (if installed), which looks better.

Possible values:  
* `1` (default): use Zenity provided by the system, keep the builtin one as a fallback
* `0`: always use the builtin Zenity

__`TDF_MULTIPLE_INSTANCES`__  
What to do if the user tries to launch `run.sh` while it's already running.

Possible values:  
* `deny`: do nothing, just exit without an error message
* `error`: show an error message and exit
* `askcmd` (default): don't launch the game but ask the user if they want to launch a command prompt in the running instance
* `cmd`: same as `askcmd` but without asking first
* `allow`: allow multiple instances of the game to be running at the same time (generally a bad idea)

__`TDF_IGNORE_EXIST_CHECKS`__  
By default, TDF checks whether the executable specified in `game_exe` actually exists before trying to launch it, but this is not always desirable and can be disabled, which can be useful to run certain commands.

Possible values:  
* `1` (default): check that the executable actually exists and show an error if it doesn't
* `0`: don't check and don't show an error if it doesn't exist

__`TDF_HIDE_GAME_RUNNING_DIALOG`__  
Whether to hide the TDF window that says "Game running". By default, TDF shows it so you can know if the process has stalled.

Possible values:  
* `0` (default): show the window
* `1`: hide it

__`TDF_SHOW_PLAY_TIME`__  
Whether to show a message when you close the game that tells you how long you've been playing.

Possible values:  
* `0` (default): don't show it
* `1`: show it

### Wine variables
__`TDF_WINE_PREFERRED_VERSION`__  
TDF comes with 2 different versions of Wine and can also use the one on your system (if installed). This variable lets you choose which one you prefer.

Possible values:  
* `games` (default): use the game-optimized build. This version is based on Valve's version of Wine, with the GE and tkg patches and is very similar to [Wine-GE-Proton](https://github.com/GloriousEggroll/wine-ge-custom). Some functionalities have been disabled: anticheat bridges (you can't convince me they're not malware), dbus (automounting of external drives), ISDN, printing, digital camera importing, LDAP and related things, pcap support (network traffic sniffing), smart cart readers support, scanners, low level access to USB devices (does not affect input, that goes over HID), webcam support, Win16 support, winemenubuilder, vkd3d-lib (Wine's own VKD3D implementation, not needed since TDF uses VKD3D-Proton)
* `mainline`: use a mostly regular version of Wine, useful for applications and old games that don't work with the game-optimized build. This version only contains a couple of hotfixes from tkg and the only disabled features are dbus and winemenubuilder for better isolation
* `system`: use the version of Wine that's installed in the system, if it's not installed `mainline` will be used instead

__`TDF_WINE_HIDE_CRASHES`__  
When a Wine application crashes, it normally shows a window similar to the "Stopped working" dialog on Windows, but depending on the game and configuration, it may be impossible to interact with that window, leaving you stuck. By default, TDF disables this crash window, but it can be enabled for debugging and troubleshooting purposes.

Possible values:  
* `1` (default): hide the crash window
* `0`: show the crash window

__`TDF_WINE_DPI`__  
DPI value for display scaling of Wine applications.

Possible values:  
* `-1` (default): use DPI from the main display (X11 only, Wayland will use default value)
* `0`: let Wine handle scaling
* number: use this DPI value (96=100% scaling, 120=125% scaling, 144=150% scaling, etc.). 96 DPI will fix some older games

__`TDF_WINE_KILL_BEFORE`__  
Whether to kill wine before launching the game. Not recommended.

Possible values:  
* `0` (default): don't kill wine before launching the game
* `1`: kill all wine instances before launching the game

__`TDF_WINE_KILL_AFTER`__  
Whether to kill wine after the game ends. Not recommended.

Possible values:  
* `0` (default): don't kill wine after the game ends
* `1`: kill all wine instances after the game ends

__`TDF_START_ARGS`__  
Optional arguments to pass to Wine's start command. [More info](https://ss64.com/nt/start.html). Mostly useful to set CPU affinity for old games.

Example: `TDF_START_ARGS='/AFFINITY 1'`

__`TDF_WINE_LANGUAGE`__  
By default, TDF will pass the system language to Wine, which may be undesirable for some games and applications that just use the system language instead of showing a language selector. Here's a complete [list of locales](https://docs.oracle.com/cd/E23824_01/html/E26033/glset.html), obviously not all games will support them.

Example: `TDF_WINE_LANGUAGE='it_IT.utf-8'`

__`TDF_WINE_ARCH`__  
The architecture of the Wine installation. Can only be set once, before the initialization is performed, and can't be changed afterwards without deleting the wineprefix.

Possible values:  
* `win64` (default): create a 64bit Windows installation
* `win32`: create a 32bit Windows installation (useful for some old games)

__`TDF_WINE_SYNC`__  
The synchronization method to be used by Wine (game-optimized build only).

Possible values:  
* `fsync` (default): use fsync if supported by the kernel (5.16+), otherwise use esync. This provides the best performance and compatibility
* `esync`: use the older esync method
* `default`: let Wine decide

__`TDF_WINE_DEBUG_RELAY`__  
Enables the Wine relay feature, which traces all interaction between the application and the rest of the system to a file. Extremely slow but can be useful to debug weird issues and crashes.

Possible values:  
* `0` (default): disabled
* `1`: when the game is launched, TDF will ask where you want to save the trace, then launch the game with relay enabled

__`TDF_WINEMONO`__  
Whether to install Wine Mono in the prefix or not. Mostly useful for launchers and applications based on .NET, games don't usually need this.

Possible values:  
* `0` (default): don't install Wine Mono
* `1`: install Wine Mono

__`TDF_WINEGECKO`__  
Whether to install Wine Gecko in the prefix or not. This provides the equivalent of a Webview, mostly useful for launchers and applications based on IE, games don't usually need this.

Possible values:  
* `0` (default): don't install Wine Gecko
* `1`: install Wine Gecko

__`export WINEDLLOVERRIDES`__  
Some game fixes and mods come in the form of DLLs that override one of Windows' DLL, usually `winmm`, `dinput8`, `version`, `d3d9`, etc.  
Unlike Windows, which happily loads random DLLs from the game's folder, Wine prefers to use its own DLLs and overrides need to be specified manually.

This is not a TDF variable, but it's part of Wine. More about this [here](https://wiki.winehq.org/Wine_User's_Guide#DLL_Overrides).

Example:  
```
#load winmm.dll and dinput8 from the game's folder (if available)
export WINEDLLOVERRIDES="winmm,dinput8=n,b"
```

This can also be used to fix games that complain about outdated drivers on AMD cards or that don't detect the correct amount of VRAM, since they often obtain this information through a DLL called `amd_ags_x64.dll`:

Example:  
```
#use wine's own fake amd_ags_x64 instead of the game's version
export WINEDLLOVERRIDES="amd_ags_x64=b"
```

Multiple overrides can be separated by a semicolon `;`.

__`export WINE_CPU_TOPOLOGY`__  
This is not a TDF variable, but it allows you to set Wine to use specific CPU cores, similar to the `/AFFINITY` option of the `start` command, but more fine grained.

Example:
```
#limits wine to one CPU core
export WINE_CPU_TOPOLOGY=1:0"
```

Example:
```
#limits wine to use the first 4 CPU cores
export WINE_CPU_TOPOLOGY=4:0,1,2,3"
```

__`export WINEDEBUG`__  
Enables/disables some [Wine debug channels](https://wiki.winehq.org/Debug_Channels).

By default, TDF sets this to `-all` improve performance, but you might want to enable one or more of these for troubleshooting, or restore the default Wine settings using `unset WINEDEBUG`.

Don't add `+relay` to this variable, as it's controlled by the `TDF_WINE_DEBUG_RELAY` variable.

Example:
```
#log loaded DLLs to the terminal and show the pid of the process that generated each message
export WINEDEBUG=+loaddll,+pid
```

#### DXVK, D8VK and VKD3D variables
__`TDF_DXVK`__  
Whether to install DXVK or not, which provides DirextX 9-11 emulation through Vulkan. If this is disabled, WineD3D will be used instead, which is better for some older games.

Settings for DXVK can be changed by editing the `dxvk.conf` file that will be created inside `zzprefix`.

Possible values:  
* `1` (default): use DXVK
* `0`: use WineD3D

__`TDF_DXVK_ASYNC`__  
If enabled, TDF will use the gplasync version of DXVK instead of the regular version. This is only useful for systems that don't support the Vulkan `VK_EXT_graphics_pipeline_library` (GPL) extension because either the GPU or the driver is too old.

Possible values:  
* `2` (default): let TDF decide automatically, uses regular DXVK if GPL is supported, gplasync otherwise
* `0`: always use the regular version of DXVK. If the system doesn't support GPL, the game will suffer from heavy shader compilation stuttering
* `1`: always use the gplasync version of DXVK. Not recommended, can introduce minor graphical issues or stability issues

__`TDF_D8VK`__  
Whether to install D8VK or not, which provides DirextX 8-11 emulation through Vulkan. Enabling this will automatically disable DXVK, DXVK_ASYNC and VKD3D. If this is disabled, WineD3D will be used instead. Games that use DirectX 1-7 will always use WineD3D.

Settings for D8VK can be changed by editing the `d8vk.conf` file that will be created inside `zzprefix`.

Possible values:  
* `0` (default): use WineD3D
* `1`: use D8VK

Note: D8VK will be merged into DXVK soon, when this happens this option will be removed.

__`TDF_VKD3D`__  
Whether to install VKD3D-Proton, which provides DirectX 12 emulation through Vulkan. If this is disabled, Wine's version of VKD3D is used instead, which has very poor game compatibility compared to this version.

Possible values:  
* `1` (default): use VKD3D-Proton
* `0`: use Wine's VKD3D implementation

VKD3D's config can be changed by using its [environment variables](https://github.com/HansKristian-Work/vkd3d-proton#environment-variables). By default, TDF only sets `export VKD3D_CONFIG=dxr11`, which enables ray tracing on supported cards.

#### Sandboxing variables
__`TDF_BLOCK_NETWORK`__  
Whether to block network access to Wine. By default, TDF blocks network access entirely to prevent undesirable data collection, but it can be unblocked if you trust the game you're running or it needs to go online.

Possible values:  
* `1` (default): block network access using `unshare -nc` (creates a namespace without the network stack)
* `0`: allow network access
* `2`: block network access using Firejail if it's installed in the system, otherwise `unshare -nc` will be used. This can fix some games that take a long time to load when there is no network stack, such as Death Stranding

__`TDF_BLOCK_BROWSER`__  
Whether to block Wine from opening the system's native web browser or not. By default, TDF will block these requests to prevent undesirable data collection, but it can be unblocked if you trust the game you're running or it needs to open some web pages.

Possible values:  
* `1` (default): block access to the system's native web browser
* `0`: allow Wine to launch the native web browser

Note that allowing access to the native web browser can be abused to bypass `TDF_BLOCK_NETWORK`, this behavior has been noticed in several game repack installers.

__`TDF_BLOCK_ZDRIVE`__  
Wine normally exposes a Z drive to applications, with full access to the Linux file system, which can be abused by games to collect data or by malware to modify files outside the TDF instance, but it can also be useful when installing games, since you can access mounted drives, your Downloads folder, etc. or if you're running applications.

Possible values:  
* `1` (default): allow access to the Z drive when in "install mode" (i.e. `game_exe` is not set yet), making it easier to install the game, block afterwards
* `2`: always block access to the Z drive
* `0`: allow access to the Z drive

Note that while this can help protect against Windows malware, malware designed to attack Wine or Linux can very easily bypass this restriction. Never run untrusted software inside TDF, use a VM instead.

__`TDF_BLOCK_EXTERNAL_DRIVES`__  
Wine normally exposes external drives to applications, giving a letter to each drive. This can be undesirable for the same reasons as exposing the Z drive and TDF blocks this by default.

Possible values:  
* `1` (default): remove all mappings to external drives when TDF is started but don't disable the `winedevice` service. If you're not using TDF's own Wine builds, drives connected while Wine is running will be mapped automatically
* `2`: remove all mappings to external drives when TDF is started and also disable the `winedevice` service so that drives can never be mapped automatically even on other Wine builds (can break some games and especially installers but improves security)
* `0`: allow access to external drives

__`TDF_PROTECT_DOSDEVICES`__  
Prevents Wine from automatically handling all drive mappings for better security. Can cause the `winedevice` service to hang when external drives are connected.

Possible values:  
* `0` (default): let Wine handle drive mappings
* `1`: TDF handles drive mappings and denies Wine write access to the `zzprefix/dosdevices` directory

Note: this option is effectively useless when using TDF's own Wine builds, since dbus is disabled and no mappings will be automatically created.

__`TDF_BLOCK_SYMLINKS_IN_CDRIVE`__  
When this option is enabled, TDF will scan the C drive on startup and remove all symlinks. This can be useful in case Wine creats some symlinks outside the TDF instance during an update, or if you created a symlink during the installation and forgot to remove it, which can be dangerous.

Possible values:  
* `1` (default): scan and remove all symlinks in the C drive on startup
* `0`: allow symlinks in the C drive

Note that Wine's symlinks to your home directory, My Documents, Desktop, etc. as well as the creation of shortcuts (.desktop files) on your desktop and start menu will always be blocked regardless of settings; TDF is not designed to let applications "integrate" with the system, quite the opposite.

__`TDF_FAKE_HOMEDIR`__  
When this option is enabled, Wine will not see your home directory, but a `zzhome` folder will be created in the TDF instance. This can be used to improve security, but it's mostly useful for games that require special settings in `~/.driconf`, such as KOTOR.

Possible values:  
* `0` (default): use the real home directory
* `1`: use a fake home directory inside the TDF instance

Note that the `zzhome` folder and all data inside it will be automatically deleted when this option is disabled.

#### Gamescope variables
__`TDF_GAMESCOPE`__  
Whether to enable Gamescope when running the game or not. This is generally not recommended when using the `games` version of Wine, since it integrates the fshack patches which makes it mostly useless, but it can be useful when using the `mainline` version for games that change the screen resolution often, require low resolutions, integers scaling, etc. such as KOTOR or WinQuake. If Gamescope is not installed in the system, it has no effect.

Possible values:  
* `0` (default): don't use Gamescope
* `1`: use Gamescope when running games if available

Note that Gamescope currently only works properly on AMD GPUs and getting it to work properly on Intel and nVidia cards requires additional configuration.

__`TDF_GAMESCOPE_PARAMETERS`__  
The command line arguments used to start Gamescope. You can see a complete list [here](https://github.com/ValveSoftware/gamescope#options).

By default, TDF sets this variable to `-f -r 60 -w $XRES -h $YRES`, where `XRES` and `YRES` are two read only variables provided by TDF for conveninece that contain the horizontal and vertical resolution of the main display. This default value emulates a virutal screen with the same resolution as the real display, with a refresh rate of 60hz and sets Gamescope to run in fullscreen without any special scaling.

#### Miscellaneous variables
__`TDF_STEAM_RUNTIME`__  
Whether to launch TDF using the Steam Runtime or not. This is generally a good idea as it makes TDF extermely portable, but if it fails to launch you might want to disable it. If you disable this feature, you must have Wine and all its dependencies installed on your system, as well as Zenity.

Possible values:  
* `1` (default): use Steam Runtime
* `0`: don't use Steam Runtime

__`TDF_GAMEMODE`__  
Whether to launch the game using Feral Gamemode or not, which can improve performance especially on weaker or mobile systems. If Gamemode is not installed in the system, it has no effect.

Possible values:  
* `1` (default): use Gamemode if available
* `0`: don't use Gamemode

__`TDF_MANGOHUD`__  
Whether to launch the game with the MangoHud performance overlay or not. If MangoHud is not installed in the system, it has no effect. Note that some games will crash when launched with MangoHud.

Possible values:  
* `0` (default): don't use MangoHud
* `1`: use Mangohud

__`TDF_COREFONTS`__  
Whether to install the Microsoft Corefonts or not. These are fonts like Arial, Comic Sans, etc. that are required by some games such as PC Building Simulator. This is generally harmless, but if some application has font rendering issues, try disabling it.

Possible values:  
* `1` (default): install the Corefonts
* `0`: don't install the Corefonts

__`TDF_VCREDIST`__  
Whether to install the Microsoft Visual C++ Redistributable (2015+) or not. This is useful for modern games but unnecessary for older ones.

Possible values:  
* `1` (default): install VCRedist 2015+
* `0`: don't install VCRedist 2015+

__`TDF_MSMFPLAT`__  
Whether to install the Microsoft Media Foundation Platform (mfplat) instead of Wine's implementation. This can fix video playback in some games but is generally a bad idea. Also, once installed, it can't be cleanly removed without recreating `zzprefix` from scratch so keep this as an absolute last resort.

Possible values:  
* `0` (default): use Wine's mfplat implementation
* `1`: use Microsoft's implementation

Note that the licensing status of this feature is unclear and it will probably be removed in future versions of TDF since it's rarely necessary. These files are readily available on [GitHub](https://github.com/z0z0z/mf-install) and have been used for years before Wine implemented mfplat decently, but they are proprietary blobs so if you're concerned about licenses and software patents, remove the `system/mfplat` folder from your TDF instance.

__`export DRI_PRIME`__  
Sometimes on systems with multiple GPUs, a game might start using the wrong GPU, such as the integrated graphics on your laptop instead of the dedicated card.

By setting a value for `DRI_PRIME` you can tell the game which graphics card to use.

Example:  
```
#use the second GPU
export DRI_PRIME=1
```

This is not a TDF variable and you can find more about it [here](https://wiki.archlinux.org/title/PRIME).

### Callbacks
You can optionally define the following functions inside `vars.conf` and they will be called at specific moments during operation. This can be useful to fix games that have issues with window positioning, focusing, etc. or that have some special requirements. The language is just bash.

If you need to define some variables, do it inside the callback functions, as the configuration is loaded more than once during the initialization process.

__`customChecks`__  
This function will be called immediately after the configuration is loaded. It's useful to run some custom checks specific to the game or to change some settings depending on hardware/software configuration. The function returns 0 if the checks succeed, 1 to indicate that they failed and stop TDF. If the function has no return, it will be treated as a success.

Example:  
```
customChecks(){
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
        return 0
    else
        zenity --error --text="Sorry, this game requires X11"
        return 1
    fi
}
```

Note that this function is blocking and TDF won't continue the initialization until it has finished running.

__`onGameStart`__  
This function will be called right before the game is launched.

Example:  
```
onGameStart(){
    setGamma 1.2
}
```

Note that this function is blocking and the game won't be launched until it has finished running.

__`onGameEnd`__  
This function will be called when the game's main process finishes running.

Example:  
```
onGameEnd(){
    restoreGamma
}
```

Notes:
* This function is blocking and TDF won't continue until it has finished running
* The wineserver is still running when this funcion is called
* Some games (especially ones with launchers) will spawn a subprocess and the main process will close, causing this callback to be triggered while the game is still running. In this case, you can check the running processes with `isProcessRunning` (mentioned later) to know whether the game has actually finished running or not

__`whileGameRunning`__  
This function will be called right before the game is running, and will continue running in parallel to the game in a subshell.

Example:  
```
whileGameRunning(){
    #workaround for the little black bar at the top of the screen
    waitForWindow "APlagueTaleRequiem_x64.exe"
    sleep 3
    focusWindow $WINDOW
    pressKey alt+enter 2
}
```

Nots:
* This function does not automatically stop running when the game's process ends, so if you're running a loop, make sure to check the game's process using `isProcessRunning`
* The game process may not have been created yet when this function is called, since Wine takes a bit to launch

__`onArchiveStart`__  
This function will be called right before the packaging process begins when using `./run.sh archive` (mentioned later). It can be used to remove or move some unnecessary files like DXVK/VKD3D caches, saved games, etc.. The function receives the same arguments passed to `run.sh` and can return 1 to prevent the packaging process from starting if something's wrong.

Example:  
```
onArchiveStart(){
    TEMPDIR="/tmp/requiem$RANDOM"
    mkdir "$TEMPDIR"
    mv zzprefix/drive_c/APTRequiem/vkd3d-proton.cache "$TEMPDIR"
    mv zzprefix/drive_c/users/wine/AppData/Local/GOG.com "$TEMPDIR"
}
```

Note that this function is blocking and the packaging process won't start until it has finished running.

__`onArchiveEnd`__  
This function will be called at the end of the packaging process when using `./run.sh archive` (mentioned later). It can be used to restore files modified or deleted by `onArchiveStart`. This function receives 0 in input if the packaging process has succeeded, 1 otherwise.  
Example:  
```
onArchiveEnd(){
    mv "$TEMPDIR/vkd3d-proton.cache" zzprefix/drive_c/APTRequiem/
    mv "$TEMPDIR/tmp/requiem/GOG.com" zzprefix/drive_c/users/wine/AppData/Local/
    rm -rf "$TEMPDIR"
}
```

Note that this function is blocking and TDF won't quit until it has finished running.

#### Builtin functions
For convenience, TDF comes with some functions that can be used inside the callback functions mentioned before, in addition to everything provided by bash such as sleep, grep, etc..

__`waitForWindow exe title [timeout]`__  
Scans windows to find one that matches the specified `exe` and contains `title` in the name. If no matching window is found, it will keep trying for `timeout` seconds (30 if not specified). If `exe` is an empty string, it will match any process with the specified title, if `title` is an empty string, it will match any window from the specified process.

The window IDs will be copied to a `WINDOWS` array, with the first matching window easily accessible with a `WINDOW` variable.

The function returns 0 if a match was found, 1 if the timeout was reached.

Examples:  
* `waitForWindow "APlagueTaleRequiem_x64.exe" "A Plague Tale: Requiem" 10`: waits up to 10 seconds for the process "APlagueTaleRequiem_x64.exe" to spawn a window that contains "A Plague Tale: Requiem" in the title
* `waitForWindow "APlagueTaleRequiem_x64.exe"`: waits up to 30 seconds for the process "APlagueTaleRequiem_x64.exe" to spawn a window
* `waitForWindow "" "A Plague Tale: Requiem"`: waits up to 30 seconds for any process to spawn a window that contains "A Plague Tale: Requiem" in the title
* `waitForWindow "APlagueTaleRequiem_x64.exe" "" 10`: waits up to 10 seconds for the process "APlagueTaleRequiem_x64.exe" to spawn a window

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`focusWindow id`__  
Makes the specified window active and focused, useful to fix games where the taskbar is visible and you have to alt-tab to get rid of it.

The `id` of the window can be obtained with the `waitForWindow` function.

Returns 0 if the operation succeeded, 1 if there's no window with the specified id.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`maximizeWindow id`__  
Makes the specified window maximized.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`restoreWindow id`__  
Makes the specified window not maximized.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`minimizeWindow id`__  
Makes the specified window minimized.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`activateWindow id`__  
Makes a minimized window active again.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`moveWindow id x y`__  
Moves the specified window to the requested position.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`resizeWindow id width height`__  
Resizes the specified window to the requested `width` and `height`.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`makeFullscreen id`__  
Adds the fullscreen attribute to the specified window, essentially making it borderless and maximized. Don't use this unless the game has no other way to go to fullscreen.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`removeFullscreen id`__  
Removes the fullscreen attribute to the specified window. Games react differently to this, don't use this if the game has a better way to go to windowed mode.

The `id` of the window can be obtained with the `waitForWindow` function.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`keepWindowFocused exe title [timeout]`__  
Keeps a game focused automatically, useful for games that have issues when alt-tabbing or when the taskbar is still visible when the game is in fullscreen.

The arguments are the same as the `waitForWindow` function, since it works in much the same way.

This function is blocking until the window no longer exists.

Example:  
```
whileGameRunning(){
    keepWindowFocused "MassEffect.exe"
}
```

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`keepWindowFocusedById id`__  
Keeps a game focused automatically, useful for games that have issues when alt-tabbing or when the taskbar is still visible when the game is in fullscreen.

This is essentially the same as the `keepWindowFocused` except it takes a window id as input, which you can obtain with the `waitForWindow` function.

This function is blocking until the window no longer exists. Returns 1 if the specified window was not found in the first place, 0 if the window was found.

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`pressKey keys [repeats]`__  
Simulates the pressing of the specified key or key combination, which is sent to the currently active and focused window. Useful for games where you have to press alt+enter to enter fullscreen or where you need to press some keys to get rid of a problem.

If a number is added for the `repeats` parameter, the specified key or key combination will be repeated `repeats` times, with a delay of 0.5s between each press.

Example:  
```
#workaround for the lag spike when you first press a key in GTA V
whileGameRunning(){
    waitForWindow "GTA5.exe" "Grand Theft Auto V"
    sleep 3
    focusWindow $WINDOW
    sleep 1
    pressKey w
}
```

Note: this function uses `xdotool` internally and may not work properly on Wayland, depending on how good the X11 emulation in your display manager is (works on major ones).

__`setGamma gamma`__  
Sets the gamma for the main screen. `gamma` can either be a single decimal number (1.0 is the default gamma), or it can be expressed as 3 separate values `r:g:b`. Useful for games that look too dark on modern displays or when using gamescope since it doesn't support hardware gamma yet.

Returns 0 if the operation succeeded, 1 if an error occurred.

The gamma level is not restored automatically when the game ends, so `restoreGamma` must be called later.

Note: this function only works on X11.

__`saveGamma`__  
Stores the current gamma level so it can be restored later with `restoreGamma`.

Returns 0 if the operation succeeded, 1 if an error occurred.

Note: this function only works on X11.

__`restoreGamma`__  
Restored the gamma level previously saved with `saveGamma`. If a gamma level was never saved, it restores the gamma level from when TDF was started.

Returns 0 if the operation succeeded, 1 if an error occurred.

Example:  
```
onGameStart(){
    saveGamma
    setGamma 1.2
}
onGameEnd(){
    restoreGamma
}
```

Note: this function only works on X11.

__`defaultGamma`__  
Sets the default 1.0 gamma.

Returns 0 if the operation succeeded, 1 if an error occurred.

Note: this function only works on X11.

__`isProcessRunning exe`__  
Determines whether there's a process with a name that contains the value in `exe` (case sensitive). Not limited to Wine executables.

Returns 1 if a process was found, 0 otherwise.

Example:  
```
if isProcessRunning "explorer.exe"; then
    wineserver -k -w
fi
```

### Game collections (multiple games in one TDF instance)
Ideally, you want to have one TDF instance for each game, which keeps them nicely isolated, but some game series like Mass Effect need to import the previous game's data or the game itself has expansions/mods that need to be started with different commands, and therefore need to be installed in the same TDF instance. This is where that `confs` folder comes in.

Inside the `conf` folder, you can make as many `.conf` files as you need, one for each game/mod installed in the TDF instance. These files follow the same syntax as the `vars.conf` file and each one contains the configuration necessary to launch one game.

TDF will automatically detect the presence of files in the `conf` folder and show a menu with the list of games in alphabetical order.

When using this mode, the `vars.conf` file will always be loaded first and its settings will apply to all games, then once the user has chosen one of the games, the specific `.conf` file will be loaded. If a variable or a callback function is defined both in `vars.conf` and in one of the `.conf` file, the latter wins because it's more specific.

Example for Mass Effect Legendary Edition:  
* `vars.conf`:
    ```
        #all 3 games use the same arguments so we can put them here
        game_args='-NoHomeDir -SeekFreeLoadingPCConsole -Subtitles 20 -OVERRIDELANGUAGE=INT'
    ```
* `confs/Mass Effect 1.conf`:
    ```
        game_exe='C:\MELE\Game\ME1\Binaries\Win64\MassEffect1.exe'
        
        whileGameRunning(){
            keepWindowFocused "MassEffect1.exe"
        }
    ```
* `confs/Mass Effect 2.conf`
    ```
        game_exe='C:\MELE\Game\ME2\Binaries\Win64\MassEffect2.exe'
        
        whileGameRunning(){
            keepWindowFocused "MassEffect2.exe"
        }
    ```
* `confs/Mass Effect 3.conf`
    ```
        game_exe='C:\MELE\Game\ME3\Binaries\Win64\MassEffect3.exe'
        
        whileGameRunning(){
            keepWindowFocused "MassEffect3.exe"
        }
    ```

Note: the `TDF_STEAM_RUNTIME` variable can only be set in `vars.conf`, since it's applied before TDF is started.

### Packaging and redistributing a TDF instance
You installed your game(s) in a TDF instance and made sure it works perfectly? Did you test it on different hardware? Different distros? All good? Great! You're ready to package it.

To start the packaging process, open a terminal inside the TDF instance and type `./run.sh archive`. This will create an archive containing the whole TDF instance that you can easily redistribute (assuming you have the rights to do it). Users will be able to simply extract these archives and launch `run.sh` to start the game.

By default, TDF creates a highly compressed `.tar.zst` archive, which takes a long time to create but can be extracted very quickly. You can choose between different formats by adding one of the following arguments after `./run.sh archive`:
* `nocompress`: creates a simple uncompressed `.tar` archive. Very fast but not ideal for redistribution
* `fastcompress`: creates a compressed `.tar.xz` archive, compressed with multithread XZ. Compression is relatively fast, decompression is also quite fast, but the compression ratio is not the best
* `maxcompress`: creates a compressed `.tar.zst` archive, compressed with single thread ZStandard with the highest settings. This is pretty slow but decompression is very fast and also has good compression ratio. This is what Fitgirl would call a "monkey repack"

During the compression process, TDF will show you a progress indicator. At the end of the process, it will tell you the compressed size and the compression ratio.

Note: this feature assumes that `tar`, `xz` and `zstd` are installed on your system (they probably are).

If you want to transfer a TDF instance from one PC to another using an external drive, it is strongly recommended to use to use the archive function so it's just one big file. __Never copy a TDF instance to an NTFS, exFAT or a FAT32 partition, it will become unusable.__

### Updating a TDF instance
TDF is designed to be easy to update. To update a TDF instance from an older version:
* Download (or build) a new version of TDF
* Delete the `system` folder and `run.sh`
* Copy `system` and `run.sh` from the newer version to the TDF instance, where the old ones used to be
* Launch run.sh and it will update everything automatically

It is also possible to downgrade to an older version of TDF in the same way, in case the newer version introduces some problems.

### Troubleshooting
TODO, sorry

## Building TDF
The TDF build scripts are designed to download the latest version of each component in TDF, build what needs to be compiled from source and create a `template-YYYYMMDD.tar.zst` ready to extract and use.

To build TDF:  
* Download the latest version of this repo: `git clone https://github.com/adolfintel/tdf`
* Enter the downloaded folder: `cd tdf`
* Launch the automatic build script: `./makeTemplate`

The following dependencies must be installed on your system:  
* Basic tools like coreutils, gcc, g++, wget, curl, git, make, meson, sed, tar, zstd, etc. (on Arch-based distros, the `base-devel` package should provide everything you need)
* Wine and its dependencies (just install Wine from your distro's repos)
* Mingw-w64
* glslc (glslang)

The following components will be downloaded:  
* Wine Mono: latest version from [Github](https://github.com/madewokherd/wine-mono/releases/)
* Wine Gecko: latest 32 and 64 bit versions from the [Wine website](https://dl.winehq.org/wine/wine-gecko/)
* Steam Runtime: latest "scout" version from [Valve](https://repo.steampowered.com/steamrt-images-scout/snapshots/)
* Microsoft Corefonts: from [Sourceforge](https://sourceforge.net/projects/corefonts/)
* Microsoft Visual C++ Redistributable: latest 32 and 64 bit versions from Microsoft
* Microsoft mfplat: [mf-install](https://github.com/z0z0z/mf-install) from Github (will probably be removed in future versions of TDF)

The following components will be built from source:  
* Wine: latest master using the [wine-tkg build system](https://github.com/Frogging-Family/wine-tkg-git) with some custom config
* DXVK: latest master from [Github](https://github.com/doitsujin/dxvk)
* DXVK-gplasync: latest patch from [Gitlab](https://gitlab.com/Ph42oN/dxvk-gplasync) applied to the latest master of DXVK
* D8VK: latest master from [Github](https://github.com/AlpyneDreams/d8vk)
* VKD3D-Proton: latest master from [Github](https://github.com/HansKristian-Work/vkd3d-proton)
* xdotool: latest master from [Github](https://github.com/jordansissel/xdotool)
* Some C programs included with the TDF source code used

It will take 30-60 minutes to compile everything, after which the package will be compressed and the finished archive will be ~380MB.

Note that while TDF downloads the latest version of almost everything, the repo does not update itself so if you're going to be building TDF regularly, you should always run `git pull origin master` before starting the build to make sure you have the latest version of the TDF repo.

## Important security notice
While TDF provides some additional security compared to a standard installation of Wine or Proton, it is important to understand that Wine is simply not designed for security, quite the opposite, it's designed to seamlessly integrate Windows stuff into Linux.

Wine is an HLE (High Level Emulator) which means that, to put it simply, it doesn't emulate an entire system like dosbox does because it would be too slow, instead it provides a way to load Windows exe files, intercept Windows system calls and "convert" them to equivalent Linux system calls. It also provides a ton of libraries and other functionality but that's not relevant here.

What this means is that a process running inside Wine is, to all intents and purposes, a regular UNIX process that's running under your user, and therefore has access to everything you have access to, and malicious software can easily escape the restrictions put in place by Wine or TDF by using Linux system calls directly, it only requires some modest knowledge of assembly.

This is not really a problem if you're just running games, the chances of games containing such a sophisticated malware are virtually zero, but it's important to understand that TDF is not a safe way to run malware or other software downloaded from dubious sources, it can easily escape the sandboxing and damage the real system. Always use a well isolated VM to test or reverse engineer malware.

To put it short: if you're worried about telemetry and data collection in games, you just don't want games to put files all over your system or you just want to package games, TDF is good; if you're going to run GTAV_Installer.exe (2.9MB) downloaded from SkidEmpressReloadedLegitCracks69 it is very much not.

## What does TDF mean?
This project started off in 2021 as a "template" that I could use to easily create these self-contained ready-made environments to easily and safely run Windows games, something that things like Lutris couldn't do really well despite having a nice GUI.

Eventually, my friends started calling it "Template Di Frederico", meaning Frederico's Template in Italian (Frederico being a common misspelling of my name, Federico); the temporary name eventually stuck, it got abbreviated to TDF or just "the template", and I couldn't come up with a better name so TDF became the official name in 2023 when I finally decided to write some documentation and release it.

## Copyright
All TDF code is distributed under the GNU GPL v3 license, but a built version of TDF will contain components with multiple licenses, including proprietary ones.

Copyright (C) 2021-2023 Federico Dossena

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/gpl-3.0>.
