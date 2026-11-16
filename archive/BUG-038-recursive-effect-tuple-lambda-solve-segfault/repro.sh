#!/usr/bin/env bash
# Reproduces BUG-038: roc check segfaults in post-check lambda_solve on two
# nested recursive effectful functions, the inner returning a tuple with a
# computed Bool, called on a Tcp connection.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-038-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/out.log"

echo "roc version: $(roc version)"

status=0
roc check main.roc >"$log" 2>&1 || status=$?
cat "$log"
if grep -Fq 'Segmentation fault' "$log" && grep -Fq 'lambda_solve' "$log"; then
    echo "BUG REPRODUCED: roc check segfaults in lambda_solve (exit $status)"
    exit 0
fi
echo "BUG NOT REPRODUCED: exit $status"
exit 1
