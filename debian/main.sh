if [ -z "${OUT-}" ]; then
    error "output file not specified"
fi

ROOT=$WS/root
BOOT=$ROOT/boot
mkdir -p "$ROOT" "$BOOT"
_clean_main() {
    $SUDO rm -rf "$ROOT"
}

kernel_install "$BOOT"
$SUDO chown 0:0 -R "$BOOT"

info "bootstraping Debian ($RELEASE)"
$SUDO debootstrap --cache-dir="$CACHE" \
    --variant=minbase --include="systemd,udev" "$RELEASE" "$ROOT" | output

if [ -n "${SITE-}" ]; then
    info "installing site files"
    tar -cf- -C "$SITE" . | tar -xf- -C "$ROOT"
fi

info "setting hostname: $HOST"
echo "$HOST" | $SUDO tee "$ROOT/etc/hostname" | output

info "setting up network"
$SUDO ln -sf "/usr/lib/systemd/system/systemd-networkd-wait-online.service" \
    "$ROOT/usr/lib/systemd/system/multi-user.target.wants"

$SUDO mkdir -p "$ROOT/usr/lib/systemd/system/systemd-networkd.service.d"
$SUDO tee "$ROOT/usr/lib/systemd/system/systemd-networkd.service.d/after-udev.conf" <<EOF | output
[Service]
ExecStartPre=/sbin/udevadm settle
EOF

$SUDO tee "$ROOT/etc/systemd/network/dhcp.network" <<EOF | output
[Match]
Name=*

[Network]
DHCP=ipv4

[DHCP]
UseDNS=yes
EOF

info "configuring resolvers"
$SUDO tee "$ROOT/etc/resolv.conf" <<EOF | output
nameserver 1.1.1.1
EOF

info "configuring initial systemd target"
$SUDO tee "$ROOT/usr/lib/systemd/system/install.target" <<EOF | output
[Unit]
Description=Installation
Requires=multi-user.target
AllowIsolate=yes
EOF
$SUDO ln -sf "/usr/lib/systemd/system/install.target" \
    "$ROOT/usr/lib/systemd/system/default.target"

info "configuring journald"
$SUDO tee "$ROOT/etc/systemd/journald.conf" << EOF | output
[Journal]
ForwardToConsole=yes
MaxLevelConsole=debug
EOF

info "disabling getty"
$SUDO find "$ROOT/etc/systemd/system/getty.target.wants" -type l -delete
$SUDO find "$ROOT/usr/lib/systemd/system/getty.target.wants" -type l -delete
$SUDO find "$ROOT/usr/lib/systemd/system/multi-user.target.wants" -name "getty.target" -type l -delete

info "configure install-site unit"
$SUDO mkdir -p "$ROOT/usr/lib/systemd/system/install.target.wants"
$SUDO ln -sf "/usr/lib/systemd/system/install-site.service" \
    "$ROOT/usr/lib/systemd/system/install.target.wants"

$SUDO tee "$ROOT/usr/lib/systemd/system/install-site.service" <<EOF | output
[Unit]
Description=Site specific installation
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh /usr/local/bin/install-site.wrapper.sh
EOF

INSTALLATION_TOKEN=$(uuidgen)
$SUDO tee "$ROOT/INSTALL_SITE_CANARY" <<EOF | output
If this file is found in a live system then the installation has failed.
$INSTALLATION_TOKEN
EOF

$SUDO tee "$ROOT/usr/local/bin/install-site.wrapper.sh" <<EOF | output
#!/bin/sh

set -o errexit

info() {
    echo 1>&2 "-- \$@"
}

error() {
    echo 1>&2 "!! \$@"
}

EOF

if [ -n "${PKGs-}" ]; then
    $SUDO tee -a "$ROOT/usr/local/bin/install-site.wrapper.sh" <<EOF | output
info "installing packages: $PKGs"
apt-get update
apt-get install -o DPkg::Options::="--force-confold" -y $PKGs
EOF
fi

$SUDO tee -a "$ROOT/usr/local/bin/install-site.wrapper.sh" <<EOF | output
if [ -x /etc/install-site.sh ]; then
    info "beginning site installation"
    if /etc/install-site.sh; then
        info "finished site installation"
    else
        error "site installationh exited with non-zero status: \$?"
        systemctl reboot 2>/dev/null
    fi
fi

info "prepare for first real boot"
ln -sf "/usr/lib/systemd/system/multi-user.target" "/usr/lib/systemd/system/default.target"

rm "/usr/local/bin/install-site.wrapper.sh"
rm "/usr/lib/systemd/system/install-site.service"
rm "/usr/lib/systemd/system/install.target"
rm -rf "/usr/lib/systemd/system/install.target.wants"

info "configuring final grub config"
cat <<FOE > "/boot/grub.cfg"
linux /boot/bzImage root=/dev/sda1 rw console=ttyS0,38400n8d init=/bin/systemd systemd.show_status=0 net.ifnames=0
boot
FOE

info "finished site installation: \$(tail -n+2 /INSTALL_SITE_CANARY)"
rm /INSTALL_SITE_CANARY

info "rebooting"
systemctl reboot 2>/dev/null
EOF
$SUDO chmod +x "$ROOT/usr/local/bin/install-site.wrapper.sh"


# grub
GRUB_FMT=i386-pc
GRUB_SRC_DIR=/usr/lib/grub/$GRUB_FMT
GRUB_MODULES="linux boot crypto bufio extcmd vbe video video_fb relocator mmap"
GRUB_MODULES="$GRUB_MODULES normal terminal gettext"
if [ "$(grub-mkimage --version | cut -f3 -d ' ')" == "2.04" ]; then
    GRUB_MODULES="$GRUB_MODULES verifiers"
fi

info "installing GRUB modules"
for m in $GRUB_MODULES; do
    $SUDO install -m 644 -D -t "$BOOT/$GRUB_FMT" \
        "$GRUB_SRC_DIR/$m.mod"
done

if [ -n "${GRUB_CFG-}" ]; then
    info "installing GRUB config: $GRUB_CFG"
    $SUDO cp "$GRUB_CFG" "$BOOT/grub.cfg"
else
    info "installing GRUB config"
    $SUDO tee "$BOOT/grub.cfg" <<EOF | output
linux /boot/bzImage root=/dev/sda1 root=/dev/vda1 rw console=ttyS0,38400n8d console=hvc0 init=/bin/systemd systemd.show_status=0 net.ifnames=0
boot
EOF
fi

# image
info "creating filesystem root.img (containing $($SUDO du -sh "$ROOT" | cut -f1) of data)"
dd if=/dev/zero of="$WS/root.img" bs=1K count="$((SIZE_MB-1))K" 2>&1 | output
$SUDO mke2fs -t ext4 -d "$ROOT" "$WS/root.img" "$((SIZE_MB-1))m" 2>&1 | output

info "building core.img"
cat <<EOF > "$WS/grub.early.cfg"
insmod $GRUB_MODULES
EOF
grub-mkimage -o "$WS/core.img" -O "$GRUB_FMT" \
    -c "$WS/grub.early.cfg" \
    -p "(hd0,msdos1)/boot" \
    part_msdos ext2 biosdisk

IMG=$WS/app.img
info "formatting (${SIZE_MB}M)"
dd if=/dev/zero of="$IMG" bs=1K count="${SIZE_MB}K" 2>&1 | output
sfdisk "$IMG" <<< "2048,,L,*" | output

info "installing MBR: $GRUB_SRC_DIR/boot.img"
dd if="$GRUB_SRC_DIR/boot.img" of="$IMG" bs=446 count=1 conv=notrunc 2>&1 | output
info "installing core.img"
dd if="$WS/core.img" of="$IMG" bs=512 seek=1 conv=notrunc 2>&1 | output
info "installing root.img"
dd if="$WS/root.img" of="$IMG" bs=512 seek=2048 conv=notrunc 2>&1 | output

info "running first boot"
qemu-system-x86_64 \
    -smp cpus="$(nproc)" -m 1024 \
    -no-reboot \
    -drive format=raw,file="$IMG",if=virtio \
    -chardev stdio,id=stdio,mux=on,signal=on \
    -device virtio-serial-pci -device virtconsole,chardev=stdio \
    -display none -nic user,model=virtio-net-pci \
    -device virtio-rng-pci \
    | tee "$WS/first-boot-log" | output

grep -cq "$INSTALLATION_TOKEN" "$WS/first-boot-log"

info "copying final image"
cp "$IMG" "$OUT"
