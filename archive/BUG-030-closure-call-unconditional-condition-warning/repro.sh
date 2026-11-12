#!/usr/bin/env bash
# A condition on a local closure's result is warned about as known at compile
# time. Uses the roc on PATH.
set -eu
cd "$(dirname "$0")"
echo "roc version: $(roc version)"
out=$(roc check main.roc 2>&1) || true
echo "$out"
if echo "$out" | grep -Fq 'unconditional condition'; then
    echo "BUG REPRODUCED: the condition is warned about"
    exit 0
fi
echo "BUG NOT REPRODUCED: no warning"
exit 1
