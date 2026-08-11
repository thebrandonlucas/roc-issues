#!/usr/bin/env bash
# Reproduces BUG-001: duplicate module names across packages panic the compiler.
#
# Expected behavior: both checks succeed (or the compiler reports a diagnostic).
# Actual behavior: the first (cold-cache) check succeeds; the second panics.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

echo "roc version: $(roc version)"
echo "clearing roc cache for a cold run..."
rm -rf ~/.cache/roc

echo "--- run 1 (cold cache) ---"
if roc check main.roc; then
    echo "run 1: OK (as expected, cold cache succeeds)"
else
    echo "run 1: FAILED unexpectedly"
    exit 1
fi

echo "--- run 2 (warm cache) ---"
if roc check main.roc; then
    echo "run 2: OK — BUG NOT REPRODUCED (compiler no longer panics)"
    exit 1
else
    status=$?
    if [ "$status" -ge 128 ]; then
        echo "run 2: killed by signal $((status - 128)) — BUG REPRODUCED"
        exit 0
    fi
    echo "run 2: exited $status without a crash — unexpected, investigate"
    exit 1
fi
