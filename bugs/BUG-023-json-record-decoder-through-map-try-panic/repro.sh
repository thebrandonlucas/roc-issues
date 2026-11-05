#!/usr/bin/env bash
# Reproduces BUG-023: `roc check` panics with "instantiation widened a closed
# tag union" when an unannotated function that decodes a record with
# `Json.parse(...)?` is passed to `List.map_try`, whose result `main!` unwraps
# with `?`.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-023-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp main.roc "$work/"
cd "$work"

echo "roc version: $(roc version)"
out=$(timeout 300 roc check main.roc 2>&1) || true
echo "$out"

if echo "$out" | grep -Fq 'panic: compiler bug: instantiation widened a closed tag union'; then
    echo "BUG REPRODUCED: roc check panics"
    exit 0
fi

if echo "$out" | grep -Eq '0 errors|No errors found'; then
    echo "BUG NOT REPRODUCED: roc check passed"
    exit 1
fi

echo "BUG NOT REPRODUCED or unexpected output"
exit 1
