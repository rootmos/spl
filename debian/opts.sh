VERBOSE=${VERBOSE-}
SUDO=${SUDO-}
RELEASE=buster
PKGs=
SIZE_MB=512
ROOT=
while getopts "vg:r:p:o:R:h:s:S:" OPT; do
    case $OPT in
        v) VERBOSE=1 ;;
        g) GRUB_CFG=$OPTARG ;;
        r) RELEASE=$OPTARG ;;
        p) PKGs="$PKGs $OPTARG" ;;
        o) OUT=$OPTARG ;;
        R) ROOT=$OPTARG ;;
        h) HOST=$OPTARG ;;
        s) SITE=$OPTARG ;;
        S) SIZE_MB=$OPTARG ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

[ -z "${HOST-}" ] && HOST=$RELEASE
