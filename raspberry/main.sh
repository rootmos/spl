if [ ! -b "${BLKDEV-}" ] && [ -z "${OUT-}" ]; then
    if [ -z "${QEMU-}" ]; then
        error "neither a block device nor an output file was specified"
    fi
fi

SIZE_MB=${SIZE_MB-50}

ROOT=$WS/root
BOOT=$WS/boot
mkdir -p "$ROOT" "$BOOT"
TOOLCHAIN_ROOT=$WS/toolchain
toolchain "$TOOLCHAIN_ROOT"
source "$TOOLCHAIN_ROOT"/.env

# kernel
kernel_install "$BOOT"

# userland
busybox_install "$ROOT"

should_install_pkg() {
    [ -f "${SITE-/dev/null}/.pkg" ] && grep -cq "^$1" "$SITE/.pkg"
}

if should_install_pkg ncurses; then
    ncurses_install "$ROOT"
fi

if should_install_pkg alsa-lib; then
    alsa_lib_install "$ROOT"
fi

if should_install_pkg alsa-utils; then
    alsa_utils_install "$ROOT"
fi

if [ -n "${SITE-}" ]; then
    info "installing site files"
    tar -cf- -C "$SITE" . | tar -xf- -C "$ROOT"
fi

info "install runtime"
toolchain_install_runtime "$ROOT"

info "create root initramfs"
initramfs_list "$ROOT" | tee "$WS/root.list" | output
initramfs_mk "$WS/root.cpio.gz" < "$WS/root.list"

if [ -n "${QEMU-}" ]; then
    QEMU_TARGET=qemu-system-$(cut -d- -f1 <<< "$TARGET")
    info "running $QEMU_TARGET"
    "$QEMU_TARGET" -machine virt -cpu cortex-a53 \
        -kernel "$BOOT/kernel.img" -initrd "$WS/root.cpio.gz" \
        -append "console=hvc0 root=/dev/ram0" \
        -chardev stdio,id=stdio,mux=on,signal=on \
        -device virtio-serial-pci -device virtconsole,chardev=stdio \
        -display none
    exit $?
fi

# firmware
FIRMWARE_COMMIT=0c01dbefba45a08c47f8538d5a071a0fba6b7e83

BOOTCODE_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/bootcode.bin
BOOTCODE_SHA256=6505bbc8798698bd8f1dff30789b22289ebb865ccba7833b87705264525cbe46

START_ELF_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/start.elf
START_ELF_SHA256=442919907e4b7d8f007b79df1aa1e12f98e09ab393da65b48cd2b2af04301b7d

FIXUP_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/fixup.dat
FIXUP_SHA256=85a54bf460aa3ff0d04ee54bc606bf3af39a2c5194e519ab278cf74ecf75f7a8

BOOTCODE=$BOOT/bootcode.bin
fetch "$BOOTCODE" "$BOOTCODE_URL" "$BOOTCODE_SHA256"

info "patching bootcode: BOOT_UART=1"
sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" "$BOOTCODE"

fetch "$BOOT/start.elf" "$START_ELF_URL" "$START_ELF_SHA256"
fetch "$BOOT/fixup.dat" "$FIXUP_URL" "$FIXUP_SHA256"

info "configure boot procedure"
cat <<EOF > "$BOOT/cmdline.txt"
console=serial0,115200 root=/dev/ram0 init=/sbin/init
EOF
cat <<EOF > "$BOOT/config.txt"
start_file=start.elf
fixup_file=fixup.dat
cmdline=cmdline.txt
initramfs root.cpio.gz followkernel
kernel=kernel.img
EOF
if [ "$RPI_VERSION" = "3" ]; then
    cat <<EOF >> "$BOOT/config.txt"
dtoverlay=disable-bt
arm_64bit=1
EOF
fi

info "creating filesystem"
dd if=/dev/zero of="$WS/boot.img" bs=1K count="$((SIZE_MB-1))K" 2>&1 | output
mkfs.fat "$WS/boot.img" | output

info "mount filesystem"
MNT=$WS/mnt
_clean_main() {
    $SUDO umount "$MNT"
}
mkdir -p "$MNT"
$SUDO mount -o loop "$WS/boot.img" "$MNT"

info "populate boot filesystem "
$SUDO cp "$WS/root.cpio.gz" "$BOOT"
info "boot filesystem size: $(du -sh "$BOOT" | cut -f1)"
$SUDO rsync -rv "$BOOT"/ "$MNT" | output

info "unmount filesystem"
sync "$MNT"
$SUDO umount "$MNT"
_clean_main() {
    true
}

IMG=$WS/app.img
info "formatting (${SIZE_MB}M)"
dd if=/dev/zero of="$IMG" bs=1K count="${SIZE_MB}K" 2>&1 | output
sfdisk "$IMG" <<< "2048,,c,*" | output

info "installing filesystem image"
dd if="$WS/boot.img" of="$IMG" bs=512 seek=2048 conv=notrunc 2>&1 | output

if [ -b "${BLKDEV-}" ]; then
    info "burn image"
    $SUDO dd bs=4M if="$IMG" of="$BLKDEV" conv=fsync 2>&1 | output
fi

if [ -n "${OUT-}" ]; then
    info "copying final image"
    cp "$IMG" "$OUT"
fi
