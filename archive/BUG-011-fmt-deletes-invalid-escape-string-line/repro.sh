#!/usr/bin/env bash
# Reproduces BUG-011: `roc fmt` deletes a `\\` multiline-string line that
# contains an invalid escape (here a trailing `\`) and reports success, so a
# module that `roc check` rejects becomes a different module that it accepts.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-011-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
log="$HOME/log"

echo "roc version: $(roc version)"
cp Invalid.roc Valid.roc "$work/"
cd "$work"

run() {
    if "$@" >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- control: an escaped backslash keeps both lines ---"
run roc fmt Valid.roc
if [ "$status" -ne 0 ] || ! cmp -s Valid.roc "$OLDPWD/Valid.roc"; then
    echo "unexpected control result: roc fmt Valid.roc exited $status or changed the file"
    cat Valid.roc
    exit 1
fi

echo "--- control: roc check rejects the invalid escape ---"
run roc check Invalid.roc
if [ "$status" -ne 1 ] || ! grep -Fq 'invalid escape sequence' "$log"; then
    echo "unexpected control result: roc check exited $status without an invalid escape error"
    exit 1
fi

echo "--- roc fmt Invalid.roc ---"
run roc fmt Invalid.roc
echo "--- Invalid.roc after formatting ---"
cat Invalid.roc

if [ "$status" -eq 0 ] &&
    ! grep -Fq 'first' Invalid.roc &&
    grep -Fq '\\second' Invalid.roc; then
    run roc check Invalid.roc
    if [ "$status" -eq 0 ] || ! grep -Fq 'invalid escape sequence' "$log"; then
        echo "BUG REPRODUCED: roc fmt exited 0 and deleted the \\\\first line; the module now checks without the escape error"
        exit 0
    fi
fi

if [ "$status" -ne 0 ] && grep -Fq 'first' Invalid.roc; then
    echo "BUG NOT REPRODUCED: roc fmt refused the invalid module and kept the line"
    exit 1
fi

if cmp -s Invalid.roc "$OLDPWD/Invalid.roc"; then
    echo "BUG NOT REPRODUCED: roc fmt left the module unchanged"
    exit 1
fi

echo "unexpected result: roc fmt exited $status without the expected deletion"
exit 1
