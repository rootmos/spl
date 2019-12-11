#!/bin/bash

set -o nounset -o pipefail -o errexit

SUDO=${SUDO-}
J=$((2*$(nproc)))
while getopts "vc:Sj:-" OPT; do
    case $OPT in
        c) CACHE=${OPTARG:-$HOME/.cache/spl} ;;
        S) SUDO=sudo ;;
        j) J=$OPTARG ;;
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
        cat
    else
        cat > /dev/null
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
