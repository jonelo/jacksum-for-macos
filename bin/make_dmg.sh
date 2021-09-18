#!/bin/bash
# creates an .dmg by using the props from config/make_dmg.cfg
# (c) 2021 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../resources"
RES_DIR="${SCRIPT_DIR}/../resources/dmg"
OUT_DIR="${SCRIPT_DIR}/../output"
WORK_DIR="/tmp/dmg-creation.$$"

source ${CFG_DIR}/make_all.cfg
source ${CFG_DIR}/make_dmg.cfg

mkdir -p "${OUT_DIR}"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

MOUNTPOINT=dmg-creation.$$
cp ${RES_DIR}/template_empty.dmg.bz2 template.dmg.bz2
bunzip2 -f template.dmg.bz2
DMG_TEMPLATE=template.dmg

# mount the image
mkdir -p $MOUNTPOINT
MOUNT=$(hdiutil attach $DMG_TEMPLATE -noautoopen -mountpoint $MOUNTPOINT | tail -1)
DEVICE=${MOUNT%% *}

# copy everything to the image
cp -R "${OUT_DIR}/$APP_NAME" "$MOUNTPOINT/$APP_NAME"
cp $RES_DIR/readme.txt "$MOUNTPOINT/"
cp $RES_DIR/release_notes.txt "$MOUNTPOINT/"
cp $RES_DIR/license.txt "$MOUNTPOINT/"

# background handler
# rm -Rf $MOUNTPOINT/.background
# mkdir -p $MOUNTPOINT/.background/
# cp resources/background.png $MOUNTPOINT/.background/

# set the icon for the disk image
# cp nc-disk.icns $MOUNTPOINT/.VolumeIcon.icns
# SetFile -a C $MOUNTPOINT
hdiutil detach $DEVICE -quiet -force

# pre clean
rmdir $MOUNTPOINT
rm "${OUT_DIR}/$DMG_FILENAME"

# compress the image
hdiutil convert "$DMG_TEMPLATE" -format UDZO -imagekey -zlib-level=9 -o "${OUT_DIR}/$DMG_FILENAME"

rm "$DMG_TEMPLATE"

# restore the working directory
cd -

# clean up
rmdir ${WORK_DIR}

