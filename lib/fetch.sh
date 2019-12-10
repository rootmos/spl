fetch() {
    FILE=$TMP/$(basename "$1")
    wget --output-document="$FILE" "$2"
    sha256sum "$FILE"
    echo "$3  $FILE" | sha256sum -c
    mv "$FILE" "$1"
}
