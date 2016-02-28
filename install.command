#!/bin/bash
# 
#  Jacksum File Browser Integration for Mac OS X
#  Copyright (C) 2010-2016 Dipl.-Inf. (FH) Johann N. Loefflmann
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

PROGDIR=/Applications/Jacksum
mkdir -p "$PROGDIR"

CURRDIR="$(cd "$(dirname "$0")" && pwd)"

echo "Copying jacksum.jar ..."
cp "$CURRDIR/jacksum.jar" "$PROGDIR"
echo "Copying license.txt ..."
cp "$CURRDIR/license.txt" "$PROGDIR"

LAUNCHER="$PROGDIR/jacksum"
echo "Creating $LAUNCHER ..."
echo '#!/bin/bash
java -jar "/Applications/Jacksum/jacksum.jar" "$@"' > "$LAUNCHER"
chmod +x "$LAUNCHER"

if [ $(id | cut -c5) -ne 0 ]; then
    SCRIPTS="$HOME/Library/Scripts/Applications/Finder/Jacksum"
else
    SCRIPTS="/Library/Scripts/Finder Scripts/Jacksum"
fi
mkdir -p "$SCRIPTS"
ALGORITHMS="adler32 cksum crc8 crc16 crc24 crc32 crc32_bzip2 crc32_mpeg2 crc64 ed2k elf fcs16 gost has160 haval_128_3 haval_128_4 haval_128_5 haval_160_3 haval_160_4 haval_160_5 haval_192_3 haval_192_4 haval_192_5 haval_224_3 haval_224_4 haval_224_5 haval_256_3 haval_256_4 haval_256_5 md2 md4 md5 ripemd128 ripemd160 ripemd256 ripemd320 sha0 sha1 sha224 sha256 sha384 sha512 sum8 sum16 sum24 sum32 sumbsd sumsysv tiger tiger128 tiger160 tiger2 tree:tiger tree:tiger2 whirlpool0 whirlpool1 whirlpool2 xor8"
for ALGO in $ALGORITHMS
do
  # Creating /tmp/$ALGO.applescript
  # Make copyright header compatible with old AppleScript versions 1.x
  echo '(*' > "/tmp/$ALGO.applescript"
  head -n19 "$0" | tail -n18 | tr '#' ' ' >> "/tmp/$ALGO.applescript"
  echo '*)' >> "/tmp/$ALGO.applescript"
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
set theCommand to "/Applications/Jacksum/jacksum -a ' >> "/tmp/$ALGO.applescript"
echo -n "$ALGO" >> "/tmp/$ALGO.applescript"
echo -n ' " & allFiles & " > /tmp/jacksum.txt; echo --- >> /tmp/jacksum.txt; echo Created with Jacksum 1.7.0, algorithm=' >> "/tmp/$ALGO.applescript"
echo -n "$ALGO" >> "/tmp/$ALGO.applescript"
echo ' >> /tmp/jacksum.txt"
do shell script theCommand
property targetURL : "file:///tmp/jacksum.txt"
open location targetURL' >> "/tmp/$ALGO.applescript"

# Compiling to $SCRIPTS/$ALGO.scpt
echo "Installing $ALGO ..."
osacompile -d -o "/$SCRIPTS/$ALGO.scpt" "/tmp/$ALGO.applescript"

# Removing /tmp/$ALGO.applescript
rm "/tmp/$ALGO.applescript"

done

echo "
Jacksum has been integrated into the Finder's script menu.

Make sure that you have activated the Apple Script Menu. Starting with
Mac OS X 10.6 (Snow Leopard), the Script Menu preferences are at the Apple 
Script-Editor's preferences, in the General tab.

Go to Finder, select a folder or one or more files and choose an algorithm from
the script folder called Jacksum in order to calculate checksums for the files.

Done."

