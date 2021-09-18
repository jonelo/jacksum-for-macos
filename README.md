# Jacksum File Browser Integration on macOS

## Abstract

Allows macOS users to calculate hash values from their files and folders in Finder, just by selecting the algorithm of choice from the script menu. The Finder integration is powered by Jacksum which provides 470 algorithms for calculating and verifying CRCs, checksums and hash values. See also https://jacksum.net and https://github.com/jonelo/jacksum


## System Requirements

- Mac OS X 10.8 (Mountain Lion) or later, tested up to macOS 11.1 (Big Sur)
- JDK 11 or later, see also https://adoptium.net

## Quick Start

### How to install and configure it

- Download and install a Java Development Kit (JDK), go to https://adoptium.net
- Activate the Apple Script Menu, see also https://support.apple.com/en-tm/guide/script-editor/scpedt27975/mac
- Download and open the .dmg, and double click on the .app

### How to use it

#### Using Finder and the script menu

Go to Finder, select files and folders and choose an algorithm from the script folder called Jacksum in order to calculate checksums for the files.

#### Using the command line interface

Open a Terminal, and use all features that Jacksum provides.

```
$ /Applications/Jacksum/jacksum
```

## Tech details

### How to create the .app and .dmg

#### Download and install Platypus

The .app will be created by the Platypus command line tool. Platypus is a great tool to wrap scripts to GUIs.
Go to https://sveinbjorn.org/platypus, download and open Platypus, select Preferences and install the command line tool.

#### Run the make_all.sh

Download the sources from the GitHub project, open a terminal and run
```
./bin/make_all.sh
```
That will build the .app and wrap it in a .dmg. You find the .dmg in the folder called ./output. 

### How does that all work?

The core of the .app is bash script that installs Jacksum's primary features to macOS Finder's Script Menu by creating applescript scripts and compiling those on the system during the installation. 

