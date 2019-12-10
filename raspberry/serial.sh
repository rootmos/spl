#!/bin/bash

set -o nounset -o pipefail -o errexit

WAIT=0
LOOP=0
POLL=0.2
BAUD=115200
INFO=1
INTERACTIVE=1
while getopts "wlqd:p:-" OPT; do
    case $OPT in
        w) WAIT=1 ;;
        l) LOOP=1 ;;
        p) POLL=$OPTARG ;;
        d) DEVICE=$OPTARG ;;
        q) INFO=0 ;;
        -) break ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

info() {
    if [ "$INFO" -eq 1 ]; then
        echo "$@" 1>&2
    fi
}

find_device() {
    find /dev -name "ttyUSB*" | head -n1
}

go() {
    if [ "$LOOP" -eq 1 ]; then
        EXEC=
    fi
    set +o errexit
    if [ "${INTERACTIVE-0}" -eq 1 ]; then
        ${EXEC-exec} picocom -b $BAUD "$1"
    else
        ${EXEC-exec} socat "$1",rawer,b$BAUD STDOUT
    fi
    EC=$?
    set -o errexit
    info "exit: $EC" 1>&2
}

if [ -n "${DEVICE-}" ]; then
    go "$DEVICE"
fi

if [ $WAIT -eq 0 ]; then
    go "$(find_device)"
fi

TIME_WAITED=0
while true; do
    DEVICE=$(find_device)
    if [ -z "$DEVICE" ]; then
        if [ "$(bc <<< "$TIME_WAITED == 0 || $TIME_WAITED >= 1")" -eq 1 ]; then
            info "waiting for devices..."
            TIME_WAITED=0
        fi
        sleep "$POLL"
        TIME_WAITED=$(bc <<< "$TIME_WAITED + $POLL")
    else
        go "$DEVICE"
    fi
done
