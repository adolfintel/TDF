# TDF - Manual
TDF is a small project aiming to make it easy to install, package and safely run Windows games on GNU/Linux. You can think of it as a portable (as in requiring no installation) version of Proton, based on most of the same technology.

__TDF is based on the following awesome projects:__  
* [Wine](https://winehq.org), for Windows emulation, more specifically it includes two custom builds made with [tkg](https://github.com/Frogging-Family/wine-tkg-git), one best suited for modern games, and one more suited for applications and older games
* [DXVK](https://github.com/doitsujin/dxvk), for DirectX 8/9/10/11 emulation, more specifically it includes both the regular version of DXVK built from source, as well as the [gplasync version](https://gitlab.com/Ph42oN/dxvk-gplasync) for cards that don't support the Vulkan GPL extension and [dxvk-nvapi](https://github.com/jp7677/dxvk-nvapi) for nvapi support on nVidia GPUs
* [VKD3D-Proton](https://github.com/HansKristian-Work/vkd3d-proton), for DirectX 12 emulation, built from source
* [xdotool](https://github.com/jordansissel/xdotool), a useful tool to handle games with problematic window/fullscreen behaviors
* [Zenity](https://gitlab.gnome.org/GNOME/zenity), a tool to display simple graphical interfaces such as loading bars, error messages, etc.
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
* Linux kernel 5.16 or newer is strongly recommended, but it will work on older versions. For best compatibility, use the latest kernel.
* A modern-ish distro with basic stuff like the GNU coreutils, glibc, systemd, X11, etc. installed, __both 32 and 64-bit versions__. Arch-based distros will work best.
* An AMD graphics card with the Mesa 23.1 driver or newer is recommended, but it will also work on nVidia and Intel cards. For best compatibility, use the latest driver.
* An SSD is strongly recommended, with a file system like ext4 or btrfs. Do not use NTFS, FAT or exFAT
* You must be able to use a Linux system, do file and folder management, know how to install games manually, know some basic shell scripting, etc.

### Basic usage
* [Download the latest build of TDF](https://downloads.fdossena.com/geth.php?r=tdf-bin) (or build it yourself)
* Extract the archive somewhere, optionally renaming the folder from `template-YYYYMMDD` to something more descriptive. We'll call this folder a TDF instance, you can have as many instances as you want
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

Here's a video showing how to install a game from GOG that requires no additional configuration: [Basic usage - Installing a game from GOG](https://downloads.fdossena.com/geth.php?r=tdfvideo1)

You can find more video examples at the end of this document.

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
The working directory of the game. By default this is set to the same folder where the `game_exe` resides. All paths must be Windows-style.

Example:  
```
game_exe='bin\indy.exe'
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
* `0` (default): check that the executable actually exists and show an error if it doesn't
* `1`: don't check and don't show an error if it doesn't exist

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

__`TDF_UI_LANGUAGE`__  
The language to use for the TDF user interface. Does not affect Wine or games (see `TDF_WINE_LANGUAGE` for that).

By default, TDF tries to obtain the language from the OS. If a translation is not available, it will fall back to English.

Currently implemented languages:  
* `en`: English
* `it`: Italian

### Wine variables
__`TDF_WINE_PREFERRED_VERSION`__  
TDF comes with 2 different versions of Wine and can also use the one on your system (if installed). This variable lets you choose which one you prefer.

Possible values:  
* `games` (default): use the game-optimized build. This version is based on Valve's version of Wine, with the GE and tkg patches and is very similar to [Wine-GE-Proton](https://github.com/GloriousEggroll/wine-ge-custom). Some functionalities have been disabled: anticheat bridges (you can't convince me they're not malware), dbus (automounting of external drives), ISDN, printing, digital camera importing, LDAP and related things, pcap support (network traffic sniffing), smart cart readers support, scanners, low level access to USB devices (does not affect input, that goes over HID), webcam support, Win16 support, winemenubuilder, vkd3d-lib (Wine's own VKD3D implementation, not needed since TDF uses VKD3D-Proton)
* `mainline`: use a mostly regular version of Wine, useful for applications and old games that don't work with the game-optimized build. This version only contains a couple of hotfixes from tkg and the only disabled features are dbus and winemenubuilder for better isolation
* `system`: use the version of Wine that's installed in the system, if it's not installed `mainline` will be used instead
* `custom`: use the version of Wine that you can put in a folder called `wine-custom` outside the system folder (next to `run.sh`). This is useful to keep TDF updates easy for the occasional game that requires custom builds of Wine
* any other value: use the version of Wine in `system/wine-yourValue`. If not found, system Wine will be used instead

__`TDF_WINE_HIDE_CRASHES`__  
When a Wine application crashes, it normally shows a window similar to the "Stopped working" dialog on Windows, but depending on the game and configuration, it may be impossible to interact with that window, leaving you stuck. By default, TDF disables this crash window, but it can be enabled for debugging and troubleshooting purposes.

Possible values:  
* `1` (default): hide the crash window
* `0`: show the crash window

__`TDF_WINE_AUDIO_DRIVER`__  
Sets the preferred audio driver for Wine. This can be useful if you have crackling audio or if one of the drivers has a lower latency than the others. Default is usually fine.

Possible values:
* `pulse`: use PulseAudio (you may also want to add `export PULSE_LATENCY_MSEC=20` for lower latency in music games or `export PULSE_LATENCY_MSEC=120` if you have crackling/dropouts)
* `alsa`: use ALSA
* `jack`: use Jack
* `default` (default): let Wine decide

Note: Choosing a driver that doesn't exist in Wine or in your system will result in no sound being played.

Note: Wine doesn't natively support PipeWire yet, it uses PulseAudio by default for compatibility if you're using PipeWire.

__`TDF_WINE_GRAPHICS_DRIVER`__  
Sets the preferred graphics driver for Wine (as in how it outputs, not how it renders 3D graphics). This can be useful if you're messing around with Wayland and X11 and Wine doesn't work properly.

Possible values:
* `x11`: use X11 (recommended even if you're using Wayland)
* `wayland`: use Wayland (incomplete and buggy at the moment, not recommended)
* `default` (default): let Wine decide (defaults to X11 at the moment, even on Wayland)

Note: Choosing a driver that doesn't exist in Wine or in your system will result in no graphics being displayed.

__`TDF_WINE_DPI`__  
DPI value for display scaling of Wine applications.

Possible values:  
* `-1` (default): use DPI from the main display
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
Optional arguments to pass to Wine's start command. [More info](https://ss64.com/nt/start.html). Mostly useful to set CPU affinity for old games (in this regard, see also `TDF_WINE_MAXLOGICALCPUS`).

Example: `TDF_START_ARGS='/AFFINITY 1'`

__`TDF_WINE_LANGUAGE`__  
By default, TDF will pass the system language to Wine, which may be undesirable for some games and applications that just use the system language instead of showing a language selector. Here's a complete [list of locales](https://docs.oracle.com/cd/E23824_01/html/E26033/glset.html), obviously not all games will support them.

Example: `TDF_WINE_LANGUAGE='it_IT.utf-8'`

__`TDF_WINE_ARCH`__  
The architecture of the Wine installation. Can only be set once, before the initialization is performed, and can't be changed afterwards without deleting the wineprefix.

Possible values:  
* `win64` (default): create a 64-bit Windows installation
* `win32`: create a 32-bit Windows installation (useful for some old games)

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

__`TDF_WINE_DEBUG_GSTREAMER`__  
Enables gstreamer debug output. This can be used to debug issues like games not playing videos or crashing when a video is supposed to play.

Possible values:  
* `0` (default): disabled
* `1`: enable gstreamer debug output

__`TDF_WINE_SMOKETEST`__  
Whether or not to perform a "smoke test" to make sure that Wine actually works before trying to run the game, that way we can tell if a crash is a Wine problem or a game problem. TDF does this by default but you can disable it if it takes too long at the "Starting Wine" screen.

Possible values:  
* `1` (default): do the "smoke test"
* `0`: skip the "smoke test" for faster startup

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

__`export WINEDEBUG`__  
Enables/disables some [Wine debug channels](https://wiki.winehq.org/Debug_Channels).

By default, TDF sets this to `-all` to improve performance, but you might want to enable one or more of these for troubleshooting, or restore the default Wine settings using `unset WINEDEBUG`.

Don't add `+relay` to this variable, as it's controlled by the `TDF_WINE_DEBUG_RELAY` variable.

Example:
```
#log loaded DLLs to the terminal and show the pid of the process that generated each message
export WINEDEBUG=+loaddll,+pid
```

#### Limiting CPU cores (and setting CPU topology in general)
As CPUs get more and more cores and threads, problems such as crashes, inconsistent performance and general instability can occur in older games. For this reason, TDF implements several ways to limit which cores can be used.

__Note: these settings apply to the game-optimized build only__

Before we get into the settings, some terminology:
* Logical CPU: A "core" as you see it in task manager, also known as physical thread. For CPUs with HyperThreading/SMT, 2+ logical CPUs are present for each physical core. Some games work well with SMT, others hate it
* Core: A physical core inside your CPU
* Sockets (multi-CPU systems): refers to the number of CPU chips physically inside your system. For gaming PCs, this is usually 1, but if you're gaming on a harvested multi-CPU server, this is going to be 2+, and not all games react well to that

If a game doesn't support a high number of cores, TDF can limit the number of logical CPUs assigned to it and choose the best ones to maximize performance.

Note: These limits affect the performance of everything running inside Wine, including DXVK and VKD3D. Use them only if absolutely necessary.

Note: if `WINE_CPU_TOPOLOGY` is set, these settings will have no effect.

__`TDF_WINE_MAXLOGICALCPUS`__  
The maximum number of logical CPUs that can be assigned to this game.

Possible values:  
* `0` (default): unlimited
* any other positive number: limit the number of logical CPUs to this value

If the number of logical CPUs exceeds this value, they are assigned intelligently in this way:
* For CPUs with P-cores and E-cores, the first logical CPU of each P-core are assigned first, then E-cores, then the second logical CPU of each core, etc. until we either run out of logical CPUs to assign or the limit is reached 
* For CPUs with HyperThreading/SMT: the first logical CPU of each core is assigned first, then the second logical CPU of each core, etc. until we either run out of logical CPUs to assign or the limit is reached
* For multi-CPU systems, see `TDF_WINE_PREFER_SAMESOCKET` below

__Generally speaking, this is the only limit you should set. Let TDF do the rest for you.__

Example 1: We're on an Intel Core i7 12900K (8 P-cores with 2 threads each, 8 E-cores with 1 thread each, 24 threads in total), the CPU topology is the following (obtained with `lscpu --all --extended`):
```
CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE    MAXMHZ   MINMHZ
  0    0      0    0 0:0:0:0          yes 6700.0000 800.0000
  1    0      0    0 0:0:0:0          yes 6700.0000 800.0000
  2    0      0    1 1:1:1:0          yes 6700.0000 800.0000
  3    0      0    1 1:1:1:0          yes 6700.0000 800.0000
  4    0      0    2 2:2:2:0          yes 6500.0000 800.0000
  5    0      0    2 2:2:2:0          yes 6500.0000 800.0000
  6    0      0    3 3:3:3:0          yes 6500.0000 800.0000
  7    0      0    3 3:3:3:0          yes 6500.0000 800.0000
  8    0      0    4 4:4:4:0          yes 6500.0000 800.0000
  9    0      0    4 4:4:4:0          yes 6500.0000 800.0000
 10    0      0    5 5:5:5:0          yes 6500.0000 800.0000
 11    0      0    5 5:5:5:0          yes 6500.0000 800.0000
 12    0      0    6 6:6:6:0          yes 6500.0000 800.0000
 13    0      0    6 6:6:6:0          yes 6500.0000 800.0000
 14    0      0    7 7:7:7:0          yes 6500.0000 800.0000
 15    0      0    7 7:7:7:0          yes 6500.0000 800.0000
 16    0      0    8 8:8:8:0          yes 3900.0000 800.0000
 17    0      0    9 9:9:8:0          yes 3900.0000 800.0000
 18    0      0   10 10:10:8:0        yes 3900.0000 800.0000
 19    0      0   11 11:11:8:0        yes 3900.0000 800.0000
 20    0      0   12 12:12:9:0        yes 3900.0000 800.0000
 21    0      0   13 13:13:9:0        yes 3900.0000 800.0000
 22    0      0   14 14:14:9:0        yes 3900.0000 800.0000
 23    0      0   15 15:15:9:0        yes 3900.0000 800.0000
```

If you want to play Colin McRae Dirt (2007), a game that supports 4 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=4`, and with this CPU TDF will select logical CPUs 0,2,4,6, because they are the fastest cores available, one thread per core.

If you want to play Lara Croft and the Guardian of Light (2010), a game that supports 12 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=12`, and with this CPU TDF will select logical CPUs 0,2,4,6,8,10,12,14,16,17,18,19. The first 8 are the P-cores, one thread per core, the last 4 are E-cores, one thread per core.

If you want to play The Witcher 2 (2010), a game that supports 31 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=31`, and with this CPU TDF will not apply any special restriction because it only has 24 logical CPUs.

Example 2: We're on an AMD Ryzen 7 5800X (8 cores with 2 threads each, 16 threads in total), the CPU topology is the following:
```
CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE    MAXMHZ    MINMHZ
  0    0      0    0 0:0:0:0          yes 4850.1948 2200.0000
  1    0      0    1 1:1:1:0          yes 4850.1948 2200.0000
  2    0      0    2 2:2:2:0          yes 4850.1948 2200.0000
  3    0      0    3 3:3:3:0          yes 4850.1948 2200.0000
  4    0      0    4 4:4:4:0          yes 4850.1948 2200.0000
  5    0      0    5 5:5:5:0          yes 4850.1948 2200.0000
  6    0      0    6 6:6:6:0          yes 4850.1948 2200.0000
  7    0      0    7 7:7:7:0          yes 4850.1948 2200.0000
  8    0      0    0 0:0:0:0          yes 4850.1948 2200.0000
  9    0      0    1 1:1:1:0          yes 4850.1948 2200.0000
 10    0      0    2 2:2:2:0          yes 4850.1948 2200.0000
 11    0      0    3 3:3:3:0          yes 4850.1948 2200.0000
 12    0      0    4 4:4:4:0          yes 4850.1948 2200.0000
 13    0      0    5 5:5:5:0          yes 4850.1948 2200.0000
 14    0      0    6 6:6:6:0          yes 4850.1948 2200.0000
 15    0      0    7 7:7:7:0          yes 4850.1948 2200.0000
```
(Notice the different interleaving in the CORE column compared to the previous example).

If you want to play Colin McRae Dirt (2007), a game that supports 4 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=4`, and with this CPU TDF will select logical CPUs 0,1,2,3, which are simply the first 4 logical CPUs, one per core.

If you want to play Lara Croft and the Guardian of Light (2010), a game that supports 12 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=12`, and with this CPU TDF will select logical CPUs 0,1,2,3,4,5,6,7,8,9,10,11. The first 8 are the first logical CPU of each core, one thread per core, the last 4 are the second logical CPU of the first 4 cores.

If you want to play The Witcher 2 (2010), a game that supports 31 cores at most, you'll have to set `TDF_WINE_MAXLOGICALCPUS=31`, and with this CPU TDF will not apply any special restriction because it only has 16 logical CPUs.

__`TDF_WINE_NOSMT`__  
Whether to hide the additional logical CPUs on CPUs that support HyperThreading/SMT.

Possible values:  
* `0` (default): use SMT
* `1` : do not use SMT. If this is set, only the first logical CPU of each core will be used, the others will be ignored. This can improve the performance of some older games.

__`TDF_WINE_NOECORES`__  
Whether to hide E-cores on CPUs like Intel Alder Lake.

Possible values:  
* `0` (default): use E-cores
* `1` : do not use E-cores

Note: for compatibility reasons, these CPUs have no easy way to tell which cores are P-cores and each ones are E-cores, so TDF "guesses" that the E-cores are the ones with a maximum clock that's <75% of that of any other core. This may be improved in the future.

__`TDF_WINE_PREFER_SAMESOCKET`__  
For systems with multiple CPUs only, how to use them.

Possible values:  
* `1` (default): assign logical CPUs based on speed, but prioritize cores on the same physical CPU (first assign all the logical CPUs in the first socket, then the second, etc.). This is generally the best for games.
* `0` : logical CPUs are assigned based exclusively on speed, regardless of which CPU they are physically on. This is generally not recommended for games.
* `2` : restrict to the first CPU

__`export WINE_CPU_TOPOLOGY`__  
This is not a TDF variable, but it allows you to set Wine to use specific CPU cores, similar to the `/AFFINITY` option of the `start` command in Windows, but more fine grained. This should be used as a last resort or if you want to do dumb things like restrict a game to only use E-cores.

Example:
```
#limits wine to one CPU core
export WINE_CPU_TOPOLOGY="1:0"
```

Example:
```
#limits wine to use the first 4 CPU cores
export WINE_CPU_TOPOLOGY="4:0,1,2,3"
```

Note: if `WINE_CPU_TOPOLOGY` is set, the settings above will have no effect.

#### DXVK and VKD3D variables
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

__`TDF_DXVK_NVAPI`__  
Whether to install DXVK-nvapi or not, which provides nvapi support for nVidia GPUs. Requires `TDF_DXVK` to be set to `1`.

Possible values:  
* `0` (default): don't use DXVK-nvapi
* `1`: use DXVK-nvapi on nVidia GPUs

__`TDF_VKD3D`__  
Whether to install VKD3D-Proton, which provides DirectX 12 emulation through Vulkan. If this is disabled, Wine's version of VKD3D is used instead, which has very poor game compatibility compared to this version.

Possible values:  
* `1` (default): use VKD3D-Proton
* `0`: use Wine's VKD3D implementation

VKD3D's config can be changed by using its [environment variables](https://github.com/HansKristian-Work/vkd3d-proton#environment-variables). By default, doesn't set this variable, meaning that VKD3D will automatically enable ray tracing on supported cards. Older versions of TDF (before November 2023) set this to `dxr11` to enable ray tracing.

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

Notes:
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
Restores the gamma level previously saved with `saveGamma`. If a gamma level was never saved, it restores the gamma level from when TDF was started.

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

__`resetResolution`__  
Resets the main display to its default screen resolution an gamma. This is useful for when you're not using the game-optimized wine build and an old game crashes without restoring the screen resolution.

Returns 0 if the operation succeeded, 1 if an error occurred.

Note: this function only works on X11.

Example:  
```
TDF_WINE_PREFERRED_VERSION='mainline'
onGameEnd(){
    resetResolution
}
```

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

Note: the `TDF_UI_LANGUAGE` variable can only be set in `vars.conf`, since it's applied before TDF is started, all other variables can be changed at any moment.

By default, when the list of games is displayed, they are shown in alphabetical order. If you want them to appear in a specific order, create a file called `_list.txt` in the `confs` folder, with the list of the configuration files in the order in which you want them to appear (filenames only, no extension).

Example:
```
Mass Effect 1
Mass Effect 2
Mass Effect 3
Mass Effect 1 - Configuration Utility
Mass Effect 2 - Configuration Utility
Mass Effect 3 - Configuration Utility
Command Prompt (for modding)
Windows Explorer (for modding)
```

### Packaging and redistributing a TDF instance
You installed your game(s) in a TDF instance and made sure it works perfectly? Did you test it on different hardware? Different distros? All good? Great! You're ready to package it.

To start the packaging process, open a terminal inside the TDF instance and type `./run.sh archive`. This will create an archive containing the whole TDF instance that you can easily redistribute (assuming you have the rights to do it). Users will be able to simply extract these archives and launch `run.sh` to start the game.

By default, TDF creates a highly compressed `.tar.zst` archive, which takes a long time to create but can be extracted very quickly.

During the compression process, TDF will show you a progress indicator. At the end of the process, it will tell you the compressed size and the compression ratio.

If you want to customize the way these archives are created, the following short commands can be added after `./run.sh archive`:
* `nocompress`: creates a simple uncompressed `.tar` archive. Very fast but not ideal for redistribution
* `fastcompress`: creates a compressed `.tar.xz` archive, compressed with multithread XZ. Compression is relatively fast, decompression is also quite fast, but the compression ratio is not the best
* `maxcompress`: creates a compressed `.tar.zst` archive, compressed with single thread ZStandard with the highest settings. This is pretty slow but decompression is very fast and also has good compression ratio. This is what Fitgirl would call a "monkey repack"

Generally speaking, the short commands above are the only ones you should need but if you want to customize it further, you can specify the following options after `./run.sh archive` instead of the short commands above:
* `-o path`: path to output file (relative or absolute). If the path contains an extension such as .tar.zst, TDF will automatically select the appropriate compression method; otherwise an appropriate extension will be added automatically. If not specified, it creates a file with the same name as the folder containing the TDF instance.
* `-m method`: compression method to use. Supported values are `zstd` (default), `xz`, `gzip` and `tar` (uncompressed). Not required if a file extension has already been specified with `-o`
* `-p preset`: compression preset to use. TDF provides 3 presets for each method: `max` (slow but smallest size), `normal` (balances speed and compression), `fast` (favors speed over compression). By default, `zstd` uses `max`, which is very slow, `xz` uses `fast` and `gzip` uses `normal`, `tar` does not compress so this parameter will be ignored
* `-f`: overwrite the output file if it already exists, otherwise it will just show an error
* `-s size`: split the output file in a multipart archive of the specified size. Supported values are any positive integer followed by `M` or `G`, such as `100M` or `1G`. `auto` can also be used to automatically decide the split size based on input size, similar to scene releases (<1G: 100M parts, 1G-10G: 1G parts, 10G-100G: 5G parts, 100G-250G: 10G parts, 250G-500G: 25G parts, >500G: 100G parts). A script to extract the multipart archive will also be created, in case your archive manager doesn't support it.

Examples:
```bash
#compress using zstd maximum to a file called example.tar.zst in the upper directory
./run.sh archive -o ../example.tar.zst
```
```bash
#compress using xz normal to a file called example.tar.xz in the home directory
./run.sh archive -m xz -p normal -o ~/example.tar.xz
```
```bash
#compress using xz fast to a file with the same name as the current folder and put it in the upper directory
./run.sh archive -m xz -p fast
```
```bash
#compress using zstd maximum to a file called example.tar.zst in the upper directory, split in 5G parts
./run.sh archive -o ../example.tar.zst -s 5G
```

Note: this feature assumes that `tar`, `xz`, `gzip` and `zstd` are installed on your system (they probably are).

If you want to transfer a TDF instance from one PC to another using an external drive, it is strongly recommended to use the archive function so that it's just one big file. __Never copy a TDF instance to an NTFS, exFAT or a FAT32 partition, it will become unusable.__

### Updating a TDF instance
TDF is designed to be easy to update. To update a TDF instance from an older version:
* Download (or build) a new version of TDF
* Delete the `system` folder and `run.sh`
* Copy `system` and `run.sh` from the newer version to the TDF instance, where the old ones used to be
* Launch run.sh and it will update everything automatically

It is also possible to downgrade to an older version of TDF in the same way, in case the newer version introduces some problems.

### Using custom versions of Wine, DXVK, etc.
TDF will automatically detect and apply changes to the files in the following folders inside the `system` of a TDF instance:
* `dxvk`
* `dxvk-async`
* `dxvk-nvapi`
* `localization`
* `msi`
* `tdfutils`
* `vcredist`
* `vkd3d`
* `wine-games`
* `wine-mainline`
* `xutils`
* `zenity`

So for instance, if you need to test a custom version of DXVK, simply replace the DLLs in `system/dxvk` with your build (making sure to keep the same folder structure), when you launch `run.sh`, TDF will detect that these DLLs don't match the ones in the wineprefix and reinstall DXVK. The same goes for Wine and other components in the list above.

Note: your custom files will only be used if that component is actually being used. For instance, if your GPU supports the `VK_EXT_graphics_pipeline_library`, then DXVK-gplasync will never be used unless you explicitly set `TDF_DXVK_ASYNC=1` or switch to an older driver.

The following folders are not monitored for changes as they are very rarely needed:
* `corefonts`

Should you need to test changes to them, simply disable that component, launch `run.sh`, then reenable it and launch it again.

### Removing unused components
TDF is built to be partially modular, meaning that if your game doesn't need certain components, such as Wine Mono, they can be removed to reduce overhead.

__Do not do this unless you know what you're doing.__

The following folders can be deleted from the `system` folder of a TDF instance if they are not needed:
* `dxvk`
* `dxvk-async` (Note: if this is removed, it is recommended to set `TDF_DXVK_ASYNC=0`, that way it won't try to use it on GPUs that don't support the GPL extension)
* `dxvk-nvapi`
* `msi/winemono.msi`
* `msi/winegecko32.msi` and `msi/winegecko64.msi`
* `tdfutils`
* `vcredist`
* `vkd3d`
* `wine-games` (Note: if this is removed, it is recommended to set either `TDF_WINE_PREFERRED_VERSION="mainline"` or `TDF_WINE_PREFERRED_VERSION="system"`, otherwise TDF will try to use the version of Wine provided by the system or `wine-mainline` as a last resort. If neither are available, TDF will fail to start)
* `wine-mainline` (Note: if this is removed, it is recommended to set either `TDF_WINE_PREFERRED_VERSION="games"` or `TDF_WINE_PREFERRED_VERSION="system"`, otherwise TDF will try to use the version of Wine provided by the system or `wine-games` as a last resort. If neither are available, TDF will fail to start)
* `zenity` (Note: if this is removed and Zenity is not installed in the system, TDF will still work but it will not have a GUI)

Folders and files not mentioned in this list should not be removed to avoid breaking TDF.

If a component has been removed, TDF will not try to use or install it even if explicitly requested in the config. If a component is removed after it has been installed in the wineprefix, it will not be removed even if explicitly requested in the config.  
For these reasons, it's better to remove components before the first time initialization of the wineprefix.

__Never remove a component that is currently installed in the wineprefix__, as this will leave it in an inconsistent state, especially during Wine updates. If that happens, simply restore the removed components and TDF should take care of the problem.

### Troubleshooting
This section covers troubleshooting games on Wine in general, with a focus on how to do it with TDF. In general, some good knowledge of Windows and Linux will be very useful here.

If a game doesn't work out of the box, before you even start troubleshooting, check [ProtonDB](https://www.protondb.com/) for known issues/fixes for this game. Solutions that work on Proton can easily be adapted to work in TDF.

#### TDF won't start (Failed to load Wine)
Wine depends on a lot of libraries, both 32 and 64 bit. The easiest way to obtain these is to simply install Wine on your system and then removing it.
* Install missing 32-bit libraries
    * For Arch-based distros see here: [Enabling multilib](https://wiki.archlinux.org/title/Official_repositories#Enabling_multilib) (not required for Manjaro)
    * For Debian-based distros:  
        ```
        sudo dpkg --add-architecture i386
        sudo apt-get update
        ```
* If it still doesn't work, install missing libraries by installing Wine and then removing it
    * For Arch-based distros:
        ```
        sudo pacman -S wine
        sudo pacman -R wine
        ```
    * For Debian-based distros:
        ```
        sudo apt-get install wine
        sudo apt-get remove wine
        ```
* If it still doesn't work, your distro may have a version of glibc that's older than the one that was used to build the prebuilt version of TDF that you have downloaded. You can verify this by opening the terminal and typing `./run.sh`, and looking at the errors that appear while TDF tries to load. If this is your case, at the moment the only solution is either building TDF yourself or using a more modern distro

#### Game won't install, the installer doesn't start, doesn't work, it freezes or gives an error during the installation
* Try using `TDF_WINE_PREFERRED_VERSION='mainline'` during the installation, using a normal version of Wine instead of the game-optimized one can get it to work
* Try using `export WINE_HEAP_DELAY_FREE=1` during the installation, this can workaround memory management bugs in the installer (very useful for repacks)
* Find another version of the game with a different installer, like a Steam rip, an ISO, or a repack from another group
* As a last resort, try installing the game in a Windows VM and copy the files over to `zzprefix/drive_c`

#### During the installation, I see error messages about .net or being unable to ShellExecute something
* These are not a problem in Wine, ignore them

#### Game won't launch (DRM issues like disc not found or requiring a login)
* Use a cracked version of the game
* If this is a cracked game, the crack may not have been loaded correctly due to a missing DLL override (see `WINEDLLOVERRIDES`) or it could be missing some DLL (see next section)

#### Game won't launch ("Game running" dialog disappears immediately)
* Often caused by missing DLLs
    * If there's a folder called `_CommonRedist` or `_Redists` in the game's folder, that will most likely contain some installers for libraries required by the game. They're usually not necessary with Wine but some older redists like PhysX will need to be installed.
        * Remove `game_exe` and launch `run.sh`
        * Navigate to that folder and install the redists
        * Put back `game_exe` and try launching the game again
    * If it still doesn't work, investigate missing DLLs
        * Add `export WINEDEBUG=-all,+loaddll` to `vars.conf`
        * Open a terminal and run `./run.sh`
        * While the game is starting you'll see each DLL that it tries to load, if you see errors about missing DLLs, they need to be installed
            * Missing files like `xinput1_3.dll` or `d3dcompiler_43.dll` indicates that you need to install the [old DirectX redistributable](https://www.microsoft.com/en-us/download/details.aspx?id=8109)
            * Missing files like `mscoree.dll` indicates that you're trying to load a .net application, try adding `TDF_WINEMONO=1` to the configuration
            * Missing files like `msvcrt###.dll` or `vcruntime###.dll` indicates that you need a specific version of the Microsoft Visual C++ Redistributable
            * Missing files like `mshtml.dll` indicates that you're trying to load an application that depends on Internet Explorer, try adding `TDF_WINEGECKO=1` to the configuration
            * Missing any file that's not part of Windows or some Microsoft redistributable indicates that there's a problem with the game installation (incomplete/corrupt setup)
        * Once you've downloaded what you need
            * If it's a single DLL just copy it to the game's folder
            * If it's an installer, remove `game_exe` from the configuration and launch `run.sh` to enter "install mode", install what you downloaded, then put back `game_exe` and try launching the game again
* If you don't see complaints about missing DLLs, it could be that the game is crashing immediately
    * Add `unset WINEDEBUG` and `TDF_WINE_HIDE_CRASHES=0` to enable Wine's default debugging messages and "stopped working" screen
    * Open a terminal and run `./run.sh`
    * While the game is trying to start, you'll see a lot of messages in the terminal, most of them are innocuous, but some of them may provide some info about the problem that you can search online. Typical causes are missing files/registry keys, issues with video playback, incompatibility with DXVK/VKD3D-Proton (rare), DRM issues, mods failing to load. It's hard to tell and you'll have to figure it out
        * A useful tool to investigate is Wine's relay feature, which logs all interaction between the application and the system to a file. To enable relay, add `TDF_WINE_DEBUG_RELAY=1` and launch the game, it will ask you where you want to save the trace and then try to launch the game. Keep in mind that Wine runs extremely slow while this is enabled and the generated trace could be several GB in size
        * After the game has crashed, open the trace with a text editor and start looking for clues (especially around the end of the file)
* If your game is a UWP app (like an extracted appx package), this is not supported by Wine at the moment, you'll need a regular Win32 version of the game. This is easily identifiable by the presence of an .appx version of VCRuntime
* If this is an older game, it may not support high core count CPUs, try setting `TDF_WINE_MAXLOGICALCPUS=4` to simulate a quad-core
    
#### Game launcher doesn't work (closes immediately or has garbled graphics)
* Find some way online to bypass the launcher, usually it involves setting `game_exe` to another file or adding some arguments with `game_args`
* Find an alternative launcher online
* Some games have .net applications as launchers or they need Internet Explorer, try adding `TDF_WINEMONO=1` and `TDF_WINEGECKO=1`

#### The game uses the wrong GPU (integrated instead of dedicated)
* Add `export DRI_PRIME=1` to the config, where 1 is the number of the GPU that you want to use (starting from 0)

#### Mods with DLL files don't work
* Wine doesn't automatically load overrides for system DLLs like `dinput8.dll`, `version.dll`, `winmm.dll`, `dsound.dll`, etc., this is a common technique used by mods to inject code, add `export WINEDLLOVERRIDES="filename1,filename2,...=n,b"`. Note that the filenames must not have an extension, only the name. Example: `export WINEDLLOVERRIDES="winmm=n,b"`.

#### Game starts with the wrong language with no way to change it
* See the `TDF_WINE_LANGUAGE` variable
* If the game is using a Steam/EGS/whatever emulator, there's usually an file nearby like `steam_api.ini` that will contain some configuration, including the language
* Some games require a command line option to change the language (`game_args` variable)
* Some older games store the language in the registry, remove `game_exe` from the configuration to get into "install mode", run regedit and find the key

#### Game detects incorrect amount of VRAM or says that the video driver is out of date
* Modern games usually obtain this information through a proprietary API like AMD AGS. If you see files like `amd_ags_x64.dll` or `nvapi.dll`, you can force Wine to use its own fake version to fix this problem by adding `export WINEDLLOVERRIDES="amd_ags_x64=b"`. If you need to add multiple overrides, separate them with a semicolon. Example: `export WINEDLLOVERRIDES="winmm=n,b;amd_ags_x64=b"`

#### Game crashes/freezes during gameplay, graphical or performance issues
* Make sure TDF is updated to the latest version
* Make sure you're running the latest Linux kernel and the latest version of Mesa (AMD/Intel) or the nVidia drvier. Ideally, if you're on an Arch-based distro, use the mesa-git package from the AUR
* If you experience severe stuttering or performance drops, these are some likely causes:
    * For DX9-11 games (DXVK), make sure your system supports the `VK_EXT_graphics_pipeline_library` extension by running this command: `vulkaninfo | grep VK_EXT_graphics_pipeline_library`, if you don't see anything, your GPU/driver doesn't support it and your experience will be miserable
    * You may be running out of VRAM. Linux doesn't handle this very well, games will stutter heavily or have a sudden drop in performance when that happens. Try installing MangoHud and add `TDF_MANGOHUD=1`, this provides a nice overlay for various things, including VRAM usage. When it's above 90%, you'll start running into problems
    * If this is a modern game, your CPU may not be fast enough to handle the game and the emulation overhead
    * If this is an older game, it may not support high core count CPUs, try setting `TDF_WINE_MAXLOGICALCPUS=4` to simulate a quad-core 
    * The game may have issues with fsync (Uncharted 4 is the only one I've encountered so far), try adding `TDF_WINE_SYNC="esync"`
    * If this is an old UE2-based game like UT2004, this is a known issue and as of August 2023 a solution is in the works
* If this is an older game, it may not support high core count CPUs, try setting `TDF_WINE_MAXLOGICALCPUS=4` to simulate a quad-core
* If this is an older game, it may also be a good idea to run it using regular Wine, add `TDF_WINE_PREFERRED_VERSION=mainline`
* If this is a DX8-11 game, try running it with WineD3D instead of DXVK by adding `TDF_DXVK=0`
* If this is a DX8-10 game and you see striped shadows, your graphics driver probably doesn't support the `VK_EXT_depth_bias_control` extension yet (added in Mesa 23.3 for AMD/Intel)
* Look for known issues and fixes for this game in the [DXVK issues page](https://github.com/doitsujin/dxvk/issues) (DX9-11), the [VKD3D-Proton issues page](https://github.com/HansKristian-Work/vkd3d-proton/issues) (DX12), and if you're on an AMD/Intel GPU check the [Mesa issues page](https://gitlab.freedesktop.org/mesa/mesa/-/issues) as well
* If this is a DX9-11 game, create a file called `dxvk.conf` in the game's folder and tinker with [DXVK's settings](https://github.com/doitsujin/dxvk/wiki/Configuration)
* If this is a DX12 game, try tinkering with [VKD3D-Proton's settings](https://github.com/HansKristian-Work/vkd3d-proton#environment-variables)
* If the game supports DXR, try adding `unset VKD3D_CONFIG` to disable ray tracing support that's normally enabled by default by TDF
* If you're on AMD/Intel, try tinkering with [Mesa's settings](https://docs.mesa3d.org/envvars.html). These are some typical settings to try first for issues on AMD (try them one by one!):
    * `export RADV_DEBUG=nodcc`
    * `export RADV_DEBUG=llvm`
    * `export ACO_DEBUG=noopt`
    * `export RADV_PERFTEST=nosam`
    * `export AMD_DEBUG=nongg`
* Some games have memory management issues that can be workarounded by adding `export WINE_HEAP_DELAY_FREE=1`
* Look for game-specific fixes on [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Home), even if it's focused on Windows, the same fixes often apply to Wine as well
* If this is an old DX9 game, add `unset WINEDEBUG` to the configuration, open a terminal and run `./run.sh`, if you see errors about shader compilation, you probably need to install the [old DirectX redistributable](https://www.microsoft.com/en-us/download/details.aspx?id=8109)
* It is extremely rare but some very old games don't work with Wine's msvcrt/msvcp, for those you'll have to find an old version of the Visual C++ Redistributable (version 6 and older) or take it from Windows, put the DLLs in the game's folder and add `export WINEDLLOVERRIDES="msvcrt,msvcp=n,b"`
* Add `unset WINEDEBUG` and `TDF_WINE_HIDE_CRASHES=0` to the config, open a terminal and run `./run.sh`, most of the messages you'll see are innocuous, but some may provide clues about what's going on

If you find a solution to a problem, always make sure to report it somewhere. If you can't find a solution, report the problem to one of the projects involved, at worst they'll tell you it's not their fault and where to report it. People are generally very friendly in the Linux gaming community.

#### Sound crackling, cutting in and out, etc.
* Increase sound buffer size by adding `export PULSE_LATENCY_MSEC=120`
* If this is an older game, try using an EAX emulator like [DSOAL](https://github.com/kcat/dsoal), you can find prebuilt DLLs online if you don't want to mess with Visual Studio, all you have to do is put them in the game's folder and add `export WINEDLLOVERRIDES="dsound=n,b"`
* The game may not support surround sound or your sample rate, set your system to 44.1KHz stereo
* If the sound issues are happening mostly when there's heavy CPU load (shader compilation, entering new areas, etc.) and you're using pipewire, your system may be affected by [this issue](https://wiki.archlinux.org/title/PipeWire#Missing_realtime_priority/crackling_under_load_after_suspend)

#### Videos don't play or game crashes when a video is supposed to play
* Try adding `TDF_WINE_DEBUG_GSTREAMER=1`, it may provide details about what's happening

#### Window positioning issues (stuck in window mode, partially off screen, etc.)
* If this is an older game, it may not support display scaling, try adding `TDF_WINE_DPI=96`
* See the section on Builtin functions for how to lock on to a window and manipulate it, or watch my video about A Plague Tale Requiem

#### TDF says the wineprefix is already running but the game is not
* The game probably left a background process running. Open your favorite task manager and kill any process's a Windows exe
* If this happens frequently, try adding `TDF_WINE_KILL_AFTER=1`, this will terminate all Wine processes when the game's main process terminates

#### Game controller not detected/not working
* Wine has built-in support for Xbox and Dualshock controllers, but you may have to add some udev rules to allow your user permissions to use them. If you're on an Arch-based distro, the `game-devices-udev` package on the AUR will take care of most models, otherwise, [this article will help](https://wiki.archlinux.org/title/Gamepad) users of all distros

#### TDF no longer starts after being copied/moved to an external drive or syncing through cloud to another computer
* To transfer a TDF instance, you should use the archive feature instead, it's faster and more reliable
* If you're using syncthing to keep a TDF instance synced between PCs, you need to set that folder to sync and send extended attributes on all your machines. This is a bad idea though, a much better thing to do would be to only sync the saved games folder inside that TDF instance
* If you moved a TDF instance to an NTFS, exFAT or god forbid a FAT32 drive, or any other file system that doesn't support UNIX permissions and symlinks, you're out of luck and I told you so in the beginning of this document. Recover your saved games from `zzprefix` and start over with a new TDF instance

## Building TDF
The TDF build scripts are designed to download the latest version of each component in TDF, build what needs to be compiled from source and create a `template-YYYYMMDD.tar.zst` ready to extract and use.

__It is strongly recommended to use an Arch-based distro to build TDF.__

To build TDF:  
* Download the latest version of this repo: `git clone https://github.com/adolfintel/tdf`
* Enter the downloaded folder: `cd tdf`
* Launch the automatic build script: `./makeTemplate.sh`

The following dependencies must be installed on your system:  
* Basic tools like coreutils, gcc, g++, wget, curl, git, make, meson, sed, tar, zstd, etc. (on Arch-based distros, the `base-devel` package should provide everything you need)
* Wine and its dependencies. (on Arch-based distros, the easiest way to get all of these is to install the wine-git package from the AUR)
* Mingw-w64
* glslc (glslang)

The following components will be downloaded:  
* Wine Mono: latest version from [Github](https://github.com/madewokherd/wine-mono/releases/)
* Wine Gecko: latest 32 and 64-bit versions from the [Wine website](https://dl.winehq.org/wine/wine-gecko/)
* Microsoft Corefonts: from [Sourceforge](https://sourceforge.net/projects/corefonts/)
* Microsoft Visual C++ Redistributable: latest 32 and 64-bit versions from Microsoft

The following components will be built from source:  
* Wine: latest master using the [wine-tkg build system](https://github.com/Frogging-Family/wine-tkg-git) with some custom config
* DXVK: latest master from [Github](https://github.com/doitsujin/dxvk)
* DXVK-gplasync: latest patch from [Gitlab](https://gitlab.com/Ph42oN/dxvk-gplasync) applied to the latest master of DXVK
* DXVK-nvapi: latest master from [Github](https://github.com/jp7677/dxvk-nvapi)
* VKD3D-Proton: latest master from [Github](https://github.com/HansKristian-Work/vkd3d-proton)
* xdotool: latest master from [Github](https://github.com/jordansissel/xdotool)
* zenity: version 3.44 from [Gnome's GitLab](https://gitlab.gnome.org/GNOME/zenity)
* Some C programs included with the TDF source code used

The first build will take a good 30-60 minutes to download and compile everything, but subsequent builds will be quicker as the download phase will only download updates for the components and the TDF repo itself.

If the build fails (and let's be honest, the first times it probably will), fix the problem and run `./makeTemplate.sh` again, the script will automatically resume from where it left off.

If you don't want to use this caching and resuming system, you can run a clean build using `./makeTemplate.sh clean`, this will delete all saved data and redownload everything, then build TDF.

If you're going to build TDF regularly, you can enable automatic updates for the TDF repo using `TDF_BUILD_AUTOUPDATE=1 ./makeTemplate.sh` (git only).

At the end of the build process, the package will be compressed using a slow but efficient zstd compression and the finished archive will be ~310MB.

## Important security notice
While TDF provides some additional security compared to a standard installation of Wine or Proton, it is important to understand that Wine is simply not designed for security, quite the opposite, it's designed to seamlessly integrate Windows stuff into Linux.

Wine is an HLE (High Level Emulator) which means that, to put it simply, it doesn't emulate an entire system like dosbox does because it would be too slow, instead it provides a way to load Windows exe files, intercept Windows system calls and "convert" them to equivalent Linux system calls. It also provides a ton of libraries and other functionality but that's not relevant here.

What this means is that a process running inside Wine is, to all intents and purposes, a regular UNIX process that's running under your user, and therefore has access to everything you have access to, and malicious software can easily escape the restrictions put in place by Wine or TDF by using Linux system calls directly, it only requires some modest knowledge of assembly.

This is not really a problem if you're just running games, the chances of games containing such a sophisticated malware are virtually zero, but it's important to understand that TDF is not a safe way to run malware or other software downloaded from dubious sources, it can easily escape the sandboxing and damage the real system. Always use a well isolated VM to test or reverse engineer malware.

To put it short: if you're worried about telemetry and data collection in games, you just don't want games to put files all over your system or you just want to package games, TDF is good; if you're going to run GTAV_Installer.exe (2.9MB) downloaded from SkidEmpressReloadedLegitCracks69.ru it is very much not.

## TODOs and future improvements
* Implement something similar to the Steam Runtime but based on Arch to mitigate Wine's dependency hell
* Automatically recognize some known problematic games and apply tweaks to the configuration
* Find some way to build against old versions of glibc for better compatibility, ideally using the Steam Runtime SDK (Wine-tkg currently fails to build on Debian-based distros due to conflicting dependencies)

## Videos
* [Basic usage - Installing a game from GOG](https://downloads.fdossena.com/geth.php?r=tdfvideo1)
* [Basic usage - Installing Steam rips](https://downloads.fdossena.com/geth.php?r=tdfvideo2)
* [Basic usage - Installing a game from ISO](https://downloads.fdossena.com/geth.php?r=tdfvideo4)
* [Troubleshooting: Video driver out of date message](https://downloads.fdossena.com/geth.php?r=tdfvideo3)
* [Troubleshooting: Repack fails to extract, game with graphical issues](https://downloads.fdossena.com/geth.php?r=tdfvideo5)
* [Advanced usage - Multiple games in one TDF instance (and some minor troubleshooting)](https://downloads.fdossena.com/geth.php?r=tdfvideo6)
* [Troubleshooting: A Plague Tale Requiem (Window positioning, graphical issues, crackling audio)](https://downloads.fdossena.com/geth.php?r=tdfvideo7) (Note: this video was shot before all the others, the version of TDF shown is a bit older)
* [Basic usage - Installing a multiplayer game](https://downloads.fdossena.com/geth.php?r=tdfvideo8)
* [Advanced usage - Capturing with Apitrace and RenderDoc](https://downloads.fdossena.com/geth.php?r=tdfvideo9)
* [Basic usage - Creating a game archive to redistribute it or to move it to another computer](https://downloads.fdossena.com/geth.php?r=tdfvideo10)
* [Callbacks: Automatically backup your saved game, just in case...](https://downloads.fdossena.com/geth.php?r=tdfvideo11)

__Important: some cracked copies of games that I have in my Steam/GOG/EGS library are used in these videos. These cracks have been used to circumvent DRM issues or incompatibilities with modern systems. TDF does not endorse piracy and I will not provide cracked copies of games.__

## What does TDF mean?
This project started off in 2021 as a "template" that I could use to easily create these self-contained ready-made environments to easily and safely run Windows games, something that things like Lutris couldn't do really well despite having a nice GUI.

Eventually, my friends started calling it "Template Di Frederico", meaning Frederico's Template in Italian (Frederico being a common misspelling of my name, Federico); the temporary name eventually stuck, it got abbreviated to TDF or just "the template", and I couldn't come up with a better name so TDF became the official name in 2023 when I finally decided to write some documentation and release it.

## License
All TDF code is distributed under the GNU GPL v3 license, but a built version of TDF will contain components with multiple licenses, including proprietary ones.

Copyright (C) 2021-2024 Federico Dossena

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
