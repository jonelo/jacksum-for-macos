#!/bin/bash
#
# Jacksum File Browser Integration Script, https://jacksum.net
# Copyright (c) 2006-2024 Johann N. Loefflmann, https://johann.loefflmann.net
# Code has been released under the conditions of the GPLv3+.
#

viewer() {
  open -e "$1"
}

FILE_LIST="/tmp/jacksum—filelist.txt"
OUTPUT="/tmp/jacksum-output.txt"
ERROR_LOG="/tmp/jacksum-error.txt"
JAVA="/Applications/HashGarten.app/Contents/Java/jre_latest/Contents/Home/bin/java"
LAUNCHER="/Applications/HashGarten.app/Contents/MacOS/bin/launcher"
JACKSUM_JAR="/Applications/HashGarten.app/Contents/MacOS/lib/jacksum-3.7.0.jar"
HASHGARTEN_JAR="/Applications/HashGarten.app/Contents/MacOS/lib/HashGarten-0.18.0.jar"
SCRIPT="/Applications/HashGarten.app/Contents/MacOS/bin/jacksum.sh"

cat /dev/null > "$FILE_LIST"
VIRGIN=1
for i in "$@"
do
  # ignore the 1st arg
  if [ "$VIRGIN" -eq 1 ]; then
    VIRGIN=0
  else
    # make sure that we get always absolute paths for both directories and files
    if [ -d "$i" ]; then
      ABSOLUTE="$(cd "$i" && pwd)"
    else
      ABSOLUTE="$(cd "$(dirname "$i")" && pwd)/$(basename "$i")"
    fi
    printf "%s\n" "${ABSOLUTE}" >> "${FILE_LIST}"
  fi
done

cd "$HOME"
ALGO=$1
shift

case $ALGO in

  "cmd_calc")
    "${LAUNCHER}" --header -O relative -U ${ERROR_LOG} --file-list-format list --file-list ${FILE_LIST} --path-relative-to-entry 1 --verbose default,summary
    # "${JAVA}" -jar "${HASHGARTEN_JAR}" --header -O relative -U ${ERROR_LOG} --file-list-format list --file-list ${FILE_LIST} --path-relative-to-entry 1 --verbose default,summary
    ;;

  "cmd_check")
    "${JAVA}" -jar "${HASHGARTEN_JAR}" --header -c relative -O ${OUTPUT} -U ${OUTPUT} --file-list-format list --file-list ${FILE_LIST} --path-relative-to-entry 1 --verbose default,summary
    ;;

  "cmd_cust")
    ALGOS="md5+sha1+ripemd160+tiger+\
sha256+sha512/256+sha3-256+shake128+ascon-hash+sm3+streebog256+kupyna-256+lsh-256-256+blake3+k12+keccak256+\
sha512+sha3-512+shake256+streebog512+kupyna-512+lsh-512-512+blake2b-512+keccak512+m14+skein-512-512+whirlpool"
  TEMPLATE='File info:
    name:                      #FILENAME{name}
    path:                      #FILENAME{path}
    size:                      #FILESIZE bytes

legacy message digests (avoid if possible):
    MD5 (128 bit):             #HASH{md5}
    SHA1 (160 bit):            #HASH{sha1}
    RIPEMD-160 (160 bit):      #HASH{ripemd160}
    TIGER (192 bit):           #HASH{tiger}

256 bit message digests (hex):
    SHA-256 (USA):             #HASH{sha256}
    SHA-512/256 (USA):         #HASH{sha512/256}
    SHA3-256 (USA):            #HASH{sha3-256}
    SHAKE128 (USA):            #HASH{shake128}
    Ascon-Hash (USA):          #HASH{ascon-hash}
    SM3 (China):               #HASH{sm3}
    STREEBOG 256 (Russia):     #HASH{streebog256}
    Kupyna256 (Ukraine):       #HASH{kupyna-256}
    LSH-256-256 (South Korea): #HASH{lsh-256-256}
    BLAKE3:                    #HASH{blake3}
    KangarooTwelve:            #HASH{k12}
    KECCAK256:                 #HASH{keccak256}

512 bit message digests (base64, no padding):
    SHA-512 (USA):             #HASH{sha512,base64-nopadding}
    SHA3-512 (USA):            #HASH{sha3-512,base64-nopadding}
    SHAKE256 (USA):            #HASH{shake256,base64-nopadding}
    STREEBOG 512 (Russia):     #HASH{streebog512,base64-nopadding}
    KUPYNA-512 (Ukraine):      #HASH{kupyna-512,base64-nopadding}
    LSH-512-512 (South Korea): #HASH{lsh-512-512,base64-nopadding}
    BLAKE2b-512:               #HASH{blake2b-512,base64-nopadding}
    KECCAK512:                 #HASH{keccak512,base64-nopadding}
    MarsupilamiFourteen:       #HASH{m14,base64-nopadding}
    SKEIN-512-512:             #HASH{skein-512-512,base64-nopadding}
    WHIRLPOOL:                 #HASH{whirlpool,base64-nopadding}
'

    "${JAVA}" -jar "${JACKSUM_JAR}" -a "${ALGOS}" -E hex --format "${TEMPLATE}" \
    --file-list "${FILE_LIST}" --file-list-format list \
    -O "${OUTPUT}" -U "${OUTPUT}"

    viewer "${OUTPUT}"
    ;;

  "cmd_edit")
    open -e "${SCRIPT}"
    exit
    ;;

  "cmd_help")
    "${JAVA}" -jar "${JACKSUM_JAR}" --help > "${OUTPUT}"
    viewer "${OUTPUT}"
    ;;

  *)
    "${JAVA}" -jar "${JACKSUM_JAR}" -a $ALGO --header \
    --file-list "${FILE_LIST}" --file-list-format list --path-relative-to-entry 1 \
    -O "${OUTPUT}" -U "${OUTPUT}"
    viewer "${OUTPUT}"
    ;;

esac
