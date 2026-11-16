#!/usr/bin/env bash
# Reproduces BUG-037: Json.to_str and Json.parse report that the builtin Try
# has no encoder_for / parser_for, though a same-shaped local nominal type
# with `encoder_for : _` encodes.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-037-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/out.log"
mkdir -p "$HOME/bug" "$HOME/control"
cp Probe.roc Parse.roc "$HOME/bug/"
# Control: the local nominal type alone.
grep -v 'Probe.theirs' Probe.roc >"$HOME/control/Probe.roc"

echo "roc version: $(roc version)"

run() { # run <dir> <args...>: roc <args> in <dir> into $log, sets $status
    local dir=$1; shift
    status=0
    (cd "$dir" && roc "$@") >"$log" 2>&1 || status=$?
    cat "$log"
}

echo "--- control: roc test Probe.roc without the Try expect ---"
run "$HOME/control" test Probe.roc
if [ "$status" -ne 0 ] || ! grep -Fq 'tests passed' "$log"; then
    echo "unexpected control result: exit $status"
    exit 1
fi

echo "--- roc check Probe.roc ---"
run "$HOME/bug" check Probe.roc
if ! { [ "$status" -eq 1 ] && grep -Eq 'missing method .* Probe\.roc:14:' "$log" \
    && grep -Fq 'does not have a method named encoder_for' "$log"; }; then
    echo "BUG NOT REPRODUCED: no missing encoder_for at Probe.roc:14 (exit $status)"
    exit 1
fi

echo "--- roc check Parse.roc ---"
run "$HOME/bug" check Parse.roc
if [ "$status" -eq 1 ] && grep -Fq 'does not have a method named parser_for' "$log"; then
    echo "BUG REPRODUCED: Try(Str, Str) has no encoder_for and no parser_for"
    exit 0
fi
echo "unexpected result: Parse.roc exit $status without the missing parser_for"
exit 1
