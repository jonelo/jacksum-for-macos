#!/bin/bash
# 
#  Jacksum File Browser Integration for macOS
#  Copyright (c) 2010-2023 Dipl.-Inf. (FH) Johann N. Loefflmann
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
# Explicitly set the PATH
PATH="/sbin:/usr/sbin:/bin:/usr/bin"

JACKSUM_VERSION=3.7.0
PROGDIR=/Applications/Jacksum
mkdir -p "$PROGDIR"

CURRDIR="$(cd "$(dirname "$0")" && pwd)"

echo "Copying .jar files ..."
cp "$CURRDIR"/*.jar "$PROGDIR"

echo "Copying jacksum.sh ..."
cp "$CURRDIR/jacksum.sh" "$PROGDIR"

echo "Copying license.txt ..."
cp "$CURRDIR/license.txt" "$PROGDIR"

JAVALAUNCHER="$PROGDIR/javalauncher"
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

LAUNCHER="$PROGDIR/jacksum"
echo "Creating $LAUNCHER ..."
cat << "EOL" > "$LAUNCHER"
#!/bin/bash
/Applications/Jacksum/javalauncher -jar "/Applications/Jacksum/jacksum-3.7.0.jar" "$@"
EOL
chmod +x "$LAUNCHER"

if [ $(id | cut -c5) -ne 0 ]; then
    SCRIPTS="${HOME}/Library/Scripts/Applications/Finder/Jacksum ${JACKSUM_VERSION}"
else
    SCRIPTS="/Library/Scripts/Finder Scripts/Jacksum ${JACKSUM_VERSION}"
fi
mkdir -p "$SCRIPTS"
#ALGORITHMS="$(/Applications/Jacksum/jacksum -a all --list)"
COMMANDS="cmd_calc;1)_Calc_hash_values cmd_check;2)_Check_data_integrity cmd_cust;3)_Customized_output cmd_edit;4)_Edit_script cmd_help;5)_Help"

TOTALCOUNT=$(echo "$COMMANDS" | wc -l)
FINISHED=0
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
  echo -n 'tell application "Finder"
  set theseItems to the selection
end tell
set allFiles to ""
repeat with i from 1 to the count of theseItems
  set thisItem to (item i of theseItems) as alias
  set thisFile to POSIX path of thisItem
  set thisFileQuoted to quoted form of thisFile
  set allFiles to allFiles & " " & thisFileQuoted
end repeat
set theCommand to "/Applications/Jacksum/jacksum.sh ' >> "${APPLE_SCRIPT}"
echo -n "$CMD" >> "${APPLE_SCRIPT}"
echo ' " & allFiles' >> "${APPLE_SCRIPT}"
echo 'do shell script theCommand' >> "${APPLE_SCRIPT}"

  # Compiling to .applescript to .scpt
  printf "Installing menu %s ...\n" "$TXT"
  osacompile -d -o "${COMPILED_SCRIPT}" "${APPLE_SCRIPT}"

  # Clean up
  rm "${APPLE_SCRIPT}"

  FINISHED=$((FINISHED+1))
  PERCENT=$((FINISHED*100/$TOTALCOUNT))
  printf "PROGRESS:%i\n" $PERCENT

done

cat << EOL

Jacksum has been integrated into the Finder's script menu.

Make sure that you have activated the Apple Script Menu. Starting with
Mac OS X 10.6 (Snow Leopard), the Script Menu preferences are at the Apple 
Script-Editor's preferences, in the General tab.

Go to Finder, select one or more files and directories and choose an entry
from the script directory called Jacksum.

Done.
EOL
