#!/usr/bin/env bash
# Reproduces BUG-014: interpolating the keyword `var` in an imported type
# module panics `roc check` instead of reporting the error.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-014-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp Mod.roc N.roc "$work/"
cd "$work"

run() {
    if "$@" >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- control: roc check Mod.roc reports the keyword ---"
run roc check Mod.roc
if [ "$status" -ne 1 ] ||
    ! grep -Fq 'That word is reserved by Roc' "$log"; then
    echo "unexpected control result: roc check Mod.roc exited $status without the reserved-word error"
    exit 1
fi

echo "--- roc check N.roc (imports Mod) ---"
run roc check N.roc

if [ "$status" -eq 134 ] &&
    grep -Fq 'panic: Unhandled canonicalize diagnostic in diagnosticToReport: invalid_string_interpolation' "$log"; then
    echo "BUG REPRODUCED: roc check exited $status with the expected panic"
    exit 0
fi

if [ "$status" -eq 1 ] && grep -Fq 'That word is reserved by Roc' "$log"; then
    echo "BUG NOT REPRODUCED: roc check reported the keyword without panicking"
    exit 1
fi

echo "unexpected failure: roc check exited $status without the expected panic"
exit 1
