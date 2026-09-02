#!/usr/bin/env bash
# Reproduces BUG-006: a folded Path crossing an effectful helper crashes at runtime.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-006-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
tmp_dir="$HOME/build"
mkdir -p "$tmp_dir"
run_log="$tmp_dir/run.log"

echo "roc version: $(roc version)"
echo "--- build ---"
roc build Repro.roc --opt=dev --output="$tmp_dir/repro"

echo "--- run ---"
if "$tmp_dir/repro" . >"$run_log" 2>&1; then
    cat "$run_log"
    echo "BUG NOT REPRODUCED: program exited successfully"
    exit 1
else
    status=$?
fi
cat "$run_log"

if grep -Fq '[ROC CRASHED] dispatch on a value that can never exist' "$run_log"; then
    echo "BUG REPRODUCED: runtime exited $status with the expected crash"
    exit 0
fi

echo "unexpected failure: runtime exited $status without the expected crash"
exit 1
