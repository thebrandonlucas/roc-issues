#!/usr/bin/env bash
# Reproduces BUG-020: `roc test` run after `roc build` on the same sources fails
# an expect over a top-level constant, while `roc test --no-cache` passes it.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-020-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/cache"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp -R app.roc pkg "$work/"
cd "$work"

echo "--- control: roc test pkg/main.roc (empty cache) ---"
XDG_CACHE_HOME="$HOME/control-cache" roc test pkg/main.roc
echo "--- roc build app.roc ---"
roc build app.roc --output="$HOME/app"

echo "--- roc test pkg/main.roc (after the build) ---"
if roc test pkg/main.roc >"$log" 2>&1; then
    cat "$log"
    echo "BUG NOT REPRODUCED: roc test passed after roc build"
    exit 1
fi
cat "$log"

echo "--- roc test pkg/main.roc --no-cache ---"
if ! roc test pkg/main.roc --no-cache; then
    echo "unexpected failure: roc test --no-cache failed too"
    exit 1
fi

if grep -Fq 'expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]' "$log"; then
    echo "BUG REPRODUCED: the expect fails after roc build and passes with --no-cache"
    exit 0
fi

echo "unexpected failure: roc test failed without the expected expect"
exit 1
