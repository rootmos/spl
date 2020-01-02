kernel_menuconfig() {
    TOOLCHAIN_ROOT=$WS/root
    toolchain "$TOOLCHAIN_ROOT"
    source "$TOOLCHAIN_ROOT"/.env

    fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux"
    tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

    kernel_config > "$WS/linux/.config"
    make -C "$WS/linux" ARCH="$KERNEL_ARCH" CROSS_COMPILE="$TARGET-" menuconfig
    cp "$WS/linux/.config" "$1"
}

kernel_install() {
    BOOT=$1
    if is_cached "${KERNEL_SHA256-}"; then
        info "install kernel (cached: $KERNEL_SHA256)"
        borrow_cached "$KERNEL_SHA256" "$WS/kernel.tar.bz2"
        tar -xvf "$WS/kernel.tar.bz2" -C "$BOOT" | output
    else
        fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
        mkdir -p "$WS/linux"
        tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

        info "configure kernel"
        kernel_config > "$WS/linux/.config"

        info "compile kernel"
        make -C "$WS/linux" ARCH="$KERNEL_ARCH" CROSS_COMPILE="$TARGET-" \
            Image dtbs -j"$J" 2>&1 | output

        info "install kernel"
        #"$WS/linux/scripts/mkknlimg" --283x \
        "$WS/linux/scripts/mkknlimg" \
            "$WS/linux/arch/$KERNEL_ARCH/boot/Image" "$BOOT/kernel.img" \
            | output
        cp "$WS/linux/arch/$KERNEL_ARCH/boot/dts/broadcom"/*.dtb "$BOOT"
        mkdir -p "$BOOT/overlays"
        cp "$WS/linux/arch/$KERNEL_ARCH/boot/dts/overlays"/*.dtbo "$BOOT/overlays/"
        cp "$WS/linux/arch/$KERNEL_ARCH/boot/dts/overlays/README" "$BOOT/overlays/"
        tar -cvjf "$WS/kernel.tar.bz2" -C "$BOOT" . | output
        put_cache "$WS/kernel.tar.bz2"
    fi
}
