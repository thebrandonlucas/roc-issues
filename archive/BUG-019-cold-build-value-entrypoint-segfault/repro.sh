#!/usr/bin/env bash
# Reproduces BUG-019: with an empty cache, `roc build` segfaults in lir_gen on
# a trivial app whose platform provides a value (not a function) to the host.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-019-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp -R App.roc platform "$work/"
# An empty libhost.a stands in for a host; the crash happens before linking.
mkdir -p "$work/platform/targets/x64musl" "$work/platform/targets/arm64musl"
: >"$work/platform/targets/x64musl/libhost.a"
: >"$work/platform/targets/arm64musl/libhost.a"
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
XDG_CACHE_HOME="$HOME/check-cache" run roc check App.roc
if [ "$status" -ne 0 ]; then
    echo "unexpected control result: roc check exited $status"
    exit 1
fi

echo "--- roc build App.roc (empty cache) ---"
XDG_CACHE_HOME="$HOME/build-cache" run timeout 600 roc build App.roc --output="$HOME/app"

if [ "$status" -eq 139 ] &&
    grep -Fq 'Segmentation fault (SIGSEGV) in the Roc compiler.' "$log" &&
    grep -Eq 'post-check +lir_gen' "$log"; then
    echo "BUG REPRODUCED: roc build exited $status with a segfault in lir_gen"
    exit 0
fi

if [ "$status" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: roc build exited successfully"
    exit 1
fi

echo "unexpected failure: roc build exited $status without the expected segfault"
exit 1
