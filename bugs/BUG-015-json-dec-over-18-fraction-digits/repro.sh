#!/usr/bin/env bash
# Reproduces BUG-015: Json.parse and Dec.from_str reject a valid decimal with
# more than 18 fraction digits instead of rounding it to Dec's precision.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-015-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp main.roc "$work/"
cd "$work"

echo "roc version: $(roc version)"
out=$(roc main.roc 2>&1) || true
echo "$out"

if echo "$out" | grep -Fq '18 places: Ok({ c: 0.011101999999999999 })' &&
    echo "$out" | grep -Fq '19 places: Err(InvalidJson("Invalid JSON"))' &&
    echo "$out" | grep -Fq 'Dec.from_str: Err(BadNumStr)'; then
    echo "BUG REPRODUCED: a 19-fraction-digit decimal is rejected"
    exit 0
fi
echo "BUG NOT REPRODUCED or unexpected output"
exit 1
