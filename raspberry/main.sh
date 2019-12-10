BOOTCODE_URL=https://github.com/raspberrypi/firmware/raw/9f4983548584d4f70e6eec5270125de93a081483/boot/bootcode.bin
BOOTCODE_SHA256=6505bbc8798698bd8f1dff30789b22289ebb865ccba7833b87705264525cbe46
BOOTCODE=$WS/bootcode.bin

fetch "$BOOTCODE" "$BOOTCODE_URL" "$BOOTCODE_SHA256"

info "patching bootcode: BOOT_UART=1"
sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" "$BOOTCODE"
