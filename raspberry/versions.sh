# toolchain
BINUTILS_URL=https://ftpmirror.gnu.org/binutils/binutils-2.33.1.tar.bz2
BINUTILS_SHA256=0cb4843da15a65a953907c96bad658283f3c4419d6bcc56bf2789db16306adb2

GCC_URL=https://ftpmirror.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz
GCC_SHA256=ea6ef08f121239da5695f76c9b33637a118dcf63e24164422231917fa61fb206

MUSL_URL=https://www.musl-libc.org/releases/musl-1.1.24.tar.gz
MUSL_SHA256=1370c9a812b2cf2a7d92802510cca0058cc37e66a7bedd70051f0a34015022a3

KERNEL_SRC_URL=https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_1.20190925-1.tar.gz
KERNEL_SRC_SHA256=295651137abfaf3f1817d49051815a5eb0cc197d0100003d10e46f5eb0f45173

# firmware
FIRMWARE_COMMIT=0c01dbefba45a08c47f8538d5a071a0fba6b7e83

BOOTCODE_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/bootcode.bin
BOOTCODE_SHA256=6505bbc8798698bd8f1dff30789b22289ebb865ccba7833b87705264525cbe46

START_ELF_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/start.elf
START_ELF_SHA256=442919907e4b7d8f007b79df1aa1e12f98e09ab393da65b48cd2b2af04301b7d

FIXUP_URL=https://github.com/raspberrypi/firmware/raw/$FIRMWARE_COMMIT/boot/fixup.dat
FIXUP_SHA256=85a54bf460aa3ff0d04ee54bc606bf3af39a2c5194e519ab278cf74ecf75f7a8

# user-space
PKG_CONFIG_URL=https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
PKG_CONFIG_SHA256=6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591
