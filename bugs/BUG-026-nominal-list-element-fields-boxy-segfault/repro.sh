#!/usr/bin/env bash
# Reproduces BUG-026: `roc check` segfaults in boxy_lowering when a value of a
# nominal record type has list elements with the wrong fields, after another
# value of that type.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-026-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp Main.roc "$work/"
cd "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
if timeout 120 roc check Main.roc >"$log" 2>&1; then
    status=0
else
    status=$?
fi
cat "$log"

if [ "$status" -eq 139 ] &&
    grep -Fq 'Segmentation fault (SIGSEGV) in the Roc compiler.' "$log" &&
    grep -Eq 'post-check +boxy_lowering' "$log"; then
    echo "BUG REPRODUCED: roc check exited $status with a segfault in boxy_lowering"
    exit 0
fi

if grep -Fq 'missing the field: size' "$log"; then
    echo "BUG NOT REPRODUCED: roc check reported the missing field"
    exit 1
fi

echo "unexpected result: roc check exited $status without the expected segfault"
exit 1
