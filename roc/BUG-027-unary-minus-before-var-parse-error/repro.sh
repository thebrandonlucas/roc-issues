#!/usr/bin/env bash
# Reproduces BUG-027: `roc check` rejects unary minus directly before a `var`
# name (`-$n`) as "unexpected expression syntax", while `-n` and `-($n)` parse.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-025-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
check_log="$HOME/check.log"

echo "roc version: $(roc version)"
cp Var.roc Plain.roc "$work/"
cd "$work"

run_check() {
    if roc check --no-cache "$@" >"$check_log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$check_log"
}

echo "--- control: -n and -(\$n) parse ---"
run_check Plain.roc
if [ "$status" -ne 0 ] || ! grep -Fq 'No errors found' "$check_log"; then
    echo "unexpected control result: roc check Plain.roc exited $status with errors"
    exit 1
fi

echo "--- roc check Var.roc (-\$n) ---"
run_check Var.roc

# Var.roc line 4 is `$n = -$n`; the minus is at column 7.
if grep -Eq 'unexpected expression syntax .* Var\.roc:4:7$' "$check_log"; then
    echo "BUG REPRODUCED: \`-\$n\` is rejected as unexpected expression syntax at Var.roc:4:7"
    exit 0
fi

if grep -Fq 'No errors found' "$check_log"; then
    echo "BUG NOT REPRODUCED: Var.roc checks without errors"
    exit 1
fi

echo "unexpected failure: Var.roc fails without the parse error at Var.roc:4:7"
exit 1
