fetch() {
    if [ -f "$CACHE/$3" ]; then
        echo "$3  $CACHE/$3" | sha256sum -c
        cp "$CACHE/$3" "$1"
    else
        FILE=$TMP/$(basename "$1")
        wget --output-document="$FILE" "$2"
        echo "$3  $FILE" | sha256sum -c
        if [ -d "$CACHE" ]; then
            cp "$FILE" "$CACHE/$3"
        fi
        mv "$FILE" "$1"
    fi
}
