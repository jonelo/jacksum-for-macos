![GitHub downloads](https://img.shields.io/github/downloads/jonelo/jacksum-fbi-macos/total?color=green)

# Jacksum File Browser Integration on macOS

## Abstract

Allows macOS users to calculate hash values from their files and folders in Finder, just by selecting the algorithm of choice from the script menu. The Finder integration is **powered by Jacksum** which provides **470 algorithms**.

See also [https://jacksum.net](https://jacksum.net) and [https://github.com/jonelo/jacksum](https://github.com/jonelo/jacksum)


## System Requirements

- OS X 10.8 (Mountain Lion) or later, tested up to macOS 11.1 (Big Sur)
- Finder
- JDK 11 or later, see also [https://adoptium.net](https://adoptium.net)
- 2 MiB disk space for Jacksum
- 4 MiB disk space for all .scpt files

## Quick Start

### How to install it

- Download and install a Java Development Kit (JDK), go to [https://adoptium.net](https://adoptium.net)
- Activate the Apple Script Menu, see also [https://support.apple.com/en-tm/guide/script-editor/scpedt27975/mac](https://support.apple.com/en-tm/guide/script-editor/scpedt27975/mac)
- Download and open the [.dmg](https://github.com/jonelo/jacksum-fbi-macos/releases/latest), and double click on the .app

<p align="center">
  <img src="docs/images/Jacksum 3.0.0 FBI on macOS during installation.png" width="629" alt="Jacksum 3.0.0 FBI on macOS during installation">
</p>


### How to use it

#### Using Finder and the script menu

Go to Finder, select files and folders and choose an algorithm from the script folder called "Jacksum 3.0.0" in order to calculate checksums, CRCs and hash values of the selected files.

<p align="center">
  <img src="docs/images/Jacksum 3.0.0 at the script menu.png" width="413" alt="Jacksum 3.0.0 at the script menu">
</p>

#### Using the command line interface

Open a Terminal, and use all features that Jacksum provides.

```
$ /Applications/Jacksum/jacksum
```

### How to configure it

#### Limit the number of algorithms

Open Finder, hit ⇧⌘G, enter the path to the Finder scripts folder `~/Library/Scripts/Applications/Finder`, and click on the Go button.
Click on `Jacksum 3.0.0`, and remove any .scpt file that you don't wanna see.

#### Recreate all algorithms

Just run the .app again.

### How to uninstall it

Open a terminal and type
```
cd
rm -Rf ~/Library/Scripts/Applications/Finder/Jacksum*
rm -Rf /Applications/Jacksum
```


## Tech details

### How to create the .app and .dmg

#### Download and install the Platypus command line tool

The .app will be created by the Platypus command line tool. Platypus is a great tool create Mac apps from command line scripts.
Go to https://sveinbjorn.org/platypus, download and open Platypus, select Preferences and install the command line tool.

#### Run the make_all.sh

Clone or download the sources from the GitHub project, open a terminal and run
```
./bin/make_all.sh
```
That will build the .app and wrap it in a .dmg. You find both the .app and the .dmg in the folder called ./output. 

### How does that all work?

The core of the .app is bash script that installs Jacksum's primary features to macOS Finder's Script Menu by creating applescript scripts and compiling those on the system during the installation.

