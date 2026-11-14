#!/usr/bin/env bash
# Reproduces BUG-032: `roc check` rejects a basic-webserver 0.21.0
# Sqlite.query_many! whose row is a record, because Sqlite.RowEncoding has no
# missing_field method.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-032-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/check.log"

echo "roc version: $(roc version)"
mkdir -p "$HOME/record" "$HOME/scalar"
cp main.roc "$HOME/record/"
# Control: the same query, read as a single-column scalar row.
sed 's/rows : List({ name : Str })/rows : List(Str)/' main.roc >"$HOME/scalar/main.roc"
grep -q 'rows : List(Str)' "$HOME/scalar/main.roc"

echo "--- control: rows : List(Str) ---"
# Warnings alone (exit status 2) count as checking.
control=0
(cd "$HOME/scalar" && roc check --no-cache main.roc) >"$log" 2>&1 || control=$?
if [ "$control" -ne 0 ] && ! { [ "$control" -eq 2 ] && grep -q '── 0 errors and' "$log"; }; then
    cat "$log"
    echo "unexpected control result: the scalar row fails to check"
    exit 1
fi
cat "$log"

echo "--- roc check main.roc (rows : List({ name : Str })) ---"
status=0
(cd "$HOME/record" && roc check --no-cache main.roc) >"$log" 2>&1 || status=$?
cat "$log"
if [ "$status" -ne 0 ] \
    && grep -Fq 'This use needs the missing_field method' "$log" \
    && grep -Fq 'Sqlite.RowEncoding' "$log"; then
    echo "BUG REPRODUCED: Sqlite.RowEncoding has no missing_field method"
    exit 0
fi
echo "BUG NOT REPRODUCED"
exit 1
