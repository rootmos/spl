#!/bin/bash

set -o nounset -o pipefail -o errexit

WS=$(mktemp -d)
trap 'rm -rf "$WS"' EXIT

TMP=$WS/tmp
mkdir -p "$TMP"
