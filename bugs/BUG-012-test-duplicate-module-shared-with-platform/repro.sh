#!/usr/bin/env bash
# Reproduces BUG-012: `roc test` panics with "compiled module plan contains
# duplicate source module" when a platform depends on a package that imports
# one of the platform's own module files through a second package root.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-012-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp -R App.roc platform lib "$work/"
cd "$work"

run() {
    if "$@" >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- control: roc check App.roc ---"
run roc check App.roc
if [ "$status" -ne 0 ]; then
    echo "unexpected control result: roc check exited $status"
    exit 1
fi

echo "--- control: roc test lib/main.roc (the package alone) ---"
run roc test lib/main.roc
if [ "$status" -ne 0 ]; then
    echo "unexpected control result: roc test lib/main.roc exited $status"
    exit 1
fi

echo "--- roc test App.roc ---"
run roc test App.roc

if [ "$status" -ne 0 ] &&
    grep -Fq 'compiled module plan contains duplicate source module' "$log"; then
    echo "BUG REPRODUCED: roc test exited $status with the duplicate module panic"
    exit 0
fi

if [ "$status" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: roc test passed"
    exit 1
fi

echo "unexpected failure: roc test exited $status without the expected panic"
exit 1
