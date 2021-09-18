#!/bin/bash
# creates an .app by using the props from cfg/make_app.cfg
# (c) 2021 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../resources"
RES_DIR="${SCRIPT_DIR}/../resources/app"
OUT_DIR="${SCRIPT_DIR}/../output"

source "${SCRIPT_DIR}/common.include"
source ${CFG_DIR}/make_all.cfg
source ${CFG_DIR}/make_app.cfg
mkdir -p "${OUT_DIR}"

checkPrerequisites /usr/local/bin/platypus

/usr/local/bin/platypus \
--overwrite \
--app-icon "${RES_DIR}/${APP_ICONS}" \
--name "${APP_NAME}"  \
--output-type 'Progress Bar'  \
--interpreter '/bin/bash'  \
--author "${APP_AUTHOR}"  \
--bundle-identifier "${APP_BUNDLE_ID}" \
--bundled-file "${RES_DIR}/${APP_JAR_FILE}" \
--bundled-file "${RES_DIR}/${APP_LICENSE_FILE}" \
  "${RES_DIR}/install.command" \
  "${OUT_DIR}/${APP_NAME}"

