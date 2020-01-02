toolchain_env() {
    TOOLCHAIN_ROOT=$(readlink -f "$1")
    TOOLCHAIN_PREFIX=$TOOLCHAIN_ROOT/usr
    TARGET=$(cat "$TOOLCHAIN_ROOT"/.target)
    cat <<EOF
export PATH=$TOOLCHAIN_PREFIX/bin:\$PATH
export HOSTCC=${HOSTCC-gcc} HOSTLD=${HOSTLD-ld}
export LD=$TARGET-ld
export AS=$TARGET-as
export CC=$TARGET-gcc CFLAGS="--sysroot=$TOOLCHAIN_ROOT"
export CPP=$TARGET-cpp CPPFLAGS="--sysroot=$TOOLCHAIN_ROOT"
export CXX=$TARGET-g++ CXXFLAGS="--sysroot=$TOOLCHAIN_ROOT"
export PKG_CONFIG=$TOOLCHAIN_PREFIX/bin/$TARGET-pkg-config
export PKG_CONFIG_PATH=$TOOLCHAIN_PREFIX/lib/pkgconfig
EOF
}

toolchain_configure_gcc() {
    (cd "$1" && env \
        AR_FOR_TARGET="$TARGET-ar" \
        AS_FOR_TARGET="$TARGET-as" \
        LD_FOR_TARGET="$TARGET-ld" \
        NM_FOR_TARGET="$TARGET-nm" \
        OBJCOPY_FOR_TARGET="$TARGET-objcopy" \
        OBJDUMP_FOR_TARGET="$TARGET-objdump" \
        RANLIB_FOR_TARGET="$TARGET-ranlib" \
        READELF_FOR_TARGET="$TARGET-readelf" \
        STRIP_FOR_TARGET="$TARGET-strip" \
        "$GCC_SRC/configure" \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        --with-sysroot=/ \
        --with-build-sysroot="$TOOLCHAIN_ROOT" \
        --enable-languages=c,c++ \
        --disable-nls --disable-multilib \
        --disable-libquadmath \
        --disable-libmudflap --disable-libsanitizer \
        --disable-libmpx \
        --without-isl \
        2>&1 ) | output
}

toolchain() {
    TOOLCHAIN_ROOT=$1
    if is_cached "${TOOLCHAIN_SHA256-}"; then
        info "installing toolchain ($TARGET, cached: $TOOLCHAIN_SHA256)"
        borrow_cached "$TOOLCHAIN_SHA256" "$WS/toolchain.tar.bz2"
        mkdir -p "$TOOLCHAIN_ROOT"
        tar -xvf "$WS/toolchain.tar.bz2" -C "$TOOLCHAIN_ROOT" | output
        toolchain_env "$TOOLCHAIN_ROOT" > "$TOOLCHAIN_ROOT"/.env

        if [ "$ARCH" != "$(cat "$TOOLCHAIN_ROOT/.arch")" ]; then
            error "incorrect arch pulled from cache:" \
                "$ARCH != $(cat "$TOOLCHAIN_ROOT/.arch")"
        fi

        if [ "$KERNEL_ARCH" != "$(cat "$TOOLCHAIN_ROOT/.kernel_arch")" ]; then
            error "incorrect kernel arch pulled from cache:" \
                "$KERNEL_ARCH != $(cat "$TOOLCHAIN_ROOT/.kernel_arch")"
        fi

        if [ "$TARGET" != "$(cat "$TOOLCHAIN_ROOT/.target")" ]; then
            error "incorrect target pulled from cache:" \
                "$TARGET != $(cat "$TOOLCHAIN_ROOT/.target")"
        fi
        return
    fi

    mkdir "$TOOLCHAIN_ROOT"
    TWS=$(mktemp --tmpdir="$TMP" --directory toolchain.XXXXXX)

    # NB make sure the following is compatible with toolchain_env above
    TOOLCHAIN_PREFIX=$TOOLCHAIN_ROOT/usr
    export PATH=$TOOLCHAIN_PREFIX/bin:$PATH

    info "building toolchain ($TARGET)"

    fetch -b "$TWS/binutils.tar.bz2" "$BINUTILS_URL" "$BINUTILS_SHA256"
    BINUTILS_SRC=$TWS/binutils_src
    mkdir -p "$BINUTILS_SRC"
    tar xf "$TWS/binutils.tar.bz2" -C "$BINUTILS_SRC" --strip-components=1 | output
    info "configuring binutils"
    BINUTILS_BUILD=$TWS/binutils_build
    mkdir -p "$BINUTILS_BUILD"
    (cd "$BINUTILS_BUILD" && "$BINUTILS_SRC/configure" \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        --disable-multilib --disable-nls \
        --enable-deterministic-archives) 2>&1 | output
    info "building binutils"
    make -C "$BINUTILS_BUILD" -j"$J" 2>&1 | output
    make -C "$BINUTILS_BUILD" -j"$J" install-strip 2>&1 | output

    fetch -b "$TWS/gcc.tar.xz" "$GCC_URL" "$GCC_SHA256"
    GCC_SRC=$TWS/gcc_src
    mkdir -p "$GCC_SRC"
    xzcat "$TWS/gcc.tar.xz" | tar -xf- -C "$GCC_SRC" --strip-components=1 | output
    info "configuring gcc"
    GCC_BUILD1=$TWS/gcc_build1
    mkdir -p "$GCC_BUILD1"
    toolchain_configure_gcc "$GCC_BUILD1"

    info "building xgcc"
    mkdir -p "$TOOLCHAIN_ROOT/usr/include"
    make -C "$GCC_BUILD1" -j"$J" all-gcc 2>&1 | output
    XGCC="$GCC_BUILD1/gcc/xgcc -B $GCC_BUILD1/gcc"
    LIBCC="$GCC_BUILD1/$TARGET/libgcc/libgcc.a"

    fetch -b "$TWS/musl.tar.gz" "$MUSL_URL" "$MUSL_SHA256"
    MUSL_SRC=$TWS/musl_src
    mkdir -p "$MUSL_SRC"
    tar xf "$TWS/musl.tar.gz" -C "$MUSL_SRC" --strip-components=1 | output
    info "configuring musl libc"
    MUSL_BUILD=$TWS/musl_build
    mkdir -p "$MUSL_BUILD"
    (cd "$MUSL_BUILD" && env CC="$XGCC" LIBCC="$LIBCC" \
        "$MUSL_SRC/configure" --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        ) | output

    info "installing musl libc headers"
    make -C "$MUSL_BUILD" -j"$J" AR="$TARGET-ar" RANLIB="$TARGET-ranlib" install-headers 2>&1 | output

    info "building libgcc"
    make -C "$GCC_BUILD1" -j"$J" enable_shared=no all-target-libgcc 2>&1 | output

    info "building musl libc"
    make -C "$MUSL_BUILD" -j"$J" AR="$TARGET-ar" RANLIB="$TARGET-ranlib" install 2>&1 | output

    fetch -b "$TWS/kernel-headers.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$TWS/linux-headers"
    tar xf "$TWS/kernel-headers.tar.gz" -C "$TWS/linux-headers" --strip-components=1 | output
    make -C "$TWS/linux-headers" ARCH="$KERNEL_ARCH" CC="$XGCC" LIBCC="$LIBCC" \
        INSTALL_HDR_PATH="$TOOLCHAIN_PREFIX" headers_install | output

    info "building gcc"
    GCC_BUILD2=$TWS/gcc_build2
    mkdir -p "$GCC_BUILD2"
    toolchain_configure_gcc "$GCC_BUILD2"
    make -C "$GCC_BUILD2" -j"$J" 2>&1 | output
    make -C "$GCC_BUILD2" -j"$J" install-strip 2>&1 | output

    fetch -b "$TWS/linux-utils.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$TWS/linux-utils"
    tar xf "$TWS/linux-utils.tar.gz" -C "$TWS/linux-utils" --wildcards linux-*/usr/* \
        --strip-components=1 | output
    make -C "$TWS/linux-utils/usr" gen_init_cpio 2>&1 | output
    install -m 755 -D -t "$TOOLCHAIN_PREFIX/bin" \
        "$TWS/linux-utils/usr/gen_init_cpio"

    fetch -b "$TWS/pkg-config.tar.gz" "$PKG_CONFIG_URL" "$PKG_CONFIG_SHA256"
    PKG_CONFIG_BUILD=$TWS/pkg-config_build
    PKG_CONFIG_SRC=$TWS/pkg-config_src
    mkdir -p "$PKG_CONFIG_SRC" "$PKG_CONFIG_BUILD"
    tar xf "$TWS/pkg-config.tar.gz" -C "$PKG_CONFIG_SRC" --strip-components=1 | output
    info "configuring pkg-config"
    (cd "$PKG_CONFIG_BUILD" && "$PKG_CONFIG_SRC/configure" \
        --prefix="$TOOLCHAIN_PREFIX" \
        --program-prefix="$TARGET-" --disable-host-tool \
        --with-pc-path= \
        ) 2>&1 | output
    info "building pkg-config"
    make -C "$PKG_CONFIG_BUILD" -j"$J" 2>&1 V=1 | output
    make -C "$PKG_CONFIG_BUILD" -j"$J" install-strip 2>&1 | output

    echo "$TARGET" > "$TOOLCHAIN_ROOT"/.target
    echo "$ARCH" > "$TOOLCHAIN_ROOT"/.arch
    echo "$KERNEL_ARCH" > "$TOOLCHAIN_ROOT"/.kernel_arch

    tar -cvjf "$WS/toolchain.tar.bz2" -C "$TOOLCHAIN_ROOT" . | output
    put_cache "$WS/toolchain.tar.bz2"

    toolchain_env "$TOOLCHAIN_ROOT" > "$TOOLCHAIN_ROOT"/.env
}
