ncurses_install() {
    fetch -b "$WS/ncurses.tar.gz" \
        "https://ftpmirror.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz" \
        "aa057eeeb4a14d470101eff4597d5833dcef5965331be3528c08d99cebaa0d17"
    mkdir -p "$WS/ncurses/build"
    tar xf "$WS/ncurses.tar.gz" -C "$WS/ncurses" --strip-components=1 | output

    patch -p1 -d "$WS/ncurses" <<EOF | output
diff -ur a/configure b/configure
--- a/configure	2018-01-20 01:27:18.000000000 +0100
+++ b/configure	2019-12-17 09:37:10.084927329 +0100
@@ -13716,7 +13716,7 @@

 if test "\$with_stripping" = yes
 then
-	INSTALL_OPT_S="-s"
+	INSTALL_OPT_S="-s --strip-program=$TARGET-strip"
 else
 	INSTALL_OPT_S=
 fi
EOF

    info "configuring ncurses"
    (cd "$WS/ncurses/build" && ../configure \
        --prefix="$TOOLCHAIN_PREFIX" --host="$TARGET" --exec-prefix="$1/usr" \
        --enable-pc-files --with-pkg-config-libdir="$PKG_CONFIG_PATH" \
        --disable-nls --without-manpages \
        --enable-widec \
        --with-shared --with-cxx-shared \
        ) 2>&1 | output

    info "building ncurses"
    make -C "$WS/ncurses/build" -j"$J" 2>&1 V=1 | output
    make -C "$WS/ncurses/build" -j"$J" install 2>&1 | output
}
