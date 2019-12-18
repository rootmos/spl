toochain_env() {
    TOOLCHAIN_ROOT=$(readlink -f "$1")
    TOOLCHAIN_PREFIX=$TOOLCHAIN_ROOT/usr
    TARGET=$(cat "$TOOLCHAIN_ROOT"/.target)
    cat <<EOF
TARGET=$TARGET
export PATH=$TOOLCHAIN_PREFIX/bin:\$PATH
HOSTCC=${HOSTCC-gcc}
HOSTLD=${HOSTLD-ld}
CC=$TARGET-gcc
LD=$TARGET-ld
AS=$TARGET-as
CXX=$TARGET-g++
PKG_CONFIG=$TOOLCHAIN_PREFIX/bin/$TARGET-pkg-config
PKG_CONFIG_PATH=$TOOLCHAIN_PREFIX/lib/pkgconfig
EOF
}

toolchain() {
    TOOLCHAIN_ROOT=$1
    TOOLCHAIN_SHA256=${TOOLCHAIN_SHA256-${2-}}

    if is_cached "$TOOLCHAIN_SHA256"; then
        borrow_cached "$TOOLCHAIN_SHA256" "$WS/toolchain.tar.bz2"
        tar -xvf "$WS/toolchain.tar.bz2" -C "$TOOLCHAIN_ROOT" | output
        toolchain_env "$TOOLCHAIN_ROOT" > "$TOOLCHAIN_ROOT"/.env
        return
    fi

    TARGET=arm-linux-musleabihf
    BARE_TARGET=arm-none-eabihf
    mkdir "$TOOLCHAIN_ROOT"
    TWS=$(mktemp --tmpdir="$TMP" --directory toolchain.XXXXXX)
    BUILD_SYSROOT=$TWS/sys-root

    # NB make sure the following is compatible with toolchain_env above
    TOOLCHAIN_PREFIX=$TOOLCHAIN_ROOT/usr
    export PATH=$TOOLCHAIN_PREFIX/bin:$PATH

    info "building toolchain ($TARGET) ($(date -Is))"

    fetch -b "$TWS/binutils.tar.bz2" "$BINUTILS_URL" "$BINUTILS_SHA256"
    BINUTILS_SRC=$TWS/binutils_src
    mkdir -p "$BINUTILS_SRC"
    tar xf "$TWS/binutils.tar.bz2" -C "$BINUTILS_SRC" --strip-components=1 | output
    info "configuring binutils"
    BINUTILS_BUILD=$TWS/binutils_build
    mkdir -p "$BINUTILS_BUILD"
    (cd "$BINUTILS_BUILD" && "$BINUTILS_SRC/configure" \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        --with-sysroot=/ \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
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
    GCC_BUILD=$TWS/gcc_build
    mkdir -p "$GCC_BUILD"
    (cd "$GCC_BUILD" && env \
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
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c,c++ \
        --disable-nls --disable-multilib \
        --disable-libquadmath \
        --disable-libmudflap --disable-libsanitizer \
        --disable-libmpx \
        ) 2>&1 | output

    info "building xgcc"
    mkdir -p "$TOOLCHAIN_ROOT/usr/include"
    make -C "$GCC_BUILD" -j"$J" all-gcc 2>&1 | output
    XGCC="$GCC_BUILD/gcc/xgcc -B $GCC_BUILD/gcc"
    LIBCC="$GCC_BUILD/$TARGET/libgcc/libgcc.a"

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
    make -C "$GCC_BUILD" -j"$J" enable_shared=no all-target-libgcc 2>&1 | output

    info "building musl libc"
    make -C "$MUSL_BUILD" -j"$J" AR="$TARGET-ar" RANLIB="$TARGET-ranlib" install 2>&1 | output

    fetch -b "$TWS/kernel-headers.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$TWS/linux-headers"
    tar xf "$TWS/kernel-headers.tar.gz" -C "$TWS/linux-headers" --strip-components=1 | output
    make -C "$TWS/linux-headers" ARCH=arm CC="$XGCC" LIBCC="$LIBCC" \
        INSTALL_HDR_PATH="$TOOLCHAIN_PREFIX" headers_install | output

    info "building gcc"
    make -C "$GCC_BUILD" -j"$J" 2>&1 | output
    make -C "$GCC_BUILD" -j"$J" install-strip 2>&1 | output

    fetch -b "$TWS/linux-utils.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$TWS/linux-utils"
    tar xf "$TWS/linux-utils.tar.gz" -C "$TWS/linux-utils" --wildcards linux-*/usr/* \
        --strip-components=1 | output
    make -C "$TWS/linux-utils/usr" gen_init_cpio 2>&1 | output
    install -m 755 -D -t "$TOOLCHAIN_PREFIX/bin" \
        "$TWS/linux-utils/usr/gen_init_cpio"

    fetch -b "$TWS/pkg-config.tar.gz" "$PKG_CONFIG_URL" "$PKG_CONFIG_SHA256"
    mkdir -p "$TWS/pkg-config_build"
    tar xf "$TWS/pkg-config.tar.gz" -C "$TWS/pkg-config" --strip-components=1 | output
    info "configuring pkg-config"
    (cd "$TWS/pkg-config_build" && ../configure \
        --prefix="$TOOLCHAIN_PREFIX" \
        --program-prefix="$TARGET-" --disable-host-tool \
        --with-pc-path= \
        ) 2>&1 | output
    info "building pkg-config"
    make -C "$TWS/pkg-config_build" -j"$J" 2>&1 V=1 | output
    make -C "$TWS/pkg-config_build" -j"$J" install-strip 2>&1 | output

    tar -cvjf "$WS/toolchain.tar.bz2" -C "$TOOLCHAIN_ROOT" . | output
    put_cache "$WS/toolchain.tar.bz2"

    cat "$TARGET" > "$TOOLCHAIN_ROOT"/.target
    toolchain_env "$TOOLCHAIN_ROOT" > "$TOOLCHAIN_ROOT"/.env
}
