#!/usr/bin/env bash
# Reproduces BUG-016: two calls of one method on a value whose type is
# inferred are given a single type, so their differing results are merged.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-016-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp main.roc "$work/"
cd "$work"

echo "roc version: $(roc version)"
out=$(roc check main.roc 2>&1) || true
echo "$out"

if echo "$out" | grep -Fq '[Count(U64), Name(U64)]'; then
    echo "BUG REPRODUCED: the two keep_oks calls share one payload type"
    exit 0
fi
echo "BUG NOT REPRODUCED or unexpected output"
exit 1
