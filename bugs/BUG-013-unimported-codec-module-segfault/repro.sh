#!/usr/bin/env bash
# Reproduces BUG-013: `roc check` segfaults on an app that calls a package
# function decoding with derived parsers from a module the app does not
# import; importing that module makes the same app check cleanly.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-013-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp -R App.roc Valid.roc api platform "$work/"
cd "$work"

run() {
    if "$@" >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- control: the same app importing api.Sexpr checks cleanly ---"
run roc check Valid.roc
if [ "$status" -ne 0 ] && [ "$status" -ne 2 ]; then
    echo "unexpected control result: roc check Valid.roc exited $status"
    exit 1
fi

echo "--- roc check App.roc ---"
run roc check App.roc

if [ "$status" -eq 139 ] &&
    grep -Fq 'Segmentation fault (SIGSEGV) in the Roc compiler.' "$log"; then
    echo "BUG REPRODUCED: roc check exited $status with the expected segfault"
    exit 0
fi

if [ "$status" -eq 0 ] || [ "$status" -eq 2 ]; then
    echo "BUG NOT REPRODUCED: roc check App.roc succeeded"
    exit 1
fi

echo "unexpected failure: roc check exited $status without the expected segfault"
exit 1
