#!/usr/bin/env bash
# Reproduces BUG-009: an app that provides the wrong type for a platform
# requirement segfaults `roc check` when the required nominal type's backing
# type refers to a tag-union alias declared in its own associated block.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-009-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
nominal="$HOME/nominal"
mkdir -p "$work" "$nominal"
check_log="$HOME/check.log"

echo "roc version: $(roc version)"
cp -R App.roc Valid.roc platform "$work/"

run_check() {
    if roc check "$@" >"$check_log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$check_log"
}

echo "--- control: a well-typed app checks cleanly ---"
(cd "$work" && run_check Valid.roc
    if [ "$status" -ne 0 ]; then
        echo "unexpected control result: roc check Valid.roc exited $status"
        exit 1
    fi)

echo "--- control: with Step as a nominal type, the same app reports a type mismatch ---"
cp -R App.roc platform "$nominal/"
sed -i 's/^\tStep : \[/\tStep := [/' "$nominal/platform/P.roc"
grep -Fq 'Step := [Run(Str)]' "$nominal/platform/P.roc"
(cd "$nominal" && run_check App.roc
    if [ "$status" -ne 1 ] || ! grep -Fq 'type mismatch' "$check_log"; then
        echo "unexpected control result: roc check exited $status without a type mismatch"
        exit 1
    fi)

echo "--- roc check App.roc (Step is an alias) ---"
cd "$work"
run_check App.roc

if [ "$status" -eq 139 ] &&
    grep -Fq 'Segmentation fault (SIGSEGV) in the Roc compiler.' "$check_log"; then
    echo "BUG REPRODUCED: roc check exited $status with the expected segfault"
    exit 0
fi

if [ "$status" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: roc check exited successfully"
    exit 1
fi

if [ "$status" -eq 1 ] && grep -Fq 'type mismatch' "$check_log"; then
    echo "BUG NOT REPRODUCED: roc check reported the type mismatch without crashing"
    exit 1
fi

echo "unexpected failure: roc check exited $status without the expected segfault"
exit 1
