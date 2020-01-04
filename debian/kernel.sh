KERNEL_SRC_URL=https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.92.tar.xz
KERNEL_SRC_SHA256=29c37cf8bbfa717ce98bc931371c35fcee3482734ad5faba32d02aff209883a2

kernel_menuconfig() {
    fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux"
    tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

    kernel_config > "$WS/linux/.config"
    make -C "$WS/linux" menuconfig
    cp "$WS/linux/.config" "$1"
}

kernel_install() {
    BOOT=$1
    if is_cached "${KERNEL_SHA256-}"; then
        info "install kernel (cached: $KERNEL_SHA256)"
        borrow_cached "$KERNEL_SHA256" "$WS/kernel.tar.bz2"
        tar -xvf "$WS/kernel.tar.bz2" -C "$BOOT" | output
    else
        fetch -b "$WS/kernel.tar.xz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
        mkdir -p "$WS/linux"
        tar -xf "$WS/kernel.tar.xz" -C "$WS/linux" --strip-components=1

        info "configure kernel"
        kernel_config > "$WS/linux/.config"

        info "compile kernel"
        make -C "$WS/linux" bzImage -j"$J" V=1 2>&1 | output

        info "install kernel"
        cp "$WS/linux/arch/x86/boot/bzImage" "$BOOT/bzImage"

        tar -cvjf "$WS/kernel.tar.bz2" -C "$BOOT" . | output
        put_cache "$WS/kernel.tar.bz2"
    fi
}
