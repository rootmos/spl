#!/bin/bash

set -o nounset -o pipefail -o errexit

SUDO=${SUDO-}
J=$((2*$(nproc)))
DEBUG_SHELL=${DEBUG_SHELL-0}
while getopts "vc:Sj:l:d:o:K:-sDT:" OPT; do
    case $OPT in
        D) DEBUG_SHELL=1 ;;
        v) VERBOSE=1 ;;
        c) CACHE=${OPTARG:-$HOME/.cache/spl} ;;
        s) SITE=$OPTARG ;;
        S) SUDO=sudo ;;
        j) J=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        d) BLKDEV=$OPTARG ;;
        o) OUT=$OPTARG ;;
        K) KERNEL_SHA256=$OPTARG ;;
        T) TOOLCHAIN_SHA256=$OPTARG ;;
        -) break ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${CACHE-}" ]; then
    CACHE=/dev/null
else
    mkdir -p "$CACHE"
fi

_clean() {
    EC=$?
    if [ "$EC" -ne 0 ] && [ "$DEBUG_SHELL" -eq 1 ]; then
        _debug_shell
    fi

    if command -v _clean_main > /dev/null; then
        _clean_main
    fi

    rm -rf "$WS"
}
trap '_clean' EXIT

if [ "$DEBUG_SHELL" -eq 1 ]; then
    _debug_shell() {
        cd "$WS" && $SHELL < /dev/tty
    }
    trap '_debug_shell' INT
fi

WS=$(mktemp --tmpdir --directory "spl.$(basename "$0").XXXXXX")
TMP=$WS/tmp
mkdir -p "$TMP"
