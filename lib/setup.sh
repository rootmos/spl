if [ -z "${CACHE-}" ]; then
    CACHE=/dev/null
else
    mkdir -p "$CACHE"
fi

_clean() {
    EC=$?
    if [ "$EC" -ne 0 ] && [ "${DEBUG_SHELL-0}" -eq 1 ]; then
        _debug_shell
    fi

    if command -v _clean_main > /dev/null; then
        _clean_main
    fi

    rm -rf "$WS"
}
trap '_clean' EXIT

if [ "${DEBUG_SHELL-0}" -eq 1 ]; then
    _debug_shell() {
        cd "$WS" && $SHELL < /dev/tty
    }
    trap '_debug_shell' INT
fi

WS=$(mktemp --tmpdir --directory "spl.$(basename "$0").XXXXXX")
TMP=$WS/tmp
mkdir -p "$TMP"

J=$((2*$(nproc)))
