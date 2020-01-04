#!/bin/bash

set -o nounset -o pipefail -o errexit

SCRIPT_DIR=$(readlink -f "$0" | xargs dirname)
ACTION=collect
OUT=
while getopts "do:-" OPT; do
    case $OPT in
        d) ACTION=dependencies ;;
        o) OUT=$OPTARG ;;
        ?) exit 2 ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${OUT-}" ]; then
    OUT=${1-/dev/stdout}
fi

suffix() {
    sed '/.*\.\w\+$/!d;s/\w\+\.\([a-zA-Z0-9.]\+\)$/\1/' <<< "$(basename "$1")"
}

if [ "$ACTION" = "dependencies" ]; then
    cp /dev/null "$OUT"
    while read -r LINE; do
        readarray -t ARGS <<< "$(sh -c 'for a in '"$LINE"'; do echo "$a"; done')"
        OPTIND=1
        SKIP=0
        while getopts "f:l:" OPT "${ARGS[@]}"; do
            case "$OPT" in
                f) ;;
                l) SKIP=1 ;;
                ?) exit 2 ;;
            esac
        done
        if [ "$SKIP" -ne 1 ]; then
            echo "${ARGS[$((OPTIND-1))]}" >> "$OUT"
        fi
    done
    exit 0
fi

if [ ! "$ACTION" = "collect" ]; then
    echo "don't know how to execute action: $ACTION" 1>&2
    exit 1
fi

cat <<EOF > "$OUT"
#!/bin/bash
# generated: $(date -Is)"

set -o nounset -o pipefail -o errexit
EOF
chmod +x "$OUT"

while read -r LINE; do
    readarray -t ARGS <<< "$(sh -c 'for a in '"$LINE"'; do echo "$a"; done')"
    FUNCTION_NAME=
    LITERAL=
    OPTIND=1
    while getopts "f:l:" OPT "${ARGS[@]}"; do
        case "$OPT" in
            f) FUNCTION_NAME=$OPTARG ;;
            l) LITERAL=$OPTARG ;;
            ?) exit 2 ;;
        esac
    done
    if [ "$OPTIND" -eq "${#ARGS[@]}" ]; then
        IN=${ARGS[$((OPTIND-1))]}
    fi

    if [ -n "$FUNCTION_NAME" ]; then
        "$SCRIPT_DIR/bundle.sh" "$FUNCTION_NAME" < "$IN" >> "$OUT"
    elif [ -n "$LITERAL" ]; then
        echo "$LITERAL" >> "$OUT"
    else
        MIME_TYPE=$(file --brief --mime-type "$IN")
        SUFFIX=$(suffix "$IN")
        if [ "$MIME_TYPE" = "text/x-shellscript" ] \
            || [ "$SUFFIX" = "sh" ]; then
            ( echo "";  echo "# $IN" ) >> "$OUT"
            cat "$IN" >> "$OUT"
        else
            echo "don't know what to do with: $IN" 1>&2
            exit 1
        fi
    fi
done
