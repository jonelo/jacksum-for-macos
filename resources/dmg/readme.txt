What is the purpose of this app?
--------------------------------
The installer called "Jacksum Finder Integration" installs Jacksum's primary
features to the macOS Finder's Script Menu.

For more information about Jacksum please go to https://jacksum.net


How do I install the "Jacksum Finder Integration"?
--------------------------------------------------
In order to install Jacksum's primary features to Finder,
just double click on the icon to run the installer.

The installer requires Mac OS X 10.8 (Mountain Lion) or later.
It has been tested up to macOS 11.1 (Big Sur).

The first time you do run the installer you may need to override
your GateKeeper settings. See also https://support.apple.com/en-us/HT202491

Alternatively, you can control-click on the app icon, and choose Open from the
shortcut menu. This time, Gatekeeper warns you about the app, but gives you the
option to bypass its default policy and open the app.

Alternatively, you can bypass the installer and run the script directly that
is bundled in the installer:

$ cd /Volumes/Jacksum\ Finder\ Integration
$ ./Jacksum\ Finder\ Integration.app/Contents/Resources/script

The script itself requires Mac OS X 10.4 (Tiger) or later.
It has been tested up to macOS 11.1 (Big Sur).
The script does not require admin priviledges.

Credits: the installer app has been created by Platypus,
a great app to wrap scripts into an app, see also https://sveinbjorn.org/platypus


How to calculate a CRC/checksum/hash value using Jacksum?
---------------------------------------------------------
After you have installed Jacksum by the Jacksum Finder Integration, you can
go to Finder, select one or more files, one or more folders and choose an
algorithm from the script folder called Jacksum in order to calculate checksums
for the files.

Alternatively, you can also do it on the commandline. Jacksum is installed in
/Applications/Jacksum by the installer and you can call jacksum on the command 
line by typing

$ /Applications/Jacksum/jacksum


What else do I need to know?
----------------------------
Jacksum requires Java to run, so you have to install a JDK. You can get it
for free for example at https://adoptium.net (recommended) or http://jdk.java.net/

Also please make sure that you have activated the Apple Script Menu.
The Script Menu preferences are at the Apple Script-Editor's preferences,
in the General tab.

See also https://support.apple.com/en-tm/guide/script-editor/scpedt27975/mac


How to remove the integration of Jacksum again?
-----------------------------------------------
Remove the folder that contains all the .scpt files. It is either
$HOME/Library/Scripts/Applications/Finder/Jacksum
or /Library/Scripts/Finder Scripts/Jacksum
it depends on the priviledge that you used to launch the installer.

Also remove the folder called /Applications/Jacksum


Where is the sourcecode of the installer script?
------------------------------------------------
$ cd /Volumes/Jacksum\ Finder\ Integration
$ cat ./Jacksum\ Finder\ Integration.app/Contents/Resources/script


Where are the sourcecodes of the Jacksum Finder scripts?
--------------------------------------------------------
The installer generates the source code for the scripts and compiles those.
You can open the .scpt files (located in your script folder) using the
Apple Script Editor or osadecompile.

