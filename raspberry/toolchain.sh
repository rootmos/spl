export TARGET=arm-linux-musleabihf
BARE=arm-none-eabihf

TWS=$WS/toolchain
mkdir -p "$TWS"

TOOLCHAIN_ROOT=${TOOLCHAIN_PREFIX-$TWS/root}
TOOLCHAIN_PREFIX=$TOOLCHAIN_ROOT/usr
export PATH=$TOOLCHAIN_PREFIX/bin:$PATH

if ! command -v "$BARE-as" > /dev/null; then
    fetch -b "$TWS/binutils-bare.tar.bz2" "$BINUTILS_URL" "$BINUTILS_SHA256"
    mkdir -p "$TWS/binutils-bare/build"
    tar xf "$TWS/binutils-bare.tar.bz2" -C "$TWS/binutils-bare" --strip-components=1 | output
    info "configuring binutils ($BARE)"
    (cd "$TWS/binutils-bare/build" && ../configure \
        --target="$BARE" --prefix="$TOOLCHAIN_PREFIX" --with-sysroot \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --disable-multilib --disable-nls) 2>&1 | output
    info "building binutils ($BARE)"
    make -C "$TWS/binutils-bare/build" -j"$J" 2>&1 | output
    make -C "$TWS/binutils-bare/build" -j"$J" install-strip 2>&1 | output
fi

if ! command -v "$BARE-gcc" > /dev/null; then
    fetch -b "$TWS/gcc-bare.tar.xz" "$GCC_URL" "$GCC_SHA256"
    mkdir -p "$TWS/gcc-bare/build"
    xzcat "$TWS/gcc-bare.tar.xz" | tar -xf- -C "$TWS/gcc-bare" --strip-components=1 | output
    info "configuring gcc ($BARE)"
    (cd "$TWS/gcc-bare/build" && ../configure \
        --target="$BARE" --prefix="$TOOLCHAIN_PREFIX" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c --without-headers \
        --disable-nls --disable-multilib) 2>&1 | output

    for t in all-gcc all-target-libgcc install-strip-gcc install-strip-target-libgcc; do
        info "building gcc ($BARE: $t)"
        make -C "$TWS/gcc-bare/build" -j"$J" "$t" 2>&1 | output
    done
fi

if [ ! -f "$TOOLCHAIN_PREFIX/include/linux/version.h" ]; then
    fetch -b "$WS/kernel-headers.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux-headers"
    tar xf "$WS/kernel-headers.tar.gz" -C "$WS/linux-headers" --strip-components=1 | output
    info "installing kernel headers"
    make -C "$WS/linux-headers" ARCH=arm CROSS_COMPILE="$BARE-" \
        INSTALL_HDR_PATH="$TOOLCHAIN_PREFIX" headers_install | output
fi

if [ ! -f "$TOOLCHAIN_PREFIX/include/stddef.h" ]; then
    fetch -b "$TWS/musl.tar.gz" "$MUSL_URL" "$MUSL_SHA256"
    mkdir -p "$TWS/musl/build"
    tar xf "$TWS/musl.tar.gz" -C "$TWS/musl" --strip-components=1 | output
    info "configuring musl libc"
    (cd "$TWS/musl/build" && ../configure \
        --target="$BARE" --prefix="$TOOLCHAIN_PREFIX" \
        --syslibdir="$TOOLCHAIN_ROOT/lib"
    ) | output
    info "building musl libc"
    make -C "$TWS/musl/build" -j"$J" 2>&1 | output
    make -C "$TWS/musl/build" -j"$J" install 2>&1 | output
fi

if ! command -v "$TARGET-as" > /dev/null; then
    fetch -b "$TWS/binutils-target.tar.bz2" "$BINUTILS_URL" "$BINUTILS_SHA256"
    mkdir -p "$TWS/binutils-target/build"
    tar xf "$TWS/binutils-target.tar.bz2" -C "$TWS/binutils-target" --strip-components=1 | output
    info "configuring binutils ($TARGET)"
    (cd "$TWS/binutils-target/build" && ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" --with-sysroot \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --disable-multilib --disable-nls) 2>&1 | output
    info "building binutils ($TARGET)"
    make -C "$TWS/binutils-target/build" -j"$J" 2>&1 | output
    make -C "$TWS/binutils-target/build" -j"$J" install-strip 2>&1 | output
fi

if ! command -v "$TARGET-gcc" > /dev/null; then
    fetch -b "$TWS/gcc-target.tar.xz" "$GCC_URL" "$GCC_SHA256"
    mkdir -p "$TWS/gcc-target/build"
    xzcat "$TWS/gcc-target.tar.xz" | tar -xf- -C "$TWS/gcc-target" --strip-components=1 | output
    info "configuhing gcc ($TARGET)"
    (cd "$TWS/gcc-target/build" && ../configure --target="$TARGET" \
        --prefix="$TOOLCHAIN_PREFIX" --with-sysroot="$TOOLCHAIN_ROOT" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c \
        --disable-nls --disable-multilib) 2>&1 | output

    for t in all-gcc all-target-libgcc install-strip-gcc install-strip-target-libgcc; do
        info "building gcc ($TARGET: $t)"
        make -C "$TWS/gcc-target/build" -j"$J" "$t" 2>&1 | output
    done
fi

if ! command -v gen_init_cpio > /dev/null; then
    fetch -b "$WS/linux-utils.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux-utils"
    tar xf "$WS/linux-utils.tar.gz" -C "$WS/linux-utils" --wildcards linux-*/usr/* \
        --strip-components=1 | output
    make -C "$WS/linux-utils/usr" gen_init_cpio 2>&1 | output
    install -m 755 -D -t "$TOOLCHAIN_PREFIX/bin" \
        "$WS/linux-utils/usr/gen_init_cpio"
fi
