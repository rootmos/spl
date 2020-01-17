LOG_FILE=${LOG_FILE-/dev/null}
LOG_DATE_FMT=%T

info() {
    if [ "${LOG_INFO-1}" -eq 1 ]; then
        echo "$(date +"$LOG_DATE_FMT") -- $*" | tee -a "$LOG_FILE" 1>&2
    else
        echo "$(date +"$LOG_DATE_FMT") -- $*" >> "$LOG_FILE"
    fi
}

error() {
    if [ "${LOG_ERROR-1}" -eq 1 ]; then
        echo "$(date +"$LOG_DATE_FMT") !! $*" | tee -a "$LOG_FILE" 1>&2
    else
        echo "$(date +"$LOG_DATE_FMT") !! $*" >> "$LOG_FILE"
    fi
    exit 1
}

output() {
    if [ "${VERBOSE-0}" -eq 1 ]; then
        tee -a "$LOG_FILE"
    else
        cat >> "$LOG_FILE"
    fi
}
