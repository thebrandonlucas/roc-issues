#!/usr/bin/env bash
# Reproduces BUG-007: a module object pack written by one app's dev build
# segfaults the compiler when another app's dev build reuses it.
set -eu
cd "$(dirname "$0")"

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-007-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
work="$HOME/work"
mkdir -p "$work"
build_log="$HOME/build.log"

echo "roc version: $(roc version)"
echo "--- platform (basic-cli 473caa2, pinned in platform/flake.lock) ---"
platform=$(nix build "path:$PWD/platform" --no-link --print-out-paths)
echo "$platform"
cp Lib.roc Primer.roc Repro.roc "$work/"
ln -s "$platform" "$work/.basic-cli"
cd "$work"

echo "--- control: Repro.roc without the cache ---"
roc build Repro.roc --opt=dev --no-cache --output="$HOME/control"

echo "--- build Primer.roc (fills the shared cache) ---"
roc build Primer.roc --opt=dev --output="$HOME/primer"

echo "--- build Repro.roc (reuses Primer's object pack for Lib) ---"
if roc build Repro.roc --opt=dev --output="$HOME/repro" >"$build_log" 2>&1; then
    cat "$build_log"
    echo "BUG NOT REPRODUCED: roc build exited successfully"
    exit 1
else
    status=$?
fi
cat "$build_log"

if [ "$status" -eq 139 ] &&
    grep -Fq 'Segmentation fault (SIGSEGV) in the Roc compiler.' "$build_log" &&
    grep -Fq 'Fault address: 0x20' "$build_log"; then
    echo "BUG REPRODUCED: roc build exited $status with the expected segfault"
    exit 0
fi

echo "unexpected failure: roc build exited $status without the expected segfault"
exit 1
