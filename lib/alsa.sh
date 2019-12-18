ALSA_MIRROR=ftp://ftp.alsa-project.org/pub
ALSA_VERSION=1.2.1

alsa_lib_install() {
    fetch -b "$WS/alsa-lib.tar.bz2" \
        "$ALSA_MIRROR/lib/alsa-lib-$ALSA_VERSION.tar.bz2" \
        "9f0dff1b1e8fcb68034c8cb043bcdc398138c4b5d951e86990cfe890fbadc7cf"
    mkdir -p "$WS/alsa-lib/build"
    tar xf "$WS/alsa-lib.tar.bz2" -C "$WS/alsa-lib" --strip-components=1 | output
    info "configuring alsa-lib"
    (cd "$WS/alsa-lib/build" && ../configure --help) | output # TODO: remove
    (cd "$WS/alsa-lib/build" && env CC="$TARGET-gcc" ../configure \
        --prefix="$1" --host="$TARGET" \
        --disable-python --disable-alisp \
        --disable-old-symbols) | output
    info "building alsa-lib"
    make -C "$WS/alsa-lib/build" -j"$J" 2>&1 V=1 | output
    make -C "$WS/alsa-lib/build" -j"$J" install-strip 2>&1 | output
}

alsa_utils_install() {
    fetch -b "$WS/alsa-utils.tar.bz2" \
        "$ALSA_MIRROR/utils/alsa-utils-$ALSA_VERSION.tar.bz2" \
        "0b110ba71ef41d3009db1bc4dcae0cf79efb99cb5426fa19d0312470560a2c0d"
    mkdir -p "$WS/alsa-utils/build"
    tar xf "$WS/alsa-utils.tar.bz2" -C "$WS/alsa-utils" --strip-components=1 | output
    info "configuring alsa-utils"
    (cd "$WS/alsa-utils/build" && ../configure --help) | output # TODO: remove
    PKG_CONFIG_PATH="$1/lib/pkgconfig" "$TOOLCHAIN_PREFIX/bin/$TARGET-pkg-config" --list-all
    exit 0
    (cd "$WS/alsa-utils/build" && env \
        PKG_CONFIG="$TOOLCHAIN_PREFIX/bin/$TARGET-pkg-config" \
        CC="$TARGET-gcc" PKG_CONFIG_PATH="$1/lib/pkgconfig" \
        ../configure --prefix="$1" --host="$TARGET"\
        --with-alsa-prefix="$1/lib" \
        --with-alsa-inc-prefix="$1/include" \
        --with-udev-rules-dir=/lib/udev/rules.d \
        --with-systemdsystemunitdir= \
        ) | output
    info "building alsa-utils"
    make -C "$WS/alsa-utils/build" -j"$J" 2>&1 V=1 | output
    make -C "$WS/alsa-utils/build" -j"$J" install-strip 2>&1 | output
}
