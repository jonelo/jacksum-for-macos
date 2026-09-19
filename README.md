![GitHub downloads](https://img.shields.io/github/downloads/jonelo/jacksum-for-macos/total?color=green)

# Jacksum for macOS

<img width="696" height="440" alt="image" src="https://github.com/user-attachments/assets/3b9652b1-c98e-4fc9-abcd-7ffba716d915" />

## Abstract

Jacksum for macOS is an installation program that gives you easy access to the features of
[Jacksum](https://github.com/jonelo/jacksum) on macOS. In other words, it adds 586 algorithms
(crypto hash functions, CRCs and checksums) to your Mac, and it lets you use them from several
different user interfaces in order to calculate hash values, verify data integrity, and more. See the
[Jacksum](https://github.com/jonelo/jacksum) page for details.

The installation program installs

- [Jacksum](https://github.com/jonelo/jacksum), the hash engine, which also provides the command line interface (CLI)
- [HashGarten](https://github.com/jonelo/HashGarten), a standalone graphical user interface (GUI) for Jacksum
- script glue that calls Jacksum and HashGarten from your preferred file manager

See also the [Architecture](https://github.com/jonelo/jacksum/wiki/Architecture) of the interaction
between those components.

## Download

Download the latest [.dmg](https://github.com/jonelo/jacksum-for-macos/releases/latest).

## Installation

### 1. Open the .dmg

Open the [.dmg](https://github.com/jonelo/jacksum-for-macos/releases/latest).

### 2. Open the .app

#### For users of macOS Sequoia 15 and later

Since macOS Sequoia, an app from an unidentified developer no longer opens on a Control-click; macOS
reports that the app cannot be opened.

> [!TIP]
> To open such an app, try to open it once, then open "System Settings" and go to "Privacy &
> Security". Scroll down to the "Security" section, where you will find the option to open the app
> that was just blocked. Click "Open Anyway" and follow the prompts.
>
> If you prefer to allow apps from anywhere, open a Terminal and enter `sudo spctl --global-disable`
> (the older `spctl --master-disable` has been deprecated). An "Anywhere" option then appears in
> System Settings under "Privacy & Security" → "Allow applications from", which restores the
> behavior of Sonoma and earlier releases of macOS. Note that this lowers the security of your
> entire system, not just for this app, so consider re-enabling it afterwards.
>
> To verify the integrity of the app, compare its hash values with the ones published in the release
> notes of the respective release. To calculate hash values you can use a hash tool such as
> [Jacksum for macOS](https://github.com/jonelo/jacksum-for-macos).

#### For users of macOS Sonoma 14 and earlier

Control-click the app icon and choose "Open" from the shortcut menu. Gatekeeper warns you about the
app, but it also offers you the option to bypass its default policy and open the app anyway.

<img width="981" alt="Open the Jacksum for macOS app" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/846dc6b3-28ac-488d-a76d-a6e44eb68657">
<p><br/></p>

#### For users of the command line interface

> [!TIP]
> You can open a Terminal in order to bypass both the graphical installation program and the security
> warnings, and run the script that is bundled with the installer app directly. Example for
> Jacksum 4.0.0:
>
>```
>% cd /Volumes/Jacksum\ for\ macOS
>% ./Jacksum\ 4.0.0\ for\ macOS.app/Contents/Resources/script
>```

### 3. Check the results

At the end of the task, a summary tells you which file managers have been found and where Jacksum and
HashGarten have been integrated.

<img width="550" alt="After the installation" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/21a49953-3fa3-41a6-bfb4-21bd1e8ef0ef">


## System Requirements

### Hardware

- Intel Mac (x64) or Apple silicon (aarch64)
- 200 MiB of disk space (the installed HashGarten.app requires about 185 MiB, most of it the bundled Java runtime)

### Software

- macOS 11 (Big Sur) or later, tested up to macOS 15.7.7 (Sequoia) on x64 and macOS 26.6.2 on aarch64
- optional: a supported file manager (see below), so that you can call Jacksum and HashGarten from
  your file manager

#### Supported File Managers

**Finder**, which supports the Apple Script Menu, is fully supported by this integration program. In
addition, some file managers that provide proprietary interfaces are supported as well.

The installation program sets up the integration for **Finder**, **Path Finder**, **HoudahSpot**,
**Tembo**, **muCommander** and **Marta**. It also installs four **Quick Actions**, which show up in the
Services menu of many apps - but not of all of them, see the "Integration" column of the table below.
All other file managers in the table either work by drag & drop only, or require a few manual steps
that are documented in the wiki.

> [!TIP]
> If your preferred file manager supports neither the Apple Script Menu nor external scripts nor
> plug-ins, chances are high that it supports at least **drag & drop**. In that case you can drag
> file and directory paths from your file manager onto the HashGarten GUI and process them there, for
> example to calculate hash values.

The following file managers have been tested successfully with Jacksum and HashGarten:

| File Manager                                                                   | Integration                                         | Comment                                                                                                                |
|--------------------------------------------------------------------------------|-----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [Commander One](https://mac.eltima.com/file-manager.html)                      | Drag & drop + Services (partly)                     | Commercial Software, its Services menu hands over only the item currently selected, a multiple selection is ignored    |
| [CRAX Commander](https://crax.soft4u2.com)                                     | Drag & drop, no Services                            | Commercial Software (Demo)                                                                                             |
| [Dropover](https://dropoverapp.com/)                                           | Drag & drop, no Services                            | Commercial Software                                                                                                    |
| [EasyFind](https://www.devontechnologies.com/apps/freeware)                    | Drag & drop, no Services                            | Freeware, its Services menu offers the selection as a URL only, so the Quick Actions do not appear there               |
| [Fileside](https://www.fileside.app)                                           | Drag & drop + proprietary API (manual), no Services | Commercial Software (Trial), [a few extra steps required](https://github.com/jonelo/jacksum-for-macos/wiki/Fileside)   |
| [Finder](https://support.apple.com/guide/mac-help/mchlp2605/mac)               | Drag & drop + Script Menu (installer) + Services    | Bundled with macOS, the standard file manager from Apple                                                               |
| [ForkLift 4](https://binarynights.com/)                                        | Drag & drop + proprietary API (manual) + Services   | Commercial Software (Trial), [a few extra steps required](https://github.com/jonelo/jacksum-for-macos/wiki/ForkLift-4) |
| [HiFile](https://www.hifile.app/)                                              | Drag & drop, no Services                            | Commercial Software (Trial)                                                                                            |
| [HoudahSpot](https://www.houdah.com/houdahSpot/)                               | Drag & drop + Script Menu (installer) + Services    | Commercial Software (Trial), a search tool rather than a file browser                                                  |
| [Marta](https://marta.sh)                                                      | Drag & drop + plug-in (installer) + Services        | Freeware                                                                                                               |
| [muCommander](https://www.mucommander.com)                                     | Drag & drop + plug-in (installer), no Services      | Free/Libre Open Source Software (GPLv3)                                                                                |
| [Nimble Commander](https://magnumbytes.com)                                    | Drag & drop + Services                              | Free/Libre Open Source Software (GPLv3)                                                                                |
| [Path Finder](https://www.cocoatech.io)                                        | Drag & drop + Script Menu (installer) + Services    | Commercial Software                                                                                                    |
| [Tembo](https://www.houdah.com/tembo/)                                         | Drag & drop + Script Menu (installer) + Services    | Commercial Software (Trial), a search tool rather than a file browser                                                  |
| [Transmit](https://panic.com/transmit)                                         | Drag & drop + Services                              | Commercial Software (Trial)                                                                                            |
| [VioletGiraffe FileCommander](https://github.com/VioletGiraffe/file-commander) | Drag & drop                                         | Free/Libre Open Source Software (Apache 2.0)                                                                           |

"(installer)" means that the installation program creates the integration for you. "(manual)" means
that the file manager offers a suitable interface, but that you have to set it up yourself as
described on the linked wiki page. "Services" means that the four Quick Actions have been verified in
that file manager's Services menu and that they work without restrictions, that is with a multiple
selection of both files and directories. "Services (partly)" means that they do appear, but with the
restriction that is described in the Comment column. "no Services" means that the Quick Actions do
not appear in that file manager's Services menu at all. They are installed either way, so a file
manager without any of those three notes may still offer them - it just has not been verified yet.

## How to use it

### Using HashGarten

Open Spotlight Search and search for HashGarten, or go to Applications and open HashGarten from there.

<img width="558" alt="Spotlight Search" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/f57c53d2-8fad-41a3-8f65-229c838db8e3">

### Using Finder and the Script Menu

Go to Finder, select files and folders, and choose an action from the Jacksum script folder.

<img width="414" alt="Jacksum at the Finder script menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/d8d94614-c927-4f5e-97b6-18d4f3bb3e3b">

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.

### Using Path Finder and the Script Menu

Open Path Finder, select files and folders, and choose an action from the Jacksum script folder.

<img width="449" alt="Jacksum at the Path Finder script menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/a1c9467c-30ed-450b-846b-cfa2c03a9291">

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.

### Using HoudahSpot and the Script Menu

Open HoudahSpot, run a search, select results, and choose an action from the Jacksum script folder.

<img width="441" height="390" alt="image" src="https://github.com/user-attachments/assets/6efa4141-e16d-4c02-afa8-20dd9ad4446b" />

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.

> [!NOTE]
> HoudahSpot is a search tool, so its results usually live in many different folders. The integration
> prints the paths relative to the first selected entry, which in that case can produce paths such as
> `../../Documents/report.pdf`.

### Using Tembo and the Script Menu

Open Tembo, run a search, select results, and choose an action from the Jacksum script folder.

<!-- TODO: screenshot of the Jacksum script menu in Tembo -->

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.

> [!NOTE]
> Tembo is a search tool, so its results usually live in many different folders. The integration
> prints the paths relative to the first selected entry, which in that case can produce paths such as
> `../../Documents/report.pdf`.

### Using the Services menu (Quick Actions)

Unlike the integrations above, the four Quick Actions are not tied to a single app. Select files and
folders, right-click, and choose an action from the Services submenu. In the Finder they also appear
in the "Quick Actions" submenu of the context menu.

<!-- TODO: screenshot of the Jacksum Quick Actions in the Services menu -->

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.

> [!NOTE]
> An app only offers the Quick Actions if it hands its selection to the Services menu as files. Most
> apps do, the Finder and HoudahSpot for example. EasyFind does not: it offers its selection as a URL
> only, so you will not find the Jacksum items there. Use drag & drop with EasyFind instead.

> [!NOTE]
> Apps that were already running while you installed keep their cached Services menu. Restart such an
> app if its menu entries show up without the Jacksum icon, or without showing up at all.

> [!NOTE]
> The Quick Actions run under Automator rather than under HashGarten. The first time you call one for
> a file on your Desktop, in Documents or in Downloads, macOS can ask you to grant Automator access to
> that folder.

### Using muCommander

Open muCommander, select files and folders, right-click, and choose an action from the "Open with..."
menu.

<img width="578" alt="muCommander menu" src="https://github.com/jonelo/jacksum-for-macos/assets/10409423/2822f49f-7f26-40ab-ae57-233972aa81b1">

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.


### Using Marta

Open Marta, select files and folders, and go to Tools → Actions..., enter "Jacksum" in "Search Action"
and choose one of the entries.

![Jacksum actions in Marta](https://github.com/jonelo/jacksum-for-macos/assets/10409423/6efbe728-a5d5-4037-8120-cc791d7fae8a)

From here, [HashGarten](https://github.com/jonelo/HashGarten) takes over and you can calculate
checksums, CRCs and hash values of the selected files.


### Using the Command Line Interface (CLI)

Open a Terminal to get full access to the CLI. You can then use all the features that Jacksum
provides. The launcher is not added to your `$PATH`, so call it by its absolute path:

```
% /Applications/HashGarten.app/jacksum
```

For more information, see [Jacksum](https://github.com/jonelo/jacksum).

## How to configure it

### Finder

Open Finder, click the script menu, and select "Open Scripts Folder", followed by "Open Finder
Scripts Folder". Alternatively, press ⇧⌘G, enter the path to the Finder scripts folder
`~/Library/Scripts/Applications/Finder`, and click the "Go" button.

Open `Jacksum 4.0.0` and remove any .scpt file that you do not want to see.

### Path Finder

Open Path Finder, click the script menu, and select "Open Scripts Folder", followed by "Open Path
Finder Scripts Folder". Open `Jacksum 4.0.0` and remove any .scpt file that you do not want to see.

### HoudahSpot

Press ⇧⌘G in Finder, enter the path to the HoudahSpot scripts folder
`~/Library/Scripts/Applications/HoudahSpot`, and click the "Go" button. Open `Jacksum 4.0.0` and
remove any .scpt file that you do not want to see.

### Tembo

Press ⇧⌘G in Finder, enter the path to the Tembo scripts folder
`~/Library/Scripts/Applications/Tembo`, and click the "Go" button. Open `Jacksum 4.0.0` and remove
any .scpt file that you do not want to see.

### Quick Actions

There are two ways to get rid of single entries or of the whole Services integration.

**Switch them off, without removing anything.** Open System Settings → Keyboard → "Keyboard
Shortcuts…" → Services, and untick the four entries that start with "Jacksum - ". macOS keeps that
choice in `~/Library/Preferences/pbs.plist`, not in the bundles, so it is not affected by what the
installation program writes. This is the better option if you only want a quieter menu.

**Remove them.** The Quick Actions are ordinary bundles in `~/Library/Services`, named
`Jacksum - <action>.workflow`. Delete the ones you do not want, or open one with Automator to modify
it:

```
% rm -rf ~/Library/Services/Jacksum\ -\ 4\)\ Edit\ script.workflow
% /System/Library/CoreServices/pbs -flush
```

The `pbs -flush` makes the change visible without a logout. Note that the next run of the
installation program recreates every bundle, including the ones you deleted.

### muCommander

The commands for muCommander are defined in `/Applications/HashGarten.app/mucommander.commands.xml`.
Modify that file to match your needs.

> [!IMPORTANT]
> `~/Library/Preferences/muCommander/commands.xml` is only a symbolic link to that file inside the app
> bundle, so any changes you make there are lost the next time you run the installation program. To
> keep your own commands permanently, replace the symbolic link with a regular file:
>
>```
>% cd ~/Library/Preferences/muCommander
>% cp commands.xml commands.xml.mine && mv commands.xml.mine commands.xml
>```

### How to recreate all items again

Just run the `Jacksum for macOS.app` again. Note that this also recreates the muCommander commands
file, which discards any changes you made to it.

## How to uninstall it

### Jacksum and HashGarten

Regardless of which file managers were integrated, remove the app itself. This also removes the CLI
launcher, the bundled Java runtime and the muCommander commands file:

```
% rm -rf /Applications/HashGarten.app
```

### Finder

Since Finder is always found during the installation, type

```
% rm -rf ~/Library/Scripts/Applications/Finder/Jacksum*
```

### Path Finder

If Path Finder was found during the installation, type

```
% rm -rf ~/Library/Scripts/Applications/Path\ Finder/Jacksum*
```

### HoudahSpot

If HoudahSpot was found during the installation, type

```
% rm -rf ~/Library/Scripts/Applications/HoudahSpot/Jacksum*
```

### Tembo

If Tembo was found during the installation, type

```
% rm -rf ~/Library/Scripts/Applications/Tembo/Jacksum*
```

### muCommander

If muCommander was found during the installation, remove the symbolic link that the installation
program created:

```
% rm ~/Library/Preferences/muCommander/commands.xml
```

If you already had a `commands.xml` before, the installation program moved it aside as
`commands.xml.before_jacksum.<date>`. In that case, restore it:

```
% cp ~/Library/Preferences/muCommander/commands.xml.before_jacksum.* ~/Library/Preferences/muCommander/commands.xml
% rm ~/Library/Preferences/muCommander/commands.xml.before_jacksum.*
```

### Marta

If Marta was found during the installation, type

```
% cd ~/Library/Application\ Support/org.yanex.marta/Plugins/
% rm $(grep -il jacksum *.lua | xargs)
```

Note that `grep` searches the contents of the plug-ins, so review the list first if you have other
plug-ins that happen to mention Jacksum.

### Quick Actions

The Quick Actions are always installed, no matter which file managers were found. Remove all four of
them and update the Services cache:

```
% rm -rf ~/Library/Services/Jacksum\ -\ *.workflow
% /System/Library/CoreServices/pbs -flush
```

That is all there is to it: each bundle is self contained, so nothing is left behind anywhere else.

> [!NOTE]
> An app that is running while you remove the bundles keeps its Services menu until you restart it,
> the Finder included. If an entry is still listed, quit and reopen that app. If you would rather
> keep the Quick Actions but not see them, untick them in System Settings instead, as described
> under [How to configure it](#quick-actions).

## For Developers

Go to https://github.com/jonelo/jacksum-for-macos/wiki/Developer-Notes

## Further Information

- [https://jacksum.net](https://jacksum.net)
- https://github.com/jonelo/jacksum
- https://github.com/jonelo/jacksum/wiki/Architecture

## Show your support

Please ⭐️ [this repository](https://github.com/jonelo/jacksum-for-macos) if this project helped you!
