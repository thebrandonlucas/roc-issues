#!/usr/bin/env bash
# Reproduces BUG-010: when XDG_CACHE_HOME climbs out of the app directory with
# `..`, building an app whose platform is a URL package fails with an
# unexplained PathOutsideWorkspace error, while `roc check` passes.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-010-home.XXXXXX")
server_pid=
cleanup() {
    if [ -n "$server_pid" ]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$tmp_home"
}
trap cleanup EXIT
export HOME="$tmp_home"
log="$HOME/roc.log"

echo "roc version: $(roc version)"

echo "--- bundle the platform (an empty libhost.a stands in for a host) ---"
cp -R platform "$HOME/platform"
mkdir -p "$HOME/platform/targets/x64musl" "$HOME/platform/targets/arm64musl" "$HOME/srv"
: >"$HOME/platform/targets/x64musl/libhost.a"
: >"$HOME/platform/targets/arm64musl/libhost.a"
(cd "$HOME/platform" &&
    roc bundle main.roc targets/x64musl/libhost.a targets/arm64musl/libhost.a \
        --output-dir "$HOME/srv")
bundle=$(cd "$HOME/srv" && ls -- *.tar.zst)

echo "--- serve it from localhost ---"
python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$HOME/srv" \
    >"$HOME/server.log" 2>&1 &
server_pid=$!
port=
for _ in $(seq 100); do
    port=$(sed -n 's/.* port \([0-9][0-9]*\).*/\1/p' "$HOME/server.log")
    [ -n "$port" ] && break
    sleep 0.1
done
if [ -z "$port" ]; then
    cat "$HOME/server.log"
    echo "unexpected failure: the HTTP server did not start"
    exit 1
fi
url="http://127.0.0.1:$port/$bundle"
echo "$url"

app="$HOME/work/app"
mkdir -p "$app"
printf 'app [main] { pf: platform "%s" }\n\nmain = "hi"\n' "$url" >"$app/App.roc"
cd "$app"

run_roc() {
    if roc "$@" >"$log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$log"
}

echo "--- control: roc build with a canonical XDG_CACHE_HOME ---"
XDG_CACHE_HOME="$HOME/work/canonical-cache" run_roc build App.roc --output="$HOME/control"
if [ "$status" -ne 0 ]; then
    echo "unexpected control result: roc build exited $status"
    exit 1
fi

export XDG_CACHE_HOME="$app/../cache"
echo "--- XDG_CACHE_HOME=$XDG_CACHE_HOME ---"

echo "--- roc check App.roc ---"
run_roc check App.roc
if [ "$status" -ne 0 ]; then
    echo "unexpected result: roc check exited $status"
    exit 1
fi

echo "--- roc build App.roc ---"
run_roc build App.roc --output="$HOME/repro"

if [ "$status" -eq 1 ] &&
    grep -Fq 'The compiler stopped with the error PathOutsideWorkspace but did not say why.' "$log"; then
    echo "BUG REPRODUCED: roc build exited $status with PathOutsideWorkspace"
    exit 0
fi

if [ "$status" -eq 0 ]; then
    echo "BUG NOT REPRODUCED: roc build exited successfully"
    exit 1
fi

echo "unexpected failure: roc build exited $status without PathOutsideWorkspace"
exit 1
