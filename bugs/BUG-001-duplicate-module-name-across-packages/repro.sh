#!/usr/bin/env bash
# Reproduces BUG-001: duplicate module names across packages panic the compiler.
set -eu
ulimit -c 0
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-001-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
run_log="$tmp_home/run-2.log"

echo "roc version: $(roc version)"
echo "temporary HOME: $HOME"

echo "--- run 1 (cold cache) ---"
if roc check main.roc; then
    echo "run 1: OK (cold cache)"
else
    echo "run 1: unexpected failure"
    exit 1
fi

echo "--- run 2 (warm cache) ---"
if roc check main.roc >"$run_log" 2>&1; then
    cat "$run_log"
    echo "BUG NOT REPRODUCED: warm-cache check succeeded"
    exit 1
else
    status=$?
fi
cat "$run_log"

if grep -Fq 'typed_cir invariant violated: duplicate module name' "$run_log"; then
    echo "BUG REPRODUCED: warm-cache check exited $status with the expected panic"
    exit 0
fi

echo "unexpected failure: warm-cache check exited $status without the expected panic"
exit 1
