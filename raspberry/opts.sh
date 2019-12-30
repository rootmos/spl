SUDO=${SUDO-}
while getopts "vc:Sj:l:d:o:K:-sDT:" OPT; do
    case $OPT in
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
