#!/usr/bin/env bash
# Reproduces BUG-020: `roc test` fails an expect over a top-level constant
# whose rows come back with garbage strings (each id is the single byte 0xFF).
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-020-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
cp -r pkg "$work/"
cd "$work"

echo "roc version: $(roc version)"
log="$HOME/test.log"
if roc test pkg/main.roc >"$log" 2>&1; then
    cat "$log"
    echo "BUG NOT REPRODUCED: roc test passed"
    exit 1
fi
cat "$log"

if grep -Fq 'expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]' "$log"; then
    echo "BUG REPRODUCED: the expect over the parsed rows fails"
    exit 0
fi
echo "unexpected failure: roc test failed without the expected expect"
exit 1
