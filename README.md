# TemplateDiFrederico

This is a small project (temporary name) that implements a readymade template to run
Windows games on GNU/Linux using Wine and related tools.

This template is meant to be easy to customize through bash scripting and not tied
to any particular platform.

## Features

The template automates setting up wine and related tools for a windows game. By default it enables some
protections against data collection and DRM by blocking network access and doing some
light sandboxing of the windows processes.

## Requirements

- Linux Kernel 5.16+ and Wine dependencies installed (tested on Manjaro, Arch Linux and similar)
- some basic conf file editing skills, and troubleshooting skills

## Building from source

Clone the repo then run `makeTemplate.sh`

The script will retrieve necessary components (wine-ge, dxvk, vkd3d, others) and
create a `tar` archive with the timestamp of the template compilation.

vkd3d and DXVK will be compiled. Make sure you have the necessary dependencies.

At the end of the process, a file called `template-YYYYMMDD.tar.zst` will be created.

## Usage

1. Extract the `template-YYYYMMDD.tar.zst` archive to a folder. This will be your game's folder
2. run the `run.sh` script and wait for the initialization to complete
3. a windows CMD prompt will open. Use this to install your game, for example by launching `explorer` and then picking an `exe` setup file. If your game has no setup, exit and manually copy the file into the wine prefix in the `zzprefix` folder
4. after installing, edit `vars.conf` and enter the path of the folder where the executable is, the executable name, and optionally any arguments
5. run `run.sh` and the game should play

### Archive mode

It's possible to use `run.sh archive` to create a tar archive of the template and the game.
This is useful to store a backup or copy the game to another machine.


