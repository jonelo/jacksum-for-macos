#!/bin/bash
#
# Downloads the Eclipse Temurin JREs for macOS (x64 and aarch64) of the latest
# LTS release from the Adoptium API, verifies them by their SHA-256 checksums
# and stores the .tar.gz files in resources/app/ where bin/make_app.sh picks
# them up. Obsolete JRE tarballs of the same architecture are removed.
#
# Copyright (c) 2026 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../config"
TARGET_DIR="${SCRIPT_DIR}/../resources/app"

source "${SCRIPT_DIR}/lib/common.include"
source "${CFG_DIR}/update_jres.cfg"


#---------------------------------------------------------------
function usage {
#---------------------------------------------------------------
cat << EOL
Usage: $(basename "$0") [-f|--force] [-h|--help] [<feature-version>]

Downloads the Temurin JREs for ${JRE_OS} (${JRE_ARCHS}) to
resources/app/ and removes obsolete ones.

  <feature-version>  the Java feature version to download, e. g. 21.
                     Defaults to JRE_FEATURE_VERSION in
                     config/update_jres.cfg, and if that is empty, to the
                     most recent LTS release as reported by the Adoptium API.
  -f, --force        download again, even if the file is there already
  -h, --help         print this help and exit
EOL
}


#---------------------------------------------------------------
function fail {
#---------------------------------------------------------------
  printf >&2 "FATAL: %s Exit.\n" "$1"
  exit 1
}


# params: key path, JSON file
# prints the value of the key, JSON is parsed by plutil (part of macOS)
#---------------------------------------------------------------
function json_value {
#---------------------------------------------------------------
  plutil -extract "$1" raw -o - -- "$2" 2>/dev/null
}


# params: URL, target file
#---------------------------------------------------------------
function fetch_json {
#---------------------------------------------------------------
  curl -fsS --retry 3 -o "$2" "$1" ||
    fail "$(printf "could not query %s." "$1")"
}


# determines the feature version to be downloaded
#---------------------------------------------------------------
function determineFeatureVersion {
#---------------------------------------------------------------
  if [ -z "$FEATURE_VERSION" ]; then
    printf "Asking %s for the most recent LTS release ...\n" "$ADOPTIUM_API"
    fetch_json "${ADOPTIUM_API}/info/available_releases" "${TMP_DIR}/releases.json"
    FEATURE_VERSION="$(json_value most_recent_lts "${TMP_DIR}/releases.json")"
  fi

  case "$FEATURE_VERSION" in
    ""|*[!0-9]*) fail "$(printf "\"%s\" is not a valid Java feature version." "$FEATURE_VERSION")" ;;
  esac
  printf "Java feature version: %s\n" "$FEATURE_VERSION"
}


# params: architecture
# removes all JRE tarballs of that architecture, but keeps $NAME
#---------------------------------------------------------------
function removeObsoleteTarballs {
#---------------------------------------------------------------
  local arch="$1"
  local file
  for file in "${TARGET_DIR}"/OpenJDK*_${arch}_${JRE_OS}_*.tar.gz; do
    [ -e "$file" ] || continue
    if [ "$(basename "$file")" != "$NAME" ]; then
      rm -f "$file" && printf "Removed obsolete %s\n" "$(basename "$file")"
    fi
  done
}


# params: architecture
# downloads, verifies and installs the JRE tarball for that architecture
#---------------------------------------------------------------
function updateJre {
#---------------------------------------------------------------
  local arch="$1"
  local json="${TMP_DIR}/assets_${arch}.json"
  local query="os=${JRE_OS}&architecture=${arch}&image_type=${JRE_IMAGE_TYPE}&vendor=${JRE_VENDOR}"

  printf "\nLooking up the %s %s for %s ...\n" "$JRE_IMAGE_TYPE" "$arch" "$JRE_OS"
  fetch_json "${ADOPTIUM_API}/assets/latest/${FEATURE_VERSION}/${JRE_JVM_IMPL}?${query}" "$json"

  NAME="$(json_value 0.binary.package.name "$json")"
  local link="$(json_value 0.binary.package.link "$json")"
  local checksum="$(json_value 0.binary.package.checksum "$json")"
  local size="$(json_value 0.binary.package.size "$json")"
  local release="$(json_value 0.release_name "$json")"

  if [ -z "$NAME" ] || [ -z "$link" ] || [ -z "$checksum" ]; then
    fail "$(printf "the Adoptium API does not offer a %s %s %s of Java %s." \
                   "$JRE_OS" "$arch" "$JRE_IMAGE_TYPE" "$FEATURE_VERSION")"
  fi
  printf "Release: %s (%s)\n" "$release" "$NAME"

  if [ $FORCE -eq 0 ] && [ -f "${TARGET_DIR}/${NAME}" ] &&
     [ "$(shasum -a 256 "${TARGET_DIR}/${NAME}" | cut -d' ' -f1)" = "$checksum" ]; then
    printf "Already there and SHA-256 verified, nothing to download.\n"
    removeObsoleteTarballs "$arch"
    RELEASES="${RELEASES}${arch}: ${release}"$'\n'
    return
  fi

  printf "Downloading %s ...\n" "$link"
  curl -fL --retry 3 --progress-bar -o "${TMP_DIR}/${NAME}" "$link" ||
    fail "$(printf "could not download %s." "$link")"

  printf "Verifying SHA-256 ...\n"
  local actual="$(shasum -a 256 "${TMP_DIR}/${NAME}" | cut -d' ' -f1)"
  if [ "$actual" != "$checksum" ]; then
    fail "$(printf "SHA-256 mismatch for %s:\n  expected %s\n  actual   %s" "$NAME" "$checksum" "$actual")"
  fi
  local actual_size="$(stat -f%z "${TMP_DIR}/${NAME}")"
  if [ -n "$size" ] && [ "$actual_size" != "$size" ]; then
    fail "$(printf "size mismatch for %s: expected %s bytes, got %s bytes." "$NAME" "$size" "$actual_size")"
  fi

  # install.command expects the archive to contain a folder called jdk*
  local topdir="$(tar -tzf "${TMP_DIR}/${NAME}" 2>/dev/null | head -1)"
  case "$topdir" in
    jdk*) ;;
    *) fail "$(printf "%s contains \"%s\" rather than a jdk* folder, install.command would not find the JRE." "$NAME" "$topdir")" ;;
  esac

  mv "${TMP_DIR}/${NAME}" "${TARGET_DIR}/${NAME}" ||
    fail "$(printf "could not move the download to %s." "$TARGET_DIR")"
  printf "Stored %s in %s\n" "$NAME" "$TARGET_DIR"

  removeObsoleteTarballs "$arch"
  RELEASES="${RELEASES}${arch}: ${release}"$'\n'
}


# checks that the globs of make_app.sh match exactly one file each
#---------------------------------------------------------------
function checkGlobsOfMakeApp {
#---------------------------------------------------------------
  local pattern count
  for pattern in "*x64*.tar.gz" "*aarch64*.tar.gz"; do
    count="$(compgen -G "${TARGET_DIR}/${pattern}" | wc -l | tr -d ' ')"
    if [ "$count" != "1" ]; then
      printf >&2 "WARNING: %s/%s matches %s files, bin/make_app.sh expects exactly one.\n" \
                 "resources/app" "$pattern" "$count"
    fi
  done
}


#---------------------------------------------------------------
function main {
#---------------------------------------------------------------
  FORCE=0
  FEATURE_VERSION="$JRE_FEATURE_VERSION"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -f|--force) FORCE=1 ;;
      -h|--help) usage; exit 0 ;;
      -*) usage >&2; fail "$(printf "unknown option %s." "$1")" ;;
      *) FEATURE_VERSION="$1" ;;
    esac
    shift
  done

  checkPrerequisites curl plutil shasum tar

  [ -d "$TARGET_DIR" ] || fail "$(printf "%s does not exist." "$TARGET_DIR")"
  TMP_DIR="/tmp/$$"
  mkdir -p "$TMP_DIR" || fail "$(printf "could not create %s." "$TMP_DIR")"
  trap 'rm -rf "$TMP_DIR"' EXIT

  RELEASES=""
  determineFeatureVersion

  local arch
  for arch in $JRE_ARCHS; do
    updateJre "$arch"
  done

  checkGlobsOfMakeApp

  printf "\nJREs in %s:\n" "$TARGET_DIR"
  ls -la "${TARGET_DIR}"/OpenJDK*.tar.gz
  printf "\n%s" "$RELEASES"
  printf "Done.\n"
}

main "$@"
