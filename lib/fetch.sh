fetch() {
    if is_cached "$3"; then
        info "fetching $(basename "$1") (cached)"
        get_cached "$3" "$1"
    else
        info "fetching $(basename "$1")"
        FILE=$TMP/$(basename "$1")
        wget --progress=dot --output-document="$FILE" "$2" 2>&1 | output
        put_cache "$3" "$FILE"
        mv "$FILE" "$1"
    fi
}
