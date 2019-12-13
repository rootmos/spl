LOG_FILE=${LOG_FILE-/dev/null}
if [ "${VERBOSE-0}" -eq 1 ]; then
    LOG_OUTPUT=1
fi

info() {
    if [ "${LOG_INFO-1}" -eq 1 ]; then
        echo "-- $*" | tee -a "$LOG_FILE" 1>&2
    else
        echo "!! $*" >> "$LOG_FILE"
    fi
}

error() {
    if [ "${LOG_ERROR-1}" -eq 1 ]; then
        echo "!! $*" | tee -a "$LOG_FILE" 1>&2
    else
        echo "!! $*" >> "$LOG_FILE"
    fi
    exit 1
}

output() {
    if [ "${LOG_OUTPUT-0}" -eq 1 ]; then
        tee -a "$LOG_FILE"
    else
        cat >> "$LOG_FILE"
    fi
}