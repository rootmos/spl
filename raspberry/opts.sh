SUDO=${SUDO-}
RPI_VERSION=${RPI_VERSION-3}
ACTION=build
while getopts "13vc:Sj:l:d:o:K:-s:DT:bxu:" OPT; do
    case $OPT in
        1) RPI_VERSION=1 ;;
        3) RPI_VERSION=3 ;;
        D) DEBUG_SHELL=1 ;;
        v) VERBOSE=1 ;;
        c) CACHE=$OPTARG ;;
        s) SITE=$OPTARG ;;
        S) SUDO=sudo ;;
        j) J=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        d) BLKDEV=$OPTARG ;;
        o) OUT=$OPTARG ;;
        K) KERNEL_SHA256=$OPTARG ;;
        T) TOOLCHAIN_SHA256=$OPTARG ;;
        b) ACTION=build ;;
        x) ACTION=run_with_env ;;
        u) USERSPACE_HOOK=$OPTARG ;;
        -) break ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

if [ "$RPI_VERSION" = "1" ]; then
    export ARCH=arm
    export TARGET=arm-linux-musleabihf
elif [ "$RPI_VERSION" = "3" ]; then
    export ARCH=arm64
    export TARGET=aarch64-linux-muslhf
else
    error "unsupported Raspberry Pi version: $RPI_VERSION"
fi
