#!/usr/bin/env bash
# Reproduces BUG-033: `roc docs` lists a broken doc link, then also reports
# the BrokenDocLinks error as an unreported error, a compiler bug.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-033-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/docs.log"

echo "roc version: $(roc version)"
mkdir -p "$HOME/broken" "$HOME/control"
cp main.roc Greet.roc "$HOME/broken/"
# Control: the same package with the link pointing at an item that exists.
cp main.roc "$HOME/control/"
sed 's/\[nonexistent\]/[hello]/' Greet.roc >"$HOME/control/Greet.roc"
grep -Fq '[hello]' "$HOME/control/Greet.roc"

echo "--- control: See [hello]. ---"
if ! (cd "$HOME/control" && roc docs main.roc) >"$log" 2>&1; then
    cat "$log"
    echo "unexpected control result: docs with a valid link fail"
    exit 1
fi
cat "$log"

echo "--- roc docs main.roc (See [nonexistent].) ---"
status=0
(cd "$HOME/broken" && roc docs main.roc) >"$log" 2>&1 || status=$?
cat "$log"
echo "exit status: $status"
if [ "$status" -ne 0 ] \
    && grep -Fq '[nonexistent]' "$log" \
    && grep -Fq 'unreported error' "$log" \
    && grep -Fq 'BrokenDocLinks' "$log"; then
    echo "BUG REPRODUCED: the broken link is listed, then reported as an unreported error"
    exit 0
fi
echo "BUG NOT REPRODUCED"
exit 1
