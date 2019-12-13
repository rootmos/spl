busybox_fetch() {
    fetch -b "$WS/busybox.tar.bz2" \
        "https://busybox.net/downloads/busybox-1.31.1.tar.bz2" \
        "d0f940a72f648943c1f2211e0e3117387c31d765137d92bd8284a3fb9752a998"
    mkdir -p "$WS/busybox"
    tar xf "$WS/busybox.tar.bz2" -C "$WS/busybox" --strip-components=1 | output
}

busybox_install() {
    busybox_fetch
    busybox_config | grep -v "CONFIG_PREFIX" > "$WS/busybox/.config"
    cat <<EOF >> "$WS/busybox/.config"
CONFIG_PREFIX="$1"
EOF
    make -C "$WS/busybox" CROSS_COMPILE="$TARGET-" -j"$J" 2>&1 V=1 | output
    make -C "$WS/busybox" CROSS_COMPILE="$TARGET-" -j"$J" install 2>&1 | output
}

busybox_menuconfig() {
    busybox_fetch
    busybox_config > "$WS/busybox/.config"
    make -C "$WS/busybox" CROSS_COMPILE="$TARGET-" menuconfig < /dev/tty
    cp "$WS/busybox/.config" "$1"
}
