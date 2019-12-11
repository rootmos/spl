APP=${1-app}
SIZE_MB=${SIZE_MB-40}

BOOTCODE_URL=https://github.com/raspberrypi/firmware/raw/9f4983548584d4f70e6eec5270125de93a081483/boot/bootcode.bin
BOOTCODE_SHA256=6505bbc8798698bd8f1dff30789b22289ebb865ccba7833b87705264525cbe46

ROOT=$WS/root
mkdir -p "$ROOT"

BOOTCODE=$ROOT/bootcode.bin
fetch "$BOOTCODE" "$BOOTCODE_URL" "$BOOTCODE_SHA256"

info "patching bootcode: BOOT_UART=1"
sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" "$BOOTCODE"

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

if [ -n "${BLKDEV-}" ]; then
    info "burn image"
    $SUDO dd bs=4M if="$IMG" of="$BLKDEV" conv=fsync
fi
