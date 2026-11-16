#!/usr/bin/env bash
# Best-effort harness for BUG-018: `roc check` intermittently dies by SIGSEGV
# or SIGABRT when many checks run in parallel. Seen on CI runners only.
#
# Usage: repro.sh [ROUNDS]   (default 10)
set -eu
cd "$(dirname "$0")"

rounds=${1:-${ROUNDS:-10}}
kai_repo=https://github.com/thebrandonlucas/kai.git
kai_rev=3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-018-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
src="$HOME/kai"
logs="$HOME/logs"
mkdir -p "$src" "$logs"

echo "roc version: $(roc version)"
echo "fetching kai at $kai_rev"
git -C "$src" init -q
git -C "$src" fetch -q --depth 1 "$kai_repo" "$kai_rev"
git -C "$src" checkout -q FETCH_HEAD

cd "$src"
echo "building the Kai platform host"
if ! (cd platform && timeout 900 zig build --release) >"$logs/host.log" 2>&1; then
    cat "$logs/host.log"
    echo "BUG NOT REPRODUCED or unexpected output: platform host build failed"
    exit 1
fi

# The package and app roots Kai's CI checks (fuzz targets are not checked).
mapfile -t roots < <(git ls-files '*Kaifile.roc' 'plugins/*/main.roc' \
    'examples/plugins/*/main.roc' cli/main.roc | grep -v '/fuzz/')
echo "checking ${#roots[@]} roots in parallel for $rounds rounds"

crashes=0
failures=0
for round in $(seq 1 "$rounds"); do
    # Each round starts from an empty Roc cache, as on a fresh CI runner.
    cache="$HOME/cache-$round"
    mkdir -p "$cache"
    pids=()
    for i in "${!roots[@]}"; do
        XDG_CACHE_HOME="$cache" timeout 600 roc check "${roots[$i]}" \
            >"$logs/$round-$i.log" 2>&1 &
        pids[i]=$!
    done
    for i in "${!roots[@]}"; do
        status=0
        wait "${pids[$i]}" || status=$?
        log="$logs/$round-$i.log"
        if [ "$status" -gt 128 ] || grep -Fq 'in the Roc compiler.' "$log"; then
            crashes=$((crashes + 1))
            echo "round $round: roc check ${roots[$i]} crashed (exit $status)"
            grep -A6 'in the Roc compiler.' "$log" || tail -n 20 "$log"
        elif [ "$status" -ne 0 ]; then
            failures=$((failures + 1))
            echo "round $round: roc check ${roots[$i]} failed (exit $status)"
            tail -n 20 "$log"
        fi
    done
    rm -rf "$cache"
    echo "round $round done"
done

if [ "$crashes" -gt 0 ]; then
    echo "BUG REPRODUCED: $crashes roc check process(es) died by signal"
    exit 0
fi
if [ "$failures" -gt 0 ]; then
    echo "BUG NOT REPRODUCED or unexpected output: $failures check(s) failed without a crash"
    exit 1
fi
echo "BUG NOT REPRODUCED: no crash in $rounds rounds"
exit 1
