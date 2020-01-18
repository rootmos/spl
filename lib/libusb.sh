libusb_install() {
    fetch -b "$WS/libusb.tar.bz2" \
        "https://github.com/libusb/libusb/releases/download/v1.0.23/libusb-1.0.23.tar.bz2" \
        "db11c06e958a82dac52cf3c65cb4dd2c3f339c8a988665110e0d24d19312ad8d"

    mkdir -p "$WS/libusb/build"
    tar xf "$WS/libusb.tar.bz2" -C "$WS/libusb" --strip-components=1 | output

    info "configuring libusb"
    (cd "$WS/libusb/build" && ../configure \
        --disable-udev --prefix="/usr" \
        --host="$TARGET" ) | output

    info "building libusb"
    make -C "$WS/libusb/build" -j"$J" 2>&1 V=1 | output
    make -C "$WS/libusb/build" -j"$J" DESTDIR="$TOOLCHAIN_ROOT" install-strip 2>&1 | output
    make -C "$WS/libusb/build" -j"$J" DESTDIR="$1" install-strip 2>&1 | output
}
