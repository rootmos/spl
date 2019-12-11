#!/bin/bash

set -o nounset -o pipefail -o errexit

cat <<FOE
$1() {
    base64 -d <<EOF | zcat
FOE

gzip -9 | base64 -w120

cat <<FOE
EOF
}
FOE
