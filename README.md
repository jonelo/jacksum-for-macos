![GitHub downloads](https://img.shields.io/github/downloads/jonelo/jacksum-for-macos/total?color=green)

# Jacksum for macOS

![Jacksum for macOS app](https://github.com/user-attachments/assets/82426e6a-966f-4993-a8e6-0d0c6c230933)

## Abstract

Jacksum for macOS is an installation program with which you can easily access functions of [Jacksum](https://github.com/jonelo/jacksum) on macOS.
In other words, it adds more than 480 hash algorithms to your Mac and you can use them with different user interfaces to calculate hash values, verify data integrity, and many more. See the [Jacksum](https://github.com/jonelo/jacksum) page for more info.

The installation program installs

- [Jacksum](https://github.com/jonelo/jacksum) which is the hash engine, it also provides the command line interface (CLI)
- [HashGarten](https://github.com/jonelo/HashGarten) which is a standalone graphical user interface (GUI) for Jacksum
- script glue to call Jacksum and HashGarten from your preferred file manager

See also the [Architeture](https://github.com/jonelo/jacksum/wiki/Architecture) of interaction between those components.

## Download

Download the latest [.dmg](https://github.com/jonelo/jacksum-for-macos/releases/latest).

## Installation

### 1. Open the .dmg

Open the [.dmg](https://github.com/jonelo/jacksum-for-macos/releases/latest).

### 2. Open on the .app

#### For users of macOS Sequoia 15 and later

With the release of macOS Sequoia, any app from an unidentified developer gives an error that the app is not opened. To open any of such apps, open "System Settings", and go to the "Privacy & Security" tab. On the "Privacy & Security" page, scroll down to last. Under the Security section, you have the option to open the application that was previously blocked. Click on the "Open Anyway" button to open it, and proceed with the prompts. Your app will be opened.

To allow open apps on macOS from anywhere, open a Terminal and enter `sudo spctl --master-disable`. In the Security section, under "Allow applications from", there is a new menu item called "Anywhere."

#### For users of macOS Sonoma 14 and earlier

Control-click on the app icon, and choose Open from the shortcut menu. Gatekeeper warns you about the app, but gives you the option to bypass its default policy and open the app.

<img width="981" alt="Open the Jacksum for macOS app" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/846dc6b3-28ac-488d-a76d-a6e44eb68657">
<p><br/></p>

#### For the command line interface lover

You can open a Terminal to bypass both the graphical installation program and security warnings and run the script directly that is bundled with the installer app. Example for Jacksum 3.7.0:

```
% cd /Volumes/Jacksum\ for\ macOS
% ./Jacksum\ 3.7.0\ for\ macOS.app/Contents/Resources/script
```

### 3. Check results

At the end of the task a summary will tell you what file managers have been found and where Jacksum and HashGarten have been integrated.

<img width="550" alt="After the installation" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/21a49953-3fa3-41a6-bfb4-21bd1e8ef0ef">


## System Requirements

### Hardware

- Intel Mac (x64) or Apple silicon (aarch64)
- 150 MiB disk space

### Software

- macOS 10.11 (El Capitan) or later, tested up to macOS 15.1.1 (Sequoia)
- optional: a supported file manager (see below) to call Jacksum and HashGarten from your flie manager

#### Supported File Managers

**Finder** which supports the Apple Script Menu is fully supported by this integration program. In adddition to that, some file managers providing proprietary interfaces are also supported.

> [!TIP]
> If your preferred file manager does not support the Apple Script Menu, nor allow to use any external scripts nor support any plug-ins, chances are high that your file manager supports at least **drag & drop**, so you could use drag & drop to transfer file/directory-paths from your file manager to the HashGarten GUI where you can process data further, e. g. calculate hashes from file/directory-paths.

The following File Managers have been tested successfully to work with Jacksum and HashGarten:

| File Manager                                                                   | Supported Interfaces  | Comment                                                       |
|--------------------------------------------------------------------------------|-----------------------|---------------------------------------------------------------|
| [CRAX Commander](https://crax.soft4u2.com)                                     | DnD                   | Commercial Software (Demo)                                    |
| [Commander One](https://mac.eltima.com/file-manager.html)                      | DnD                   | Commercial Software                                           |
| [Dropover](https://dropoverapp.com/)                                           | DnD                   | Commercial Software                                           |
| [EasyFind](https://www.devontechnologies.com/en/apps/freeware)                 | DnD                   | Freeware                                                      |
| [Finder](https://support.apple.com/guide/mac-help/mchlp2605/mac)               | DnD + Script Menu     | Commercial Software, the standard file manager from Apple     |
| [Fileside](https://www.fileside.app)                                           | DnD + proprietary API | Commercial Software (Trial), [few extra actions required](https://github.com/jonelo/jacksum-for-macos/wiki/Fileside)     |
| [Forklift 4](https://binarynights.com/)                                        | DnD + proprietary API | Commercial Software (Trial), [few extra actions required](https://github.com/jonelo/jacksum-for-macos/wiki/ForkLift-4) |
| [HiFile](https://www.hifile.app/)                                              | DnD                   | Commercial Software (Trial)                                   |
| [Marta](https://marta.sh)                                                      | DnD + proprietary API | Freeware                                                      |
| [muCommander](https://www.mucommander.com)                                     | DnD + proprietary API | Free/Libre Open Source Software (GPLv3)                       |
| [Nimble Commander](https://magnumbytes.com)                                    | DnD                   | Free/Libre Open Source Software (GPLv3)                       |
| [Path Finder](https://www.cocoatech.io)                                        | DnD + Script Menu     | Commercial Software                                           |
| [Transmit](https://panic.com/transmit)                                         | DnD                   | Commercial Software (Trial)                                   |
| [VioletGiraffe FileCommander](https://github.com/VioletGiraffe/file-commander) | DnD                   | Free/Libre Open Source Software (Apache 2.0)                  |


#### Not Yet Supported FLOSS File Managers

The following file managers do not support DnD nor allow calling external scripts.

| File Manager                                                                   | Comment                                                       |
|--------------------------------------------------------------------------------|---------------------------------------------------------------|
| [Spacedrive Alpha v0.4.2](https://www.spacedrive.com)                          | Free/Libre Open Source Software (AGPL 3.0)                    |



## How to use it

### Using HashGarten

Open the Spotlight Search and search for HashGarten or go to Applications and open HashGarten.

<img width="558" alt="Spotlight Search" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/f57c53d2-8fad-41a3-8f65-229c838db8e3">

### Using Finder and the Script Menu

Go to Finder, select files and folders and choose an action from the Jacksum script folder.

<img width="414" alt="Jacksum at the Finder script menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/d8d94614-c927-4f5e-97b6-18d4f3bb3e3b">

From here [HashGarten](https://github.com/jonelo/HashGarten) takes over, and you can calculate checksums, CRCs and hash values of the selected files.

### Using Path Finder and the Script Menu

Open Path Finder, select files and folders and choose an action from the Jacksum script folder.

<img width="449" alt="Jacksum at the Path Finder script menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/a1c9467c-30ed-450b-846b-cfa2c03a9291">

From here [HashGarten](https://github.com/jonelo/HashGarten) takes over, and you can calculate checksums, CRCs and hash values of the selected files.

### Using muCommander

Open muCommandere, select files and folders, right click and choose an action from the "Open with..." menu.

<img width="578" alt="muCommander menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/2822f49f-7f26-40ab-ae57-233972aa81b1">

From here [HashGarten](https://github.com/jonelo/HashGarten) takes over, and you can calculate checksums, CRCs and hash values of the selected files.


### Using Marta

Open Marta, select files and folders, select Tools -> Actions... -> Enter "Jacksum" in Search Action and choose one of the entries.

![Bildschirmfoto 2024-05-23 um 21 36 38](https://github.com/jonelo/jacksum-for-macos/assets/10409423/6efbe728-a5d5-4037-8120-cc791d7fae8a)

From here [HashGarten](https://github.com/jonelo/HashGarten) takes over, and you can calculate checksums, CRCs and hash values of the selected files.


### Using the Command Line Interface (CLI)

Open a Terminal to get full access to the CLI. Now you can use all features that Jacksum provides.

```
% /Applications/HashGarten.app/jacksum
```

For more information see also [Jacksum](https://github.com/jonelo/jacksum)

## How to configure it

### Finder

Open Finder, click on the script menu, and select "Open Scripts Folder", followed by "Open Finder Scripts Folder".
Alternatively hit ⇧⌘G, enter the path to the Finder scripts folder `~/Library/Scripts/Applications/Finder`, and click on the Go button.

Click on `Jacksum 3.7.0`, and remove any .scpt file that you do not want to see.

### Path Finder

Open Path Finder, click on the script menu, and select "Open Scripts Folder", followed by "Open Path Finder Scripts Folder".
Click on `Jacksum 3.7.0`, and remove any .scpt file that you do not want to see.

### muCommander

Modify the content of `~/Library/Preferences/muCommander/commands.xml` to match your needs.

### How to recreate all items again

Just run the `Jacksum for macOS.app` again.

## How to uninstall it

### Finder

Since Finder will always be found during installation, type
```
% rm -rf /Applications/HashGarten.app
% rm -rf ~/Library/Scripts/Applications/Finder/Jacksum*
```

### Path Finder

If Path Finder was found during installation, type
```
% rm -rf ~/Library/Scripts/Applications/Path\ Finder/Jacksum*
```

### muCommander

If muCommander was found during installation, type
```
% rm ~/Library/Preferences/muCommander/commands.xml
% cp ~/Library/Preferences/muCommander/commands.xml.before_jacksum.* ~/Library/Preferences/muCommander/commands.xml
% rm ~/Library/Preferences/muCommander/commands.xml.before_jacksum.*
```

### Marta

If Marta was found during installation, type
```
% cd ~/Library/Application\ Support/org.yanex.marta/Plugins/
% rm $(grep -il jacksum *.lua | xargs)
```


## Further Information

- [https://jacksum.net](https://jacksum.net)
- https://github.com/jonelo/jacksum
- https://github.com/jonelo/jacksum/wiki/Architecture

## Show your support

Please ⭐️ [this repository](https://github.com/jonelo/jacksum-for-macos) if this project helped you!
