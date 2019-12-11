TARGET=arm-none-eabihf

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
        --disable-multilib --disable-nls) | output
    info "compile binutils"
    make -C "$TWS/binutils/build" -j"$J" 2>&1 | output
    make -C "$TWS/binutils/build" -j"$J" install-strip 2>&1 | output
fi

if ! command -v "$TARGET-gcc" > /dev/null; then
    fetch "$TWS/gcc.tar.xz" \
        "https://ftpmirror.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz" \
        "ea6ef08f121239da5695f76c9b33637a118dcf63e24164422231917fa61fb206"
    mkdir -p "$TWS/gcc/build"
    xzcat "$TWS/gcc.tar.xz" | tar -xf- -C "$TWS/gcc" --strip-components=1 | output
    info "configure gcc"
    (cd "$TWS/gcc/build" && ../configure \
        --target="$TARGET" --prefix="$TOOLCHAIN_PREFIX" \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --enable-languages=c --without-headers \
        --disable-multilib --disable-nls) | output

    info "compile gcc"
    for t in all-gcc all-target-libgcc install-gcc install-target-libgcc; do
        make -C "$TWS/gcc/build" -j"$J" "$t" 2>&1 | output
    done
fi
