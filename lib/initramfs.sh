initramfs_list() {
    if [ -d "$1" ]; then
        LOCAL="$1"
        TARGET="${2-}"
        find "$LOCAL" -mindepth 1 | while read -r x; do
            LOCATION=$(sed 's,^'"$LOCAL"','"$TARGET"',' <<< "$x")
            if [ -d "$x" ]; then
                echo "dir $LOCATION 0555 0 0"
            elif [ -x "$x" ]; then
                echo "file $LOCATION $x 0555 0 0"
            elif [ -f "$x" ]; then
                echo "file $LOCATION $x 0444 0 0"
            else
                error "don't know how to handle: $x"
            fi
        done
    else
        error "don't know how to handle: $1"
    fi
}

initramfs_mk() {
    gen_init_cpio - | gzip -9 > "$1"
}
