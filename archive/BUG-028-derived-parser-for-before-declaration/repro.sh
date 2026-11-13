#!/usr/bin/env bash
# Reproduces BUG-028: a derived `parser_for : _` "does not exist" when a
# sibling nominal type's custom parser_for calls it before its declaration.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-026-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/check.log"

echo "roc version: $(roc version)"
for name in Earlier Later; do
    mkdir -p "$HOME/$name"
    cp "$name.roc" "$HOME/$name/"
    echo "package [$name] {}" >"$HOME/$name/main.roc"
done

echo "--- control: Fields declared before its use ---"
if ! roc test --no-cache "$HOME/Earlier/main.roc" >"$log" 2>&1; then
    cat "$log"
    echo "unexpected control result: Earlier fails"
    exit 1
fi
cat "$log"

echo "--- roc check Later/main.roc ---"
roc check --no-cache "$HOME/Later/main.roc" >"$log" 2>&1 || true
cat "$log"
if grep -Fq 'Fields.parser_for does not exist' "$log"; then
    echo "BUG REPRODUCED: the derived Fields.parser_for is missing when used before its declaration"
    exit 0
fi
echo "BUG NOT REPRODUCED"
exit 1
