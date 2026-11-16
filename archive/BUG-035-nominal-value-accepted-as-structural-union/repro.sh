#!/usr/bin/env bash
# Reproduces BUG-035: a value of a nominal tag union is accepted where a
# structural tag union of the same shape is annotated, and keeps its methods.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-035-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
log="$HOME/out.log"
mkdir -p "$work"
cp Color.roc Light.roc "$work/"
cd "$work"

echo "roc version: $(roc version)"

run() { # run <args...>: roc <args> into $log, sets $status
    status=0
    roc "$@" >"$log" 2>&1 || status=$?
    cat "$log"
}

echo "--- control: roc check Light.roc (a different shape) ---"
run check Light.roc
if [ "$status" -ne 1 ] || ! grep -Fq 'type mismatch' "$log"; then
    echo "unexpected control result: Light.roc exited $status without a type mismatch"
    exit 1
fi

echo "--- roc check Color.roc ---"
run check Color.roc
if [ "$status" -ne 0 ] || ! grep -Fq 'No errors found' "$log"; then
    if grep -Fq 'type mismatch' "$log"; then
        echo "BUG NOT REPRODUCED: roc check reports the type mismatch"
    else
        echo "unexpected result: roc check Color.roc exited $status"
    fi
    exit 1
fi

echo "--- roc test Color.roc ---"
run test Color.roc
if [ "$status" -eq 0 ] && grep -Fq 'tests passed' "$log"; then
    echo "BUG REPRODUCED: a Color is accepted as [Red, Green] and keeps Color's methods"
    exit 0
fi
echo "unexpected result: roc test Color.roc exited $status"
exit 1
