#!/bin/bash
# 
#  Jacksum File Browser Integration for macOS
#  Copyright (c) 2010-2026 Dipl.-Inf. (FH) Johann N. Loefflmann
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

PATH="/sbin:/usr/sbin:/bin:/usr/bin"
JACKSUM_VERSION=4.0.0


#---------------------------------------------------------------
function applescript_for_Finder {
#---------------------------------------------------------------
  echo -n 'tell application "Finder"
	set theseItems to the selection
end tell

set allFiles to ""
repeat with fileItem in theseItems
	set thisItem to fileItem as alias
	set thisFile to POSIX path of thisItem
	set thisFileQuoted to quoted form of thisFile
	set allFiles to allFiles & " " & thisFileQuoted
end repeat

' >> "${APPLE_SCRIPT}"
}


#---------------------------------------------------------------
function applescript_for_PathFinder {
#---------------------------------------------------------------
echo -n 'tell application "Path Finder"

	set allFiles to ""
	repeat with fileItem in (get selection)
		set thisFile to POSIX path of fileItem
		set thisFileQuoted to quoted form of thisFile
		set allFiles to allFiles & " " & thisFileQuoted
	end repeat
end tell

' >> "${APPLE_SCRIPT}"
}


#---------------------------------------------------------------
function applescript_for_HoudahSpot {
#---------------------------------------------------------------
echo -n 'tell application "HoudahSpot"

	set allFiles to ""
	set theSelection to (get selection)
	if theSelection is not missing value then
		repeat with resultItem in theSelection
			set thisFile to path of resultItem
			set thisFileQuoted to quoted form of thisFile
			set allFiles to allFiles & " " & thisFileQuoted
		end repeat
	end if
end tell

' >> "${APPLE_SCRIPT}"
}


#---------------------------------------------------------------
function applescript_for_Tembo {
#---------------------------------------------------------------
# Tembo is scriptable like HoudahSpot, but its dictionary puts
# "selection" on the document rather than on the application,
# so the app level "get selection" of HoudahSpot does not exist here.
echo -n 'tell application "Tembo"

	set allFiles to ""
	if (count of documents) > 0 then
		-- the selection has to go into a variable first, because
		-- "repeat with x in (selection of document 1)" iterates by
		-- reference and asks Tembo to resolve "item 1 of selection
		-- of document 1", which it cannot (error -1700)
		set theSelection to (get selection of document 1)
		repeat with resultItem in theSelection
			set thisFile to path of resultItem
			set thisFileQuoted to quoted form of thisFile
			set allFiles to allFiles & " " & thisFileQuoted
		end repeat
	end if
end tell

' >> "${APPLE_SCRIPT}"
}


#---------------------------------------------------------------
function update_progress_bar {
#---------------------------------------------------------------
  FINISHED=$[$FINISHED+$1]
  PERCENT=$[$FINISHED*100/$TOTAL_COUNT]
  printf "PROGRESS:%i\n" $PERCENT
}


#---------------------------------------------------------------
function setup_muCommander {
#---------------------------------------------------------------
DIR="$APP_DIR/Contents/MacOS/bin"
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<commands>
  <command alias="Jacksum - 1) Calc Hash Values" value="'"${DIR}"'/jacksum.sh cmd_calc $f" />
  <command alias="Jacksum - 2) Check Data Integrity" value="'"${DIR}"'/jacksum.sh cmd_check $f" />
  <command alias="Jacksum - 3) Customized Output" value="'"${DIR}"'/jacksum.sh cmd_cust $f" />
  <command alias="Jacksum - 4) Edit Script" value="'"${DIR}"'/jacksum.sh cmd_edit $f" />
</commands>' > ${APP_DIR}/mucommander.commands.xml

  COMMANDS_XML="$HOME/Library/Preferences/muCommander/commands.xml"

  if [ -e "$COMMANDS_XML" ]; then
    DATE=$(date +"%Y-%m-%d_%H-%M")
    COMMANDS_XML_BACKUP="${COMMANDS_XML}.before_jacksum.${DATE}"
    mv "$COMMANDS_XML" "$COMMANDS_XML_BACKUP"
    printf "Warning: %s existed, created backup as %s.\n" "$COMMANDS_XML" "$COMMANDS_XML_BACKUP"
  fi

  if [ ! -e "$COMMANDS_XML" ]; then
    ln -s "${APP_DIR}/mucommander.commands.xml" "$COMMANDS_XML"
  fi

  update_progress_bar 4
}


#---------------------------------------------------------------
function setup_marta {
#---------------------------------------------------------------

CMDS=("calc" "check" "cust" "edit")
ACTIONS=("Calc Hash Values" "Check Data Integrity" "Customized Output" "Edit Script")
PLUGINS_DIR="$HOME/Library/Application Support/org.yanex.marta/Plugins/"
mkdir -p "$PLUGINS_DIR"

index=0
for action in "${ACTIONS[@]}"
do
    action_nospaces=${action// /}
    plugin_file="$PLUGINS_DIR/${action_nospaces}.lua"

echo -n 'plugin {
    id = "net.jacksum.Jacksum'"${action_nospaces}"'Plugin",
    name = "Jacksum '"${action}"'",
    apiVersion = "2.1",

    author = "Johann N. Löfflmann",
    email = "johann@loefflmannn.net",
    url = "https://jacksum.net/"
}

action {
    id = "net.jacksum.Jacksum'"${action_nospaces}"'Action",
    name = "'"${action}"' [Jacksum]",

    isApplicable = function(context)
        return context.activePane.model.hasActiveFiles
    end,

    apply = function(context)
        local files = context.activePane.model.activeFiles
        local array = {}
        for i, file in ipairs(files) do
           array[i] = file.path
        end
        table.insert(array, 1, "cmd_'"${CMDS[index]}"'")
        martax.execute("/Applications/HashGarten.app/Contents/MacOS/bin/jacksum.sh", array)
    end
}
' > "${plugin_file}"

  chmod +x "${plugin_file}"
  index=$[$index+1]

done

  update_progress_bar 4
}


#---------------------------------------------------------------
function setup_quick_actions {
#---------------------------------------------------------------
# An Automator Quick Action (.workflow) per command. Unlike every
# other integration this one is not bound to a single app: it shows
# up in the Services menu of every app that puts a file selection on
# the pasteboard, the Finder and HoudahSpot for example. It is
# therefore always installed.
#
# Note that EasyFind, which was the reason to look into Services in
# the first place, is NOT among those apps: it offers its selection
# as public.url only, so a public.item service never matches there.

SERVICES_DIR="$HOME/Library/Services"
mkdir -p "$SERVICES_DIR"

# the bundles are fully generated, there is nothing to preserve
rm -rf "$SERVICES_DIR/Jacksum - "*.workflow

for i in $COMMANDS
do
  CMD="${i%;*}"; TXT="${i#*;}"; TXT="${TXT//_/ }"

  # the / is for folders, so we have to adjust the filename for e.g. SHA512/224
  NAME="Jacksum - ${TXT//\//-}"
  WORKFLOW_DIR="${SERVICES_DIR}/${NAME}.workflow/Contents"
  mkdir -p "$WORKFLOW_DIR"

  printf "Installing Quick Action %s ...\n" "$TXT"

  # NSSendFileTypes is not optional: without it the menu item does show up,
  # but the service is called without any data and macOS responds with
  # "An error occurred while sending data to the service".
  cat << EOL > "${WORKFLOW_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>${NAME}</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.item</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOL

  cat << EOL > "${WORKFLOW_DIR}/document.wflow"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>534</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>"${APP_DIR}/Contents/MacOS/bin/jacksum.sh" ${CMD} "\$@"</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>$(uuidgen)</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>$(uuidgen)</string>
				<key>UUID</key>
				<string>$(uuidgen)</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>conversionLabel</key>
				<integer>0</integer>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>309.000000:305.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleIDsByPath</key>
		<dict/>
		<key>applicationPaths</key>
		<array/>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>15</integer>
		<key>processesInput</key>
		<false/>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<false/>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<false/>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
EOL

  # The Services menu draws the icon of the bundle that provides the service.
  # For a .workflow that is neither CFBundleIconFile nor NSIconName - both are
  # ignored, the Automator document icon wins - so the only way to get the
  # Jacksum icon into the menu is a Finder custom icon on the bundle itself.
  # NSWorkspace writes one without any developer tools being installed.
  osascript -l JavaScript \
    -e 'ObjC.import("AppKit"); function run(a) { var i = $.NSImage.alloc.initWithContentsOfFile(a[0]); if (i.isNil()) { return false } return $.NSWorkspace.sharedWorkspace.setIconForFileOptions(i, a[1], 0) }' \
    "$APP_DIR/Contents/Resources/Jacksum.icns" "${SERVICES_DIR}/${NAME}.workflow" > /dev/null 2>&1

  update_progress_bar 1

done

  # register the Quick Actions without a logout
  /System/Library/CoreServices/pbs -flush 2> /dev/null || true
}


#---------------------------------------------------------------
function enableAppleScriptMenu {
#---------------------------------------------------------------
cat << EOL
The script menu in the menu bar needs to be
visible, so that you can access menu items.

Please allow the "AppleScript Utility.app" to do the change for you.

Waiting ...
EOL

  # Starting with Mac OS X 10.6 (Snow Lopard), the Script Menu
  # preferences are at the Apple Script-Editor's preferences,
  # in the General tab.
  osascript <<EndOfScript
  tell application "AppleScript Utility"
    set Script menu enabled to true
    set show Computer scripts to true
    set application scripts position to bottom
  end tell
EndOfScript
  APPLE_SCRIPT_ERROR=$?

  if [ $APPLE_SCRIPT_ERROR -eq 0 ]; then
    printf "\nThe Apple Script Menu has been enabled.\n"
  else
cat << EOL

WARNING: the Apple Script Menu has NOT been
enabled.

If you want to select the menu items you have to
enable the Apple Script Menu!
EOL

  printf "ALERT:Message|You didn't allow me to do the modification for you. Manual action required or rerun the script.\n"
  tccutil reset AppleEvents
  fi

}


#---------------------------------------------------------------
function enableOrDisableFileManagers {
#---------------------------------------------------------------
  # Path Finder 
  if [ -f "/Applications/Path Finder.app/Contents/MacOS/Path Finder" ]; then
    PATH_FINDER=1
    TOTAL_COUNT=$[$TOTAL_COUNT+$COMMANDS_COUNT]
  else
    PATH_FINDER=0 
  fi

  # muCommander
  if [ -d "/Applications/muCommander.app" ]; then
    MUCOMMANDER=1
    TOTAL_COUNT=$[$TOTAL_COUNT+$COMMANDS_COUNT]
  else
    MUCOMMANDER=0
  fi

  # Marta
  if [ -d "/Applications/Marta.app" ]; then
    MARTA=1
    TOTAL_COUNT=$[$TOTAL_COUNT+$COMMANDS_COUNT]
  else
    MARTA=0
  fi

  # HoudahSpot
  if [ -d "/Applications/HoudahSpot.app" ]; then
    HOUDAHSPOT=1
    TOTAL_COUNT=$[$TOTAL_COUNT+$COMMANDS_COUNT]
  else
    HOUDAHSPOT=0
  fi

  # Tembo
  if [ -d "/Applications/Tembo.app" ]; then
    TEMBO=1
    TOTAL_COUNT=$[$TOTAL_COUNT+$COMMANDS_COUNT]
  else
    TEMBO=0
  fi
} 


#---------------------------------------------------------------
function initGlobalVars {
#---------------------------------------------------------------
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  APP_DIR=/Applications/HashGarten.app
  COMMANDS="cmd_calc;1)_Calc_hash_values cmd_check;2)_Check_data_integrity cmd_cust;3)_Customized_output cmd_edit;4)_Edit_script"
  COMMANDS_COUNT=($COMMANDS)
  COMMANDS_COUNT=${#COMMANDS_COUNT[@]}
  # the Finder script menu and the Quick Actions are always installed
  TOTAL_COUNT=$[$COMMANDS_COUNT+$COMMANDS_COUNT]
  FINISHED=0
  enableOrDisableFileManagers
}


#---------------------------------------------------------------
function createJavaLauncher {
#---------------------------------------------------------------
  JAVALAUNCHER="$APP_DIR/javalauncher"
  echo "Creating $JAVALAUNCHER ..."
  cat << "EOL" > "$JAVALAUNCHER"
#!/bin/bash
if [[ ! -z $JAVA_HOME ]]; then
    JEXEC=$JAVA_HOME/bin/java
else
    LIBEXEC=$(/usr/libexec/java_home 2> /dev/null | head -1)
    # is there a JDK?
    if [[ ! -z $LIBEXEC ]]; then
        JEXEC="$LIBEXEC/bin/java"
    else
       # is there a JRE?
       JRE=/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java
       if [[ -f "$JRE" ]]; then
           JEXEC="$JRE"
       else
           JEXEC=java
       fi
    fi
fi
"$JEXEC" "$@"
EOL

  chmod +x "$JAVALAUNCHER"
}


#---------------------------------------------------------------
function createJacksumLauncher {
#---------------------------------------------------------------
  LAUNCHER="$APP_DIR/jacksum"
  echo "Creating $LAUNCHER ..."
  cat << "EOL" > "$LAUNCHER"
#!/bin/bash
/Applications/HashGarten.app/Contents/Java/jre_latest/Contents/Home/bin/java -jar "/Applications/HashGarten.app/Contents/MacOS/lib/jacksum-4.0.0.jar" "$@"
EOL

  chmod +x "$LAUNCHER"
}


#---------------------------------------------------------------
function copyFiles {
#---------------------------------------------------------------
  mkdir -p "$APP_DIR"

  echo "Copying license.txt ..."
  cp "$SCRIPT_DIR/license.txt" "$APP_DIR"

  # createJavaLauncher
  createJacksumLauncher 
}


#---------------------------------------------------------------
function setup {
#---------------------------------------------------------------
  FM="$1"
  printf "Installing menu entries for %s\n" "$FM"

  if [ "$(id | cut -c5)" -ne 0 ]; then
    SCRIPTS="${HOME}/Library/Scripts/Applications/${FM}/Jacksum ${JACKSUM_VERSION}"
  else
    SCRIPTS="/Library/Scripts/${FM} Scripts/Jacksum ${JACKSUM_VERSION}"
  fi
  mkdir -p "$SCRIPTS"
  #ALGORITHMS="$(${APP_DIR}/jacksum -a all --list)"

  for i in $COMMANDS
  do
    CMD="${i%;*}"; TXT="${i#*;}"; TXT="${TXT//_/ }"

    # the / is for folders, so we have to adjust the filename for e.g. SHA512/224
    SCRIPT_NAME="${TXT//\//-}"
    APPLE_SCRIPT="/tmp/${SCRIPT_NAME}.applescript"
    COMPILED_SCRIPT="${SCRIPTS}/${SCRIPT_NAME}.scpt"
    # Creating ${APPLE_SCRIPT}
    # Make copyright header compatible with old AppleScript versions 1.x
    echo '(*' > "${APPLE_SCRIPT}"
    head -n19 "$0" | tail -n18 | tr '#' ' ' >> "${APPLE_SCRIPT}"
    echo '*)' >> "${APPLE_SCRIPT}"

    METHOD_NAME="${FM// /}"
    applescript_for_${METHOD_NAME}

    printf "set theCommand to \"%s %s \" & allFiles\n" "${APP_DIR}/Contents/MacOS/bin/jacksum.sh" "$CMD" >> "${APPLE_SCRIPT}"
    printf "do shell script theCommand\n" >> "${APPLE_SCRIPT}"

    # Compiling to .applescript to .scpt
    printf "Installing menu %s ...\n" "$TXT"
    osacompile -d -o "${COMPILED_SCRIPT}" "${APPLE_SCRIPT}"

    # Clean up
    rm "${APPLE_SCRIPT}"

    update_progress_bar 1

  done
}


#---------------------------------------------------------------
function finish {
#---------------------------------------------------------------

cat << EOL

Both Jacksum and HashGarten have been installed.
They have also been set up for the following
file managers:

EOL

  printf "  - Finder\n"
  if [ $PATH_FINDER -eq 1 ]; then
    printf "  - Path Finder\n"
  fi
  if [ $MUCOMMANDER -eq 1 ]; then
    printf "  - muCommander\n"
  fi
  if [ $MARTA -eq 1 ]; then
    printf "  - Marta\n"
  fi
  if [ $HOUDAHSPOT -eq 1 ]; then
    printf "  - HoudahSpot\n"
  fi
  if [ $TEMBO -eq 1 ]; then
    printf "  - Tembo\n"
  fi

cat << EOL

Four Quick Actions have been installed as well. You
find them in the Services menu of every app that
offers a file selection there, such as the Finder
and HoudahSpot.

Please refer to the readme.pdf to see
how you can use it with your file manager.
EOL

  if [ $APPLE_SCRIPT_ERROR -eq 0 ]; then
    printf "\nDone.\n"
  else
    printf "\nDone with errors. See above.\n"
  fi
}


#---------------------------------------------------------------
function setupAllFileManagers {
#---------------------------------------------------------------
  setup "Finder"
  setup_quick_actions

  if [ $PATH_FINDER -eq 1 ]; then
      setup "Path Finder"
  fi

  if [ $MUCOMMANDER -eq 1 ]; then
      setup_muCommander
  fi

  if [ $MARTA -eq 1 ]; then
      setup_marta
  fi

  if [ $HOUDAHSPOT -eq 1 ]; then
      setup "HoudahSpot"
  fi

  if [ $TEMBO -eq 1 ]; then
      setup "Tembo"
  fi
}


#---------------------------------------------------------------
function copyHashGarten {
#---------------------------------------------------------------
  FOLDER="/Applications/HashGarten.app"
  # remove HashGarten if it is installed already
  [ -d "$FOLDER" ] && rm -Rf "$FOLDER"
  # copy all HashGarten files
  cp -R "${SCRIPT_DIR}/HashGarten.app" "$FOLDER"
}


#---------------------------------------------------------------
function setupJava {
#---------------------------------------------------------------
  TARGET="/Applications/HashGarten.app/Contents/Java"
  mkdir -p $TARGET

  # Extract the correct JRE, dependent on the arch of the system
  ARCH=$(uname -m)
  printf "Copying JRE for arch %s to %s ..." "$ARCH" "$TARGET"
  if [ $ARCH = "x86_64" ]; then
    tar -xvf "${SCRIPT_DIR}"/*x64*.tar.gz -C "$TARGET" 2>/dev/null
  elif [ $ARCH = "arm64" ]; then
    tar -xvf "${SCRIPT_DIR}"/*aarch64*.tar.gz -C "$TARGET" 2>/dev/null
  else
    printf "ERROR: no suitable JRE found for arch %s." "$ARCH"
  fi
  if [ $? -eq 0 ]; then
    printf "done.\n"
  else
    printf "ERROR.\n"
  fi

  printf "Creating a symlink to the JRE ...\n"
  # What is the name of the JRE?
  FOLDER_JRE="$(ls -ld1 $TARGET/jdk*)"
  # Make a symlink to the JRE
  rm "$TARGET/jre_latest"
  ln -s "$FOLDER_JRE" "$TARGET/jre_latest"
}


#---------------------------------------------------------------
function init {
#---------------------------------------------------------------
  printf "DETAILS:SHOW\n"
  initGlobalVars
  copyHashGarten
  copyFiles
  setupJava
  enableAppleScriptMenu
}   


#---------------------------------------------------------------
function main {
#---------------------------------------------------------------
  init
  setupAllFileManagers
  finish
}

main
