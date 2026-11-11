#!/usr/bin/env bash
# Reproduces BUG-024: when an interpolated string literal shares a list with a
# later element of a non-string type, `roc check` reports "This string literal
# is being used where a non-string type is needed" at that later element
# instead of at the interpolated string literal.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-011-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
check_log="$HOME/check.log"

echo "roc version: $(roc version)"
cp App.roc Plain.roc "$work/"
cd "$work"

run_check() {
    if roc check --no-cache "$@" >"$check_log" 2>&1; then
        status=0
    else
        status=$?
    fi
    cat "$check_log"
}

echo "--- control: a plain string literal is reported at the literal ---"
run_check Plain.roc
if [ "$status" -ne 1 ] ||
    ! grep -Fq 'This string literal is being used where a non-string type is needed.' "$check_log" ||
    ! grep -Eq 'type mismatch .* Plain\.roc:4:9$' "$check_log"; then
    echo "unexpected control result: roc check Plain.roc exited $status without a mismatch at Plain.roc:4:9"
    exit 1
fi

echo "--- roc check App.roc (interpolated string literal) ---"
run_check App.roc

if [ "$status" -ne 1 ] ||
    ! grep -Fq 'This string literal is being used where a non-string type is needed.' "$check_log"; then
    echo "unexpected failure: roc check exited $status without the expected string literal mismatch"
    exit 1
fi

# App.roc line 6 is `list = ["v${version}", number]`: the interpolated
# literal starts at column 9 and `number` at column 24.
if grep -Eq 'type mismatch .* App\.roc:6:24$' "$check_log"; then
    echo "BUG REPRODUCED: the string literal mismatch is reported at \`number\` (App.roc:6:24), not at the interpolated literal (App.roc:6:9)"
    exit 0
fi

if grep -Eq 'type mismatch .* App\.roc:6:9$' "$check_log"; then
    echo "BUG NOT REPRODUCED: the mismatch is reported at the interpolated literal"
    exit 1
fi

echo "unexpected failure: the mismatch is reported at neither App.roc:6:9 nor App.roc:6:24"
exit 1
