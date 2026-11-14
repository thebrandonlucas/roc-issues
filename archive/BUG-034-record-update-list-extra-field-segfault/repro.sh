#!/usr/bin/env bash
# Reproduces BUG-034: `roc check` crashes in the type-check of Project when a
# record update of an imported nominal record gives its list field an element
# with a field the element type lacks.
#
# Whether it crashes can vary between runs, so after one `--jobs=1` run this
# tries the default worker count up to 10 times, each with a fresh cache.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-034-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
log="$HOME/check.log"

echo "roc version: $(roc version)"
mkdir -p "$HOME/bug" "$HOME/control"
cp main.roc Model.roc Project.roc "$HOME/bug/"
# Control: the same update with an element of the right type.
cp main.roc Model.roc "$HOME/control/"
sed 's/{ name: "a", extra: Bool.False }/{ name: "a" }/' Project.roc >"$HOME/control/Project.roc"
grep -Fq 'items: [{ name: "a" }]' "$HOME/control/Project.roc"

check() { # check <dir> [args...]: roc check Project.roc with a fresh cache
    local dir=$1; shift
    rm -rf "$HOME/.cache"
    (cd "$dir" && XDG_CACHE_HOME="$HOME/.cache" timeout 120 roc check "$@" Project.roc) >"$log" 2>&1
}

echo "--- control: items: [{ name: \"a\" }] ---"
if ! check "$HOME/control" --jobs=1; then
    cat "$log"
    echo "unexpected control result: the well-typed update fails to check"
    exit 1
fi
cat "$log"

for run in 1 2 3 4 5 6 7 8 9 10 11; do
    args=()
    [ "$run" -eq 1 ] && args=(--jobs=1)
    echo "--- run $run: roc check ${args[*]:-} Project.roc ---"
    status=0
    check "$HOME/bug" "${args[@]}" || status=$?
    cat "$log"
    echo "exit status: $status"
    if { [ "$status" -eq 139 ] || [ "$status" -eq 134 ]; } \
        && grep -Eq 'type-check +module Project' "$log"; then
        echo "BUG REPRODUCED: roc check crashed (exit $status) in the type-check of Project"
        exit 0
    fi
    if [ "$status" -ne 1 ]; then
        echo "unexpected result: exit $status without the expected crash"
        exit 1
    fi
done
echo "BUG NOT REPRODUCED: every run reported a type error"
exit 1
