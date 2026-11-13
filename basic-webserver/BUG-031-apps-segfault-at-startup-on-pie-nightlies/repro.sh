#!/usr/bin/env bash
# Reproduces BUG-031: a basic-webserver 0.21.0 app builds, then segfaults
# before it starts listening (on Roc nightlies that link executables as PIE).
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-031-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
ulimit -c 0

echo "roc version: $(roc version)"
cp main.roc "$HOME/"
cd "$HOME"

echo "--- roc build main.roc --output=app ---"
if ! roc build --no-cache main.roc --output=app >build.log 2>&1; then
    cat build.log
    echo "unexpected: the build failed"
    exit 1
fi
cat build.log

echo "--- ./app (stopped after 10s if it keeps running) ---"
status=0
timeout 10 ./app >run.log 2>&1 || status=$?
cat run.log
echo "exit status: $status"

if [ "$status" -eq 139 ] && ! grep -q 'Listening on' run.log; then
    echo "BUG REPRODUCED: the app segfaults before it starts listening"
    exit 0
fi
if [ "$status" -eq 124 ] && grep -q 'Listening on' run.log; then
    echo "BUG NOT REPRODUCED: the app starts and listens"
    exit 1
fi
echo "BUG NOT REPRODUCED: unexpected result"
exit 1
