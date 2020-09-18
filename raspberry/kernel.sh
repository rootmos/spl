kernel_menuconfig() {
    TOOLCHAIN_ROOT=$WS/root
    toolchain "$TOOLCHAIN_ROOT"
    source "$TOOLCHAIN_ROOT"/.env

    fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
    mkdir -p "$WS/linux"
    tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

    "kernel${RPI_VERSION}_config" > "$WS/linux/.config"
    make -C "$WS/linux" CROSS_COMPILE="$TARGET-" menuconfig
    cp "$WS/linux/.config" "$1"
}

kernel_install() {
    BOOT=$1
    if is_cached "${KERNEL_SHA256-}"; then
        info "install kernel (cached: $KERNEL_SHA256)"
        borrow_cached "$KERNEL_SHA256" "$WS/kernel.tar.bz2"
        tar -xvf "$WS/kernel.tar.bz2" -C "$BOOT" | output
    else
        fetch -b "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
        mkdir -p "$WS/linux"
        tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

        patch -p1 -d "$WS/linux" <<EOF
diff -ru a/net/ipv4/ipconfig.c b/net/ipv4/ipconfig.c
--- a/net/ipv4/ipconfig.c	2019-09-24 19:28:42.000000000 +0200
+++ b/net/ipv4/ipconfig.c	2020-01-18 17:38:06.141419443 +0100
@@ -85,7 +85,7 @@
 
 /* Define the friendly delay before and after opening net devices */
 #define CONF_POST_OPEN		10	/* After opening: 10 msecs */
-#define CONF_CARRIER_TIMEOUT	120000	/* Wait for carrier timeout */
+#define CONF_CARRIER_TIMEOUT	1000	/* Wait for carrier timeout */
 
 /* Define the timeout for waiting for a DHCP/BOOTP/RARP reply */
 #define CONF_OPEN_RETRIES 	2	/* (Re)open devices twice */
@@ -93,7 +93,7 @@
 #define CONF_BASE_TIMEOUT	(HZ*2)	/* Initial timeout: 2 seconds */
 #define CONF_TIMEOUT_RANDOM	(HZ)	/* Maximum amount of randomization */
 #define CONF_TIMEOUT_MULT	*7/4	/* Rate of timeout growth */
-#define CONF_TIMEOUT_MAX	(HZ*30)	/* Maximum allowed timeout */
+#define CONF_TIMEOUT_MAX	(HZ)	/* Maximum allowed timeout */
 #define CONF_NAMESERVERS_MAX   3       /* Maximum number of nameservers
 					   - '3' from resolv.h */
 #define CONF_NTP_SERVERS_MAX   3	/* Maximum number of NTP servers */
Only in b/net/ipv4: .ipconfig.c.swp
EOF

        patch -p1 -d "$WS/linux" <<EOF
diff -ru a/scripts/dtc/dtc-lexer.l b/scripts/dtc/dtc-lexer.l
--- a/scripts/dtc/dtc-lexer.l	2020-09-18 16:47:48.390462120 +0200
+++ b/scripts/dtc/dtc-lexer.l	2020-09-18 16:48:25.726702951 +0200
@@ -38,7 +38,6 @@
 #include "srcpos.h"
 #include "dtc-parser.tab.h"
 
-YYLTYPE yylloc;
 extern bool treesource_error;
 
 /* CAUTION: this will stop working if we ever use yyless() or yyunput() */
EOF

        info "configure kernel"
        "kernel${RPI_VERSION}_config" > "$WS/linux/.config"

        info "compile kernel"
        case "$RPI_VERSION" in
            1) KERNEL=zImage; DTB_PREFIX= ;;
            3) KERNEL=Image; DTB_PREFIX=/broadcom ;;
        esac
        make -C "$WS/linux" CROSS_COMPILE="$TARGET-" V=1 \
            "$KERNEL" dtbs -j"$J" 2>&1 | output

        info "install kernel"
        "$WS/linux/scripts/mkknlimg" \
            "$WS/linux/arch/$ARCH/boot/$KERNEL" "$BOOT/kernel.img" \
            | output
        cp "$WS/linux/arch/$ARCH/boot/dts$DTB_PREFIX"/*.dtb "$BOOT"
        mkdir -p "$BOOT/overlays"
        cp "$WS/linux/arch/$ARCH/boot/dts/overlays"/*.dtbo "$BOOT/overlays/"
        cp "$WS/linux/arch/$ARCH/boot/dts/overlays/README" "$BOOT/overlays/"
        tar -cvjf "$WS/kernel.tar.bz2" -C "$BOOT" . | output
        put_cache "$WS/kernel.tar.bz2"
    fi
}
