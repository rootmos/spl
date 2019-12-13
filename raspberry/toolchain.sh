export TARGET=arm-linux-musleabihf

TWS=$WS/toolchain
mkdir -p "$TWS"

TOOLCHAIN_PREFIX=${TOOLCHAIN_PREFIX-$TWS/root}
export PATH=$TOOLCHAIN_PREFIX/bin:$PATH

if ! command -v "$TARGET-as" > /dev/null; then
    fetch -b "$TWS/binutils.tar.bz2" "$BINUTILS_URL" "$BINUTILS_SHA256"
    mkdir -p "$TWS/binutils/build"
    tar xf "$TWS/binutils.tar.bz2" -C "$TWS/binutils" --strip-components=1 | output
    info "configure binutils"
    (cd "$TWS/binutils/build" && ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" --with-sysroot \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --disable-multilib --disable-nls) 2>&1 | output
    info "compile binutils"
    make -C "$TWS/binutils/build" -j"$J" 2>&1 | output
    make -C "$TWS/binutils/build" -j"$J" install-strip 2>&1 | output
fi

if ! command -v "$TARGET-gcc" > /dev/null; then
    fetch -b "$TWS/gcc1.tar.xz" "$GCC_URL" "$GCC_SHA256"
    mkdir -p "$TWS/gcc1/build"
    xzcat "$TWS/gcc1.tar.xz" | tar -xf- -C "$TWS/gcc1" --strip-components=1 | output
    info "configure gcc (phase 1)"
    (cd "$TWS/gcc1/build" && ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c --without-headers \
        --disable-libmudflap \
        --disable-nls \
        --disable-libsanitizer \
        --disable-gold \
        --disable-libstdcxx \
        --disable-multilib) 2>&1 | output

    info "compile gcc (phase 1)"
    for t in all-gcc install-gcc; do
        make -C "$TWS/gcc1/build" -j"$J" "$t" 2>&1 | output
    done

    fetch -b "$WS/kernel-headers.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux-headers"
    tar xf "$WS/kernel-headers.tar.gz" -C "$WS/linux-headers" --strip-components=1 | output
    make -C "$WS/linux-headers" ARCH=arm CROSS_COMPILE="$TARGET-" \
        INSTALL_HDR_PATH="$TOOLCHAIN_PREFIX/usr" headers_install

    fetch -b "$TWS/musl.tar.gz" "$MUSL_URL" "$MUSL_SHA256"
    mkdir -p "$TWS/musl/build"
    tar xf "$TWS/musl.tar.gz" -C "$TWS/musl" --strip-components=1 | output
    (cd "$TWS/musl/build" && env \
        CROSS_COMPILE="$TARGET-" ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX/usr" \
        --syslibdir="$TOOLCHAIN_PREFIX/lib"
    ) | output
    make -C "$TWS/musl/build" -j"$J" 2>&1 | output
    make -C "$TWS/musl/build" -j"$J" install 2>&1 | output

    fetch -b "$TWS/gcc2.tar.xz" "$GCC_URL" "$GCC_SHA256"
    mkdir -p "$TWS/gcc2/build"
    xzcat "$TWS/gcc2.tar.xz" | tar -xf- -C "$TWS/gcc2" --strip-components=1 | output
    info "configure gcc (phase 2)"
    (cd "$TWS/gcc2/build" && ../configure --target="$TARGET" \
        --prefix="$TOOLCHAIN_PREFIX" --with-sysroot="$TOOLCHAIN_PREFIX" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c \
        --disable-libmudflap \
        --disable-nls \
        --disable-libsanitizer \
        --disable-gold \
        --disable-libstdcxx \
        --disable-multilib) 2>&1 | output

    info "compile gcc (phase 2)"
    for t in all-gcc all-target-libgcc install-gcc install-target-libgcc; do
        make -C "$TWS/gcc2/build" -j"$J" "$t" 2>&1 | output
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
