#!/usr/bin/env bash
# Reproduces BUG-002: `roc test` crashes through the plugin union registry path.
#
# Expected behavior: tests compile and run.
# Actual behavior: the compiler crashes (SIGSEGV or SIGABRT in LIR lowering).
set -uo pipefail
cd "$(dirname "$0")"

echo "roc version: $(roc version)"

echo "--- roc check (expected to succeed) ---"
if ! roc check plugin-tests.roc; then
    echo "roc check: FAILED unexpectedly"
    exit 1
fi

echo "--- roc test (expected to crash) ---"
roc test plugin-tests.roc
status=$?
if [ "$status" -eq 0 ]; then
    echo "roc test: OK — BUG NOT REPRODUCED (compiler no longer crashes)"
    exit 1
elif [ "$status" -ge 128 ]; then
    echo "roc test: killed by signal $((status - 128)) — BUG REPRODUCED"
    exit 0
else
    echo "roc test: exited $status without a crash — unexpected, investigate"
    exit 1
fi
