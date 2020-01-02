SUDO=${SUDO-}
QEMU=0
RPI_VERSION=${RPI_VERSION-3}
while getopts "13vc:Sj:l:d:o:K:-s:DT:" OPT; do
    case $OPT in
        1) RPI_VERSION=1 ;;
        3) RPI_VERSION=3 ;;
        D) DEBUG_SHELL=1 ;;
        v) VERBOSE=1 ;;
        c) CACHE=${OPTARG:-$HOME/.cache/spl} ;;
        s) SITE=$OPTARG ;;
        S) SUDO=sudo ;;
        j) J=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        d) BLKDEV=$OPTARG ;;
        o) OUT=$OPTARG ;;
        K) KERNEL_SHA256=$OPTARG ;;
        T) TOOLCHAIN_SHA256=$OPTARG ;;
        -) break ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

if [ "$RPI_VERSION" = "3" ]; then
    export ARCH=arm64
    export TARGET=aarch64-linux-musl
else
    error "unsupported Raspberry Pi version: $RPI_VERSION"
fi
