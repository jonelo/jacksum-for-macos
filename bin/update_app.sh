#!/bin/bash
# Updates the HashGarten.app by downloading the published Linux bundle
# and extracting the three jar files from there.
#
# Copyright (c) 2026 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../config"
source ${CFG_DIR}/update_app.cfg

TARGET_DIR="${SCRIPT_DIR}/../resources/app/HashGarten.app/Contents/MacOS/lib/"

FILE="https://github.com/jonelo/jacksum-for-linux/releases/download/v${LINUX_BUNDLE_VERSION}/jacksum-${LINUX_JACKSUM_VERSION}-hashgarten-${LINUX_HASHGARTEN_VERSION}-for-linux-${LINUX_BUNDLE_VERSION}.tar.bz2"

printf "Files in %s:\n" "$TARGET_DIR"
ls -la $TARGET_DIR

cd $TARGET_DIR
mkdir -p /tmp/$$
curl -L -o /tmp/$$/my.tar.bz2 $FILE
if [ $? -ne 0 ]; then
  echo "Error while trying to download %s\n" "$FILE"
  cd -
else
  cd /tmp/$$
  tar xfvj my.tar.bz2 "jacksum-for-linux/*.jar"
  cd -
  rm *.jar
  cp /tmp/$$/jacksum-for-linux/*.jar .
  printf "Files have been updated in %s:\n" "$TARGET_DIR"
  ls -la "$TARGET_DIR"
fi
