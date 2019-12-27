#!/bin/bash

set -o nounset -o pipefail -o errexit

# parse options
VERBOSE=${VERBOSE-}
RELEASE=buster
SYSTEM_PKGs=systemd,udev
PKGs=
SIZE_MB=512
ROOT=
FIRST_BOOT_TIMEOUT=10m
EXTRA_QEMU_OPTS=
GRUB_DST_DIR=boot/grub
KERNEL_DST_DIR=/boot
while getopts "k:K:vg:r:p:i:R:h:s:S:Q:m" OPT; do
    case $OPT in
        v) VERBOSE=1 ;;
        k) KERNEL=$OPTARG ;;
        K) KERNEL_TARBALL=$OPTARG ;;
        m) MENUCONFIG=1 ;;
        r) RELEASE=$OPTARG ;;
        R) ROOT=$OPTARG ;;
        g) GRUB_CFG=$OPTARG ;;
        i) IMG=$OPTARG ;;
        p) PKGs="$PKGs $OPTARG" ;;
        h) HOST=$OPTARG ;;
        s) SITE=$OPTARG ;;
        S) SIZE_MB=$OPTARG ;;
        Q) EXTRA_QEMU_OPTS="$EXTRA_QEMU_OPTS $OPTARG" ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

# tmp
TMP=$(mktemp -d .debian.XXXXXX)
clean() {
    if command -v gpgconf 1>/dev/null 2>&1 ; then
        gpgconf --homedir="$TMP/.gnupg" --kill gpg-agent
    fi

    rm -rf "$TMP"
}
trap clean EXIT

# output helpers
info() {
    echo 1>&2 "-- $*"
}

output() {
    if [ -n "$VERBOSE" ]; then
        cat
    else
        cat > "$TMP/log"
    fi
}

# kernel
if [[ ! -v KERNEL ]]; then
    KERNEL=$TMP/linux/arch/x86/boot/bzImage
fi

kernel_config() {
    base64 -d <<EOF | zcat
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
EOF
}

if [ ! -f "$KERNEL" ]; then
    if [[ ! -v KERNEL_TARBALL ]]; then
        KERNEL_TARBALL=$TMP/linux.tar
    fi

    MIRROR=https://cdn.kernel.org/pub/linux/kernel
    TARBALL_PATH=v5.x/linux-5.2.14.tar

    if [ ! -f "$KERNEL_TARBALL" ]; then
        info "preparing root: fetching kernel sources"
        wget --no-verbose -O- "$MIRROR/$TARBALL_PATH.xz" 2>/dev/null | xzcat > "$KERNEL_TARBALL"
    fi

    wget --no-verbose -O"$KERNEL_TARBALL.sign" "$MIRROR/$TARBALL_PATH.sign" 2>/dev/null

    info "preparing root: verifying kernel sources"
    # https://www.kernel.org/category/signatures.html
    KEYS="38DBBDC86092693E DEA66FF797772CDC E7BFC8EC95861109"
    _gpg() {
        gpg --homedir="$TMP" "$@" | output
    }
    _gpg --recv-keys "$KEYS" 2>&1 | output
    _gpg "$(for k in $KEYS; do echo --trusted-key "$k"; done)" \
        --verify "$KERNEL_TARBALL.sign" "$KERNEL_TARBALL" 2>&1 | output

    info "preparing root: extracting kernel sources"
    mkdir -p "$TMP/linux"
    tar -xf"$KERNEL_TARBALL" -C "$TMP/linux" --strip-components=1

    info "preparing root: building kernel"
    if [[ -v KERNEL_CONFIG ]]; then
        cp "$KERNEL_CONFIG" "$TMP/linux/.config"
        if [ -n "${MENUCONFIG-}" ]; then
            make -C "$TMP/linux" menuconfig < /dev/tty
            cp "$TMP/linux/.config" "$KERNEL_CONFIG"
        fi
    else
        kernel_config > "$TMP/linux/.config"
    fi
    make -C "$TMP/linux" bzImage -j$((2*$(nproc))) 2>&1 | output
    if [ "$TMP/linux/arch/x86/boot/bzImage" != "$KERNEL" ]; then
        cp "$TMP/linux/arch/x86/boot/bzImage" "$KERNEL"
    fi
fi

# root
if [ -z "$ROOT" ]; then
    ROOT=$TMP/root
fi

if [ ! -d "$ROOT" ]; then
    info "preparing root: bootstraping Debian ($RELEASE)"
    debootstrap --variant=minbase --include="$SYSTEM_PKGs" "$RELEASE" "$ROOT" | output
fi

if [[ -v SITE ]]; then
    info "preparing root: installing site files"
    tar -cf- -C "$SITE" . | tar -xf- -C "$ROOT"
fi

[[ ! -v HOST ]] && HOST=$RELEASE
info "preparing root: setting hostname ($HOST)"
echo "$HOST" > "$ROOT/etc/hostname"

info "preparing root: set up networking"
ln -sf "/usr/lib/systemd/system/systemd-networkd-wait-online.service" "$ROOT/usr/lib/systemd/system/multi-user.target.wants"

mkdir -p "$ROOT/usr/lib/systemd/system/systemd-networkd.service.d"
cat <<EOF > "$ROOT/usr/lib/systemd/system/systemd-networkd.service.d/after-udev.conf"
[Service]
ExecStartPre=/sbin/udevadm settle
EOF

cat <<EOF > "$ROOT/etc/systemd/network/dhcp.network"
[Match]
Name=*

[Network]
DHCP=ipv4

[DHCP]
UseDNS=yes
EOF

info "preparing root: configuring resolvers"
cat <<EOF > "$ROOT/etc/resolv.conf"
nameserver 1.1.1.1
EOF

info "preparing root: configuring initial systemd target"
cat <<EOF > "$ROOT/usr/lib/systemd/system/install.target"
[Unit]
Description=Installation
Requires=multi-user.target
AllowIsolate=yes
EOF
ln -sf "/usr/lib/systemd/system/install.target" "$ROOT/usr/lib/systemd/system/default.target"

info "preparing root: configuring journald"
cat <<EOF > "$ROOT/etc/systemd/journald.conf"
[Journal]
ForwardToConsole=yes
MaxLevelConsole=debug
EOF

info "preparing root: disabling getty"
find "$ROOT/etc/systemd/system/getty.target.wants" -type l -delete
find "$ROOT/usr/lib/systemd/system/getty.target.wants" -type l -delete
find "$ROOT/usr/lib/systemd/system/multi-user.target.wants" -name "getty.target" -type l -delete

info "preparing root: configure install-site unit"
mkdir -p "$ROOT/usr/lib/systemd/system/install.target.wants"
ln -sf "/usr/lib/systemd/system/install-site.service" "$ROOT/usr/lib/systemd/system/install.target.wants"

cat <<EOF > "$ROOT/usr/lib/systemd/system/install-site.service"
[Unit]
Description=Site specific installation
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh /usr/local/bin/install-site.wrapper.sh
EOF

INSTALLATION_TOKEN=$(uuidgen)
cat <<EOF > "$ROOT/INSTALL_SITE_CANARY"
If this file is found in a live system then the installation has failed.
$INSTALLATION_TOKEN
EOF

cat <<EOF > "$ROOT/usr/local/bin/install-site.wrapper.sh"
#!/bin/sh

set -o errexit

info() {
    echo 1>&2 "-- \$@"
}

error() {
    echo 1>&2 "!! \$@"
}

info "installing packages: $PKGs"
apt-get update
apt-get install -o DPkg::Options::="--force-confold" -y $PKGs

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
cat <<FOE > "/$GRUB_DST_DIR/grub.cfg"
linux $KERNEL_DST_DIR/$(basename "$KERNEL") root=/dev/sda1 rw console=ttyS0,38400n8d init=/bin/systemd systemd.show_status=0 net.ifnames=0
boot
FOE

info "finished site installation: \$(tail -n+2 /INSTALL_SITE_CANARY)"
rm /INSTALL_SITE_CANARY

info "rebooting"
systemctl reboot 2>/dev/null
EOF
chmod +x "$ROOT/usr/local/bin/install-site.wrapper.sh"


# grub
GRUB_FMT=i386-pc
GRUB_SRC_DIR=/usr/lib/grub/$GRUB_FMT
GRUB_MODULES="linux boot crypto bufio extcmd vbe video video_fb relocator mmap"
GRUB_MODULES="$GRUB_MODULES normal terminal gettext"
if [ "$(grub-mkimage --version | cut -f3 -d ' ')" == "2.04" ]; then
    GRUB_MODULES="$GRUB_MODULES verifiers"
fi

info "preparing root: installing GRUB modules"
for m in $GRUB_MODULES; do
    install -m 644 -D -t "$ROOT/$GRUB_DST_DIR/$GRUB_FMT" "$GRUB_SRC_DIR/$m.mod"
done

if [[ -v GRUB_CFG ]]; then
    info "preparing root: GRUB_CFG=$GRUB_CFG"
    install -m 644 -D -t "$ROOT/$GRUB_DST_DIR" "$GRUB_CFG"
else
    info "preparing root: default GRUB config"

    cat <<EOF > "$ROOT/$GRUB_DST_DIR/grub.cfg"
linux $KERNEL_DST_DIR/$(basename "$KERNEL") root=/dev/sda1 root=/dev/vda1 rw console=ttyS0,38400n8d console=hvc0 init=/bin/systemd systemd.show_status=0 net.ifnames=0
boot
EOF
fi

info "preparing root: installing kernel"
install -m 644 -D -t "$ROOT$KERNEL_DST_DIR" "$KERNEL"


# image
info "creating filesystem root.img (containing $(du -sh "$ROOT" | cut -f1) of data)"
dd if=/dev/zero of="$TMP/root.img" bs=1K count="$((SIZE_MB-1))K" 2>&1 | output
mke2fs -t ext4 -d "$ROOT" "$TMP/root.img" "$((SIZE_MB-1))m" 2>&1 | output

info "building core.img"
cat <<EOF > "$TMP/grub.early.cfg"
insmod $GRUB_MODULES
EOF
grub-mkimage -o "$TMP/core.img" -O "$GRUB_FMT" \
    -c "$TMP/grub.early.cfg" \
    -p "(hd0,msdos1)/$GRUB_DST_DIR" \
    part_msdos ext2 biosdisk

info "formatting (${SIZE_MB}M): $IMG"
dd if=/dev/zero of="$IMG" bs=1K count="${SIZE_MB}K" 2>&1 | output
sfdisk "$IMG" <<< "2048,,L,*" | output

info "installing MBR: $GRUB_SRC_DIR/boot.img"
dd if="$GRUB_SRC_DIR/boot.img" of="$IMG" bs=446 count=1 conv=notrunc 2>&1 | output
info "installing core.img"
dd if="$TMP/core.img" of="$IMG" bs=512 seek=1 conv=notrunc 2>&1 | output
info "installing root.img"
dd if="$TMP/root.img" of="$IMG" bs=512 seek=2048 conv=notrunc 2>&1 | output

info "running first boot"
timeout --foreground "$FIRST_BOOT_TIMEOUT" qemu-system-x86_64 \
    -smp cpus="$(nproc)" -m 1024 \
    -no-reboot \
    -drive format=raw,file="$IMG",if=virtio \
    -chardev stdio,id=stdio,mux=on,signal=on \
    -device virtio-serial-pci -device virtconsole,chardev=stdio \
    -display none -nic user,model=virtio-net-pci \
    -device virtio-rng-pci \
    "$EXTRA_QEMU_OPTS" | tee "$TMP/log" | output

grep -cq "$INSTALLATION_TOKEN" "$TMP/log"
