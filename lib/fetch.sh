fetch() {
    if [ -f "$CACHE/$3" ]; then
        info "fetching $(basename "$1") (cached)"
        echo "$3  $CACHE/$3" | sha256sum -c | output
        cp "$CACHE/$3" "$1"
    else
        info "fetching $(basename "$1")"
        FILE=$TMP/$(basename "$1")
        wget --output-document="$FILE" "$2" | output
        echo "$3  $FILE" | sha256sum -c | output
        if [ -d "$CACHE" ]; then
            cp "$FILE" "$CACHE/$3"
        fi
        mv "$FILE" "$1"
    fi
}
