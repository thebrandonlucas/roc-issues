#!/usr/bin/env bash
# Reproduces BUG-036: a package dependency whose path is a type module (not a
# package) is accepted, and the module's values are reported as not existing.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-036-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
log="$HOME/out.log"

echo "roc version: $(roc version)"

# The repro as it is.
mkdir -p "$HOME/bug"
cp -r Shared.roc sub "$HOME/bug/"
# Control: the same Uses.roc, with base pointing at a package that holds
# the same Shared.roc.
mkdir -p "$HOME/control/pkg"
cp -r sub "$HOME/control/"
cp Shared.roc "$HOME/control/pkg/"
printf 'package [Shared] {}\n' >"$HOME/control/pkg/main.roc"
sed -i 's#"../Shared.roc"#"../pkg/main.roc"#' "$HOME/control/sub/main.roc"
grep -Fq '"../pkg/main.roc"' "$HOME/control/sub/main.roc"

check() { # check <dir>: roc check sub/main.roc into $log, sets $status
    status=0
    (cd "$1" && roc check sub/main.roc) >"$log" 2>&1 || status=$?
    cat "$log"
}

echo "--- control: base is a package ---"
check "$HOME/control"
if [ "$status" -ne 0 ] || ! grep -Fq 'No errors found' "$log"; then
    echo "unexpected control result: exit $status"
    exit 1
fi

echo "--- base is ../Shared.roc ---"
check "$HOME/bug"
if [ "$status" -eq 1 ] && grep -Fq 'Shared.value does not exist' "$log" \
    && ! grep -Fq 'sub/main.roc:' "$log"; then
    echo "BUG REPRODUCED: the module path is accepted as a package and Shared.value does not exist"
    exit 0
fi
echo "BUG NOT REPRODUCED (or a different result): exit $status"
exit 1
