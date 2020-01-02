initramfs_list() {
    if [ -d "$1" ]; then
        LOCAL="$1"
        REMOTE="${2-}"
        find "$LOCAL" -mindepth 1 \
            -not \( -name ".pkg" -or -name "*.a" \) \
            | while read -r x; do
            LOCATION=$(sed 's,^'"$LOCAL"','"$REMOTE"',' <<< "$x")
            if [ -d "$x" ]; then
                echo "dir $LOCATION 0555 0 0"
            elif [ -h "$x" ]; then
                echo "slink $LOCATION $(readlink "$x") 0555 0 0"
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

    echo "dir /lib 0555 0 0"
    echo "slink /lib/ld-musl-$(cut -d- -f1 <<< "$TARGET").so.1 /usr/lib/libc.so 0555 0 0"
    echo "file /usr/lib/libc.so $TOOLCHAIN_PREFIX/lib/libc.so 0555 0 0"
}

initramfs_mk() {
    gen_init_cpio - | gzip -9 > "$1"
}
