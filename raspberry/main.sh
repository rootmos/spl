APP=${1-app}
SIZE_MB=${SIZE_MB-20}

BOOTCODE_URL=https://github.com/raspberrypi/firmware/raw/9f4983548584d4f70e6eec5270125de93a081483/boot/bootcode.bin
BOOTCODE_SHA256=6505bbc8798698bd8f1dff30789b22289ebb865ccba7833b87705264525cbe46

START_ELF_URL=https://github.com/raspberrypi/firmware/raw/9d6be5b07e81bdfb9c4b9a560e90fbc7477fdc6e/boot/start.elf
START_ELF_SHA256=42736b4b32af51945cf11855e3ce9b6b167f6dc26c5dcb9bf03949b8a99517e2

FIXUP_URL=https://github.com/raspberrypi/firmware/raw/601d36df3aa541560e4cf9b571105d20db2b4b7c/boot/fixup.dat
FIXUP_SHA256=cdf2600ce1376cfea219f359495845b4e68596274e4bc12ad3661b78617cbcd0

KERNEL_SRC_URL=https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_1.20190925-1.tar.gz
KERNEL_SRC_SHA256=295651137abfaf3f1817d49051815a5eb0cc197d0100003d10e46f5eb0f45173

ROOT=$WS/root
mkdir -p "$ROOT"

fetch "$WS/kernel.tar.gz" "$KERNEL_SRC_URL" "$KERNEL_SRC_SHA256"
mkdir -p "$WS/linux"
tar xf "$WS/kernel.tar.gz" -C "$WS/linux" --strip-components=1 | output

info "configure kernel"
kernel_config > "$WS/linux/.config"
if [ -n "${MENUCONFIG-}" ]; then
    make -C "$WS/linux" ARCH=arm CROSS_COMPILE="$TARGET-" menuconfig
    cp "$WS/linux/.config" "$MENUCONFIG"
    exit 0
fi

info "compile kernel"
make -C "$WS/linux" ARCH=arm CROSS_COMPILE="$TARGET-" V=1 \
    zImage dtbs -j"$((2*$(nproc)))" 2>&1 | output

info "install kernel"
cp "$WS/linux/arch/arm/boot/zImage" "$ROOT/kernel.img"
cp "$WS/linux/arch/arm/boot/dts"/*.dtb "$ROOT"
mkdir -p "$ROOT/overlays"
cp "$WS/linux/arch/arm/boot/dts/overlays"/*.dtb* "$ROOT/overlays/"
cp "$WS/linux/arch/arm/boot/dts/overlays/README" "$ROOT/overlays/"

BOOTCODE=$ROOT/bootcode.bin
fetch "$BOOTCODE" "$BOOTCODE_URL" "$BOOTCODE_SHA256"

info "patching bootcode: BOOT_UART=1"
sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" "$BOOTCODE"

fetch "$ROOT/start.elf" "$START_ELF_URL" "$START_ELF_SHA256"
fetch "$ROOT/fixup.dat" "$FIXUP_URL" "$FIXUP_SHA256"

info "configure boot procedure"
cat <<EOF > "$ROOT/cmdline.txt"
console=serial0,115200 console=tty1
EOF
cat <<EOF > "$ROOT/config.txt"
start_file=start.elf
fixup_file=fixup.dat
kernel=kernel.img
cmdline=cmdline.txt
EOF

info "creating filesystem filesystem (containing $(du -sh "$ROOT" | cut -f1) of data)"
dd if=/dev/zero of="$WS/root.img" bs=1K count="$((SIZE_MB-1))K" 2>&1 | output
mkfs.fat "$WS/root.img" | output

info "mount filesystem"
MNT=$WS/mnt
_clean_main() {
    $SUDO umount "$MNT"
}
mkdir -p "$MNT"
$SUDO mount -o loop "$WS/root.img" "$MNT"

info "populate filesystem"
$SUDO rsync -rv "$ROOT"/ "$MNT" | output

info "unmount filesystem"
$SUDO umount "$MNT"
_clean_main() {
    true
}

IMG=$WS/$APP.img
info "formatting (${SIZE_MB}M)"
dd if=/dev/zero of="$IMG" bs=1K count="${SIZE_MB}K" 2>&1 | output
sfdisk "$IMG" <<< "2048,,c,*" | output

info "installing filesystem image"
dd if="$WS/root.img" of="$IMG" bs=512 seek=2048 conv=notrunc 2>&1 | output

if [ -b "${BLKDEV-}" ]; then
    info "burn image"
    $SUDO dd bs=4M if="$IMG" of="$BLKDEV" conv=fsync 2>&1 | output
fi
