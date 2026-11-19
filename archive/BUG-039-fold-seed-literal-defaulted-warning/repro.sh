#!/usr/bin/env bash
# Reproduces BUG-039: a fold whose step is `sum + x` gets a "literal
# defaulted" warning on its literal seed, though `x + sum` gets none.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-039-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/out.log"
mkdir -p "$HOME/bug" "$HOME/control"
cp Fold.roc "$HOME/bug/"
# Control: the operands swapped.
sed 's/sum + x/x + sum/' Fold.roc >"$HOME/control/Fold.roc"

echo "roc version: $(roc version)"

run() { # run <dir> <args...>: roc <args> in <dir> into $log, sets $status
    local dir=$1; shift
    status=0
    (cd "$dir" && roc "$@") >"$log" 2>&1 || status=$?
    cat "$log"
}

echo "--- control: roc check Fold.roc with x + sum ---"
run "$HOME/control" check Fold.roc
if [ "$status" -ne 0 ] || ! grep -Fq 'No errors found' "$log"; then
    echo "unexpected control result: exit $status"
    exit 1
fi

echo "--- roc check Fold.roc ---"
run "$HOME/bug" check Fold.roc
if grep -Eq 'literal defaulted .* Fold\.roc:4:25' "$log" && grep -Fq 'default type U32' "$log"; then
    echo "BUG REPRODUCED: the fold's literal seed is reported as defaulted (exit $status)"
    exit 0
fi
echo "BUG NOT REPRODUCED (exit $status)"
exit 1
