fetch() {
    local OPTIND
    BORROW=0
    while getopts "b" OPT; do
        case "$OPT" in
            b) BORROW=1 ;;
            ?) exit 2 ;;
        esac
    done
    shift $((OPTIND-1))

    if is_cached "$3"; then
        info "fetching $(basename "$1") (cached)"
        if [ "$BORROW" -eq 0 ]; then
            get_cached "$3" "$1"
        else
            borrow_cached "$3" "$1"
        fi
    else
        info "fetching $(basename "$1")"
        FILE=$TMP/$(basename "$1")
        wget --progress=dot --output-document="$FILE" "$2" 2>&1 | output
        put_cache "$FILE"
        mv "$FILE" "$1"
    fi
}
