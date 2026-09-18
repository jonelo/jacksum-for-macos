#!/bin/bash
# Creates the .app, optionally the .pdf and the .dmg
# (c) 2021-2026 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../config"
REPO_DIR="${SCRIPT_DIR}/.."

source "${CFG_DIR}/make_pdf.cfg"

${SCRIPT_DIR}/make_app.sh

# the .dmg ships a PDF of the README, do not let it get out of date
if [ "$MAKE_PDF_IN_MAKE_ALL" = "true" ] &&
   [ "${REPO_DIR}/${MD_FILE_DEFAULT}" -nt "${REPO_DIR}/${PDF_FILE_DEFAULT}" ]; then
    printf "%s is newer than %s, refreshing it ...\n" "$MD_FILE_DEFAULT" "$PDF_FILE_DEFAULT"
    ${SCRIPT_DIR}/make_pdf.sh || exit 1
fi

${SCRIPT_DIR}/make_dmg.sh

OUT="${SCRIPT_DIR}/../output"
echo "both .app and .dmg have been stored in ${OUT}" 
ls -la "${OUT}"
open "${SCRIPT_DIR}/../output/"
