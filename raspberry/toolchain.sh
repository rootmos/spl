export TARGET=arm-linux-musleabihf

TWS=$WS/toolchain
mkdir -p "$TWS"

TOOLCHAIN_PREFIX=${TOOLCHAIN_PREFIX-$TWS/root}
export PATH=$TOOLCHAIN_PREFIX/bin:$PATH

if ! command -v "$TARGET-as" > /dev/null; then
    fetch "$TWS/binutils.tar.bz2" \
        "https://ftpmirror.gnu.org/binutils/binutils-2.33.1.tar.bz2" \
        "0cb4843da15a65a953907c96bad658283f3c4419d6bcc56bf2789db16306adb2"
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
    fetch "$TWS/gcc1.tar.xz" \
        "https://ftpmirror.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz" \
        "ea6ef08f121239da5695f76c9b33637a118dcf63e24164422231917fa61fb206"
    mkdir -p "$TWS/gcc1/build"
    xzcat "$TWS/gcc1.tar.xz" | tar -xf- -C "$TWS/gcc1" --strip-components=1 | output
    info "configure gcc (phase 1)"
    (cd "$TWS/gcc1/build" && ../configure \
        --target="$TARGET" --prefix="$TWS/phase1" --with-sysroot="$TOOLCHAIN_PREFIX" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c --without-headers \
        --disable-libmudflap \
        --disable-nls \
        --disable-libsanitizer \
        --disable-gold \
        --disable-libstdcxx \
        --disable-multilib) 2>&1 | output

    info "compile gcc (phase 1)"
    for t in all-gcc all-target-libgcc install-gcc install-target-libgcc; do
        make -C "$TWS/gcc1/build" -j"$J" "$t" 2>&1 | output
    done

    fetch "$TWS/musl.tar.gz" \
        "https://www.musl-libc.org/releases/musl-1.1.24.tar.gz" \
        "1370c9a812b2cf2a7d92802510cca0058cc37e66a7bedd70051f0a34015022a3"
    mkdir -p "$TWS/musl/build"
    tar xf "$TWS/musl.tar.gz" -C "$TWS/musl" --strip-components=1 | output
    (cd "$TWS/musl/build" && env \
        CROSS_COMPILE="$TARGET-" ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX/usr" \
        --syslibdir="$TOOLCHAIN_PREFIX/lib"
    ) | output
    make -C "$TWS/musl/build" -j"$J" 2>&1 | output
    make -C "$TWS/musl/build" -j"$J" install 2>&1 | output

    fetch "$WS/kernel-headers.tar.gz" \
        "https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_1.20190925-1.tar.gz" \
        "295651137abfaf3f1817d49051815a5eb0cc197d0100003d10e46f5eb0f45173"
    mkdir -p "$WS/linux-headers"
    tar xf "$WS/kernel-headers.tar.gz" -C "$WS/linux-headers" --strip-components=1 | output
    make -C "$WS/linux-headers" ARCH=arm CROSS_COMPILE="$TARGET-" \
        INSTALL_HDR_PATH="$TOOLCHAIN_PREFIX/usr" headers_install

    fetch "$TWS/gcc2.tar.xz" \
        "https://ftpmirror.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz" \
        "ea6ef08f121239da5695f76c9b33637a118dcf63e24164422231917fa61fb206"
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
