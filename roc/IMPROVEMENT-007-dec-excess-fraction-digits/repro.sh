#!/usr/bin/env bash
# Json.parse and Dec.from_str reject a decimal with more than 18 fraction
# digits instead of rounding it to Dec's precision.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/dec-digits-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
cp Main.roc "$HOME/"
cd "$HOME"

echo "roc version: $(roc version)"
out=$(roc test Main.roc 2>&1) || true
echo "$out"

if echo "$out" | grep -Fq '[dbg] Err(InvalidJson("Invalid JSON"))' &&
    echo "$out" | grep -Fq '[dbg] Err(BadNumStr)' &&
    echo "$out" | grep -Fq '1 passed' &&
    echo "$out" | grep -Fq '2 failed'; then
    echo "REPRODUCED: a 19-fraction-digit decimal is rejected"
    exit 0
fi
echo "NOT REPRODUCED or unexpected output"
exit 1
