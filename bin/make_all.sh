#!/bin/bash
# Creates both the .app and the .dmg
# (c) 2021 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
${SCRIPT_DIR}/make_app.sh
${SCRIPT_DIR}/make_dmg.sh

OUT="${SCRIPT_DIR}/../output"
echo "both .app and .dmg have been stored in ${OUT}" 
ls -la "${OUT}"
