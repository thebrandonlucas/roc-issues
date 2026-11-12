#!/usr/bin/env bash
# Reproduces BUG-029: a second `roc check` crashes when the cache still holds
# the first check's canonicalization entries (`can/`) but not its module
# entries (`mod/`), for an app with a top-level value of a recursive nominal
# tag union.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-029-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp -R App.roc platform "$work/"
cd "$work"
log="$HOME/check.log"

echo "roc version: $(roc version)"

run_check() {
    if timeout 120 roc check App.roc >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- roc check App.roc (empty cache) ---"
run_check
if [ "$status" -ne 0 ]; then
    echo "unexpected result: the first roc check exited $status"
    exit 1
fi

echo "--- control: roc check App.roc (cache intact) ---"
run_check
if [ "$status" -ne 0 ]; then
    echo "unexpected result: the warm roc check exited $status"
    exit 1
fi

mapfile -t mods < <(find "$XDG_CACHE_HOME/roc" -mindepth 2 -maxdepth 2 -type d -name mod)
if [ "${#mods[@]}" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: this compiler's cache has no compat-*/mod directory"
    exit 1
fi
echo "--- removing ${mods[*]#"$XDG_CACHE_HOME/"}, keeping can/ ---"
rm -rf "${mods[@]}"

echo "--- roc check App.roc (can/ entries without mod/ entries) ---"
run_check
if [ "$status" -gt 128 ] || grep -Eq 'in the Roc compiler\.|internal compiler error|OutOfMemory' "$log"; then
    echo "BUG REPRODUCED: roc check exited $status"
    exit 0
fi
if [ "$status" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: roc check succeeded"
    exit 1
fi
echo "unexpected result: roc check exited $status without a crash"
exit 1
