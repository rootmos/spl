is_cached() {
    [ -f "$CACHE/$1" ]
}

get_cached() {
    echo "$1  $CACHE/$1" | sha256sum -c | output
    cp "$CACHE/$1" "$2"
}

sha256() {
    sha256sum "$1" | cut -f1 -d' '
}

put_cache() {
    if [ -d "$CACHE" ]; then
        info "caching $(basename "$1"): $(sha256 "$1")"
        cp "$1" "$CACHE/$(sha256 "$1")"
    fi
}
