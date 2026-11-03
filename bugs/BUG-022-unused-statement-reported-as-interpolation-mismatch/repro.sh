#!/usr/bin/env bash
# Reproduces BUG-022: a call used as a statement whose value is a Str is
# reported as a type mismatch between the values interpolated into a string
# in another function, and the statement itself is never named.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-022-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp Main.roc "$work/"
cd "$work"

echo "roc version: $(roc version)"
out=$(timeout 120 roc check Main.roc 2>&1) || true
echo "$out"

if echo "$out" | grep -Fq 'The values interpolated into this string must all have the same type.' &&
    ! echo "$out" | grep -Fq "This expression produces a value, but it's not being used."; then
    echo "BUG REPRODUCED: the unused Str statement is reported as an interpolation mismatch"
    exit 0
fi

if echo "$out" | grep -Fq "This expression produces a value, but it's not being used."; then
    echo "BUG NOT REPRODUCED: roc check reports the unused value"
    exit 1
fi

echo "BUG NOT REPRODUCED or unexpected output"
exit 1
