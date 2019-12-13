kernel_menuconfig() {
    fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux"
    tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

    kernel_config > "$WS/linux/.config"
    make -C "$WS/linux" ARCH=arm CROSS_COMPILE="$TARGET-" menuconfig
    cp "$WS/linux/.config" "$1"
}

kernel_install() {
    BOOT=$1
    if is_cached "${KERNEL_SHA256-}"; then
        info "install kernel (cached)"
        borrow_cached "$KERNEL_SHA256" "$WS/kernel.tar.bz2"
        tar -xvf "$WS/kernel.tar.bz2" -C "$BOOT" | output
    else
        fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
        mkdir -p "$WS/linux"
        tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

        info "configure kernel"
        kernel_config > "$WS/linux/.config"
        if [ -n "${MENUCONFIG-}" ]; then
            make -C "$WS/linux" ARCH=arm CROSS_COMPILE="$TARGET-" menuconfig
            cp "$WS/linux/.config" "$MENUCONFIG"
            exit 0
        fi

        info "compile kernel"
        make -C "$WS/linux" ARCH=arm CROSS_COMPILE="$TARGET-" V=1 \
            zImage dtbs -j"$((2*$(nproc)))" 2>&1 | output

        info "install kernel"
        cp "$WS/linux/arch/arm/boot/zImage" "$BOOT/kernel.img"
        cp "$WS/linux/arch/arm/boot/dts"/*.dtb "$BOOT"
        mkdir -p "$BOOT/overlays"
        cp "$WS/linux/arch/arm/boot/dts/overlays"/*.dtb* "$BOOT/overlays/"
        cp "$WS/linux/arch/arm/boot/dts/overlays/README" "$BOOT/overlays/"
        tar -cvjf "$WS/kernel.tar.bz2" -C "$BOOT" . | output
        put_cache "$WS/kernel.tar.bz2"
    fi
}
