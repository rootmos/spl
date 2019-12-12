#!/bin/bash

set -o nounset -o pipefail -o errexit

SUDO=${SUDO-}
J=$((2*$(nproc)))
LOG_FILE=${LOG_FILE-/dev/null}
while getopts "vc:Sj:l:-" OPT; do
    case $OPT in
        c) CACHE=${OPTARG:-$HOME/.cache/spl} ;;
        S) SUDO=sudo ;;
        j) J=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        -) break ;;
        v) VERBOSE=1 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${CACHE-}" ]; then
    CACHE=/dev/null
else
    mkdir -p "$CACHE"
fi

info() {
    if [ -n "${INFO-1}" ]; then
        echo "-- $*" >&2
    fi
}

output() {
    if [ "${VERBOSE-0}" -eq 1 ]; then
        tee -a "$LOG_FILE"
    else
        cat >> "$LOG_FILE"
    fi
}

_clean() {
    rm -rf "$WS"
}
trap 'command -v _clean_main > /dev/null && _clean_main; _clean' EXIT

WS=$(mktemp -d)
TMP=$WS/tmp
mkdir -p "$TMP"

export SUDO J
