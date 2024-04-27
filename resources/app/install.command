#!/bin/bash
# 
#  Jacksum File Browser Integration for macOS
#  Copyright (c) 2010-2024 Dipl.-Inf. (FH) Johann N. Loefflmann
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
JACKSUM_VERSION=3.7.0


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

  FINISHED=$[$FINISHED+4]
  PERCENT=$[$FINISHED*100/$TOTAL_COUNT]
  printf "PROGRESS:%i\n" $PERCENT
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
} 


#---------------------------------------------------------------
function initGlobalVars {
#---------------------------------------------------------------
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  APP_DIR=/Applications/HashGarten.app
  COMMANDS="cmd_calc;1)_Calc_hash_values cmd_check;2)_Check_data_integrity cmd_cust;3)_Customized_output cmd_edit;4)_Edit_script"
  COMMANDS_COUNT=($COMMANDS)
  COMMANDS_COUNT=${#COMMANDS_COUNT[@]}
  TOTAL_COUNT=$COMMANDS_COUNT
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
/Applications/HashGarten.app/Contents/Java/jre_latest/Contents/Home/bin/java -jar "/Applications/HashGarten.app/Contents/MacOS/lib/jacksum-3.7.0.jar" "$@"
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

    FINISHED=$[$FINISHED+1]
    PERCENT=$[$FINISHED*100/$TOTAL_COUNT]
    printf "PROGRESS:%i\n" $PERCENT

  done
}


#---------------------------------------------------------------
function finish {
#---------------------------------------------------------------

cat << EOL

Both Jacksum and HashGarten have been installed.
They have also been integrated into the script
menu for the following file managers:

EOL

  printf "  - Finder\n"
  if [ $PATH_FINDER = 1 ]; then
    printf "  - Path Finder\n"
  fi
  if [ $MUCOMMANDER = 1 ]; then
    printf "  - muCommander\n"
  fi

cat << EOL

Open your file manager, select files and
directories and choose an entry from the
EOL

  printf "script folder called \"Jacksum %s\".\n" "$JACKSUM_VERSION"
  if [ $APPLE_SCRIPT_ERROR -eq 0 ]; then
    printf "\nDone.\n"
  else
    printf "\nDown with errors. See above.\n"
  fi
}


#---------------------------------------------------------------
function setupAllFileManagers {
#---------------------------------------------------------------
  setup "Finder"

  if [ $PATH_FINDER -eq 1 ]; then
      setup "Path Finder"
  fi

  if [ $MUCOMMANDER -eq 1 ]; then
      setup_muCommander
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
