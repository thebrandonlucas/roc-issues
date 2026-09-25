#!/usr/bin/env bash
# Reproduces BUG-008: interpolating a reserved word in an imported module
# panics `roc check` instead of reporting the error.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-008-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
check_log="$HOME/check.log"

echo "roc version: $(roc version)"
cp M.roc N.roc "$work/"
cd "$work"

echo "--- control: roc check M.roc reports the reserved word ---"
if roc check M.roc >"$check_log" 2>&1; then
    status=0
else
    status=$?
fi
cat "$check_log"
if [ "$status" -ne 1 ] ||
    ! grep -Fq 'That word is reserved by Roc' "$check_log"; then
    echo "unexpected control result: roc check M.roc exited $status without the reserved-word error"
    exit 1
fi

echo "--- roc check N.roc (imports M) ---"
if roc check N.roc >"$check_log" 2>&1; then
    cat "$check_log"
    echo "BUG NOT REPRODUCED: roc check exited successfully"
    exit 1
else
    status=$?
fi
cat "$check_log"

if [ "$status" -eq 134 ] &&
    grep -Fq 'panic: Unhandled canonicalize diagnostic in diagnosticToReport: invalid_string_interpolation' "$check_log"; then
    echo "BUG REPRODUCED: roc check exited $status with the expected panic"
    exit 0
fi

if [ "$status" -eq 1 ] && grep -Fq 'That word is reserved by Roc' "$check_log"; then
    echo "BUG NOT REPRODUCED: roc check reported the reserved word without panicking"
    exit 1
fi

echo "unexpected failure: roc check exited $status without the expected panic"
exit 1
