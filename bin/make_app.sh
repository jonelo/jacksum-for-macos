#!/bin/bash
# creates an .app by using the props from cfg/make_app.cfg
# Copyright (c) 2021-2023 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../config"
OUT_DIR="${SCRIPT_DIR}/../output"
INT_DIR="${SCRIPT_DIR}/../resources/app/"

source "${SCRIPT_DIR}/lib/common.include"
source ${CFG_DIR}/make_all.cfg
source ${CFG_DIR}/make_app.cfg
mkdir -p "${OUT_DIR}"

# make the integration script app using Platypus
# Note: Platypus includes a command line tool counterpart to the Platypus.app
# application, platypus, which can be installed into /usr/local/bin/ via
# Settings... Install
checkPrerequisites /usr/local/bin/platypus

/usr/local/bin/platypus \
--overwrite \
--app-icon "${INT_DIR}/${APP_ICONS}" \
--name "${APP_NAME}"  \
--app-version "${DMG_VERSION}" \
--output-type 'Progress Bar'  \
--interpreter '/bin/bash'  \
--author "${APP_AUTHOR}"  \
--bundle-identifier "${APP_BUNDLE_ID}" \
--bundled-file "${INT_DIR}/${APP_LICENSE_FILE}" \
--bundled-file "${INT_DIR}/HashGarten.app" \
--bundled-file "${INT_DIR}/"*x64*.tar.gz \
--bundled-file "${INT_DIR}/"*aarch64*.tar.gz \
  "${INT_DIR}/install.command" \
  "${OUT_DIR}/${APP_NAME}"

if [ $? = 0 ]; then
  # reset any answers from previously dialogs
  tccutil reset AppleEvents
fi

