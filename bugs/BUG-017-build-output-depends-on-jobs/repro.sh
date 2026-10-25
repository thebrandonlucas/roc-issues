#!/usr/bin/env bash
# Reproduces BUG-017: `roc build --opt=size` emits a different binary for the
# same source depending on the number of worker threads (`--jobs`).
set -eu
cd "$(dirname "$0")"

# Kai's CLI at a pinned commit: the smallest program found to show the effect.
kai_repo=https://github.com/thebrandonlucas/kai.git
kai_rev=3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3
# Worker count compared against --jobs=1.
jobs_n=${JOBS_N:-2}

tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/bug-017-home.XXXXXX")
trap 'rm -rf "$tmp_home"' EXIT
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
src="$HOME/kai"
out="$HOME/out"
mkdir -p "$src" "$out"

echo "roc version: $(roc version)"
echo "fetching kai at $kai_rev"
git -C "$src" init -q
git -C "$src" fetch -q --depth 1 "$kai_repo" "$kai_rev"
git -C "$src" checkout -q FETCH_HEAD

cd "$src"
build() { # name, extra roc args...
    local name=$1
    shift
    echo "roc build cli/main.roc --opt=size --target=x64musl${*:+ $*}"
    if ! timeout 900 roc build cli/main.roc --opt=size --target=x64musl \
        --output="$out/$name" "$@" >"$out/$name.log" 2>&1; then
        cat "$out/$name.log"
        echo "BUG NOT REPRODUCED or unexpected output: build $name failed"
        exit 1
    fi
}
build jobs1 --jobs=1
build jobsN-a --jobs="$jobs_n"
build jobsN-b --jobs="$jobs_n"
build default

sum() { sha256sum "$out/$1" | cut -d' ' -f1; }
j1=$(sum jobs1)
na=$(sum jobsN-a)
nb=$(sum jobsN-b)
def=$(sum default)
printf '%-20s %s\n' "--jobs=1:" "$j1" "--jobs=$jobs_n (first):" "$na" \
    "--jobs=$jobs_n (repeat):" "$nb" "default --jobs:" "$def"

if [ "$na" != "$nb" ]; then
    echo "BUG NOT REPRODUCED or unexpected output: repeated --jobs=$jobs_n builds differ"
    exit 1
fi
if [ "$j1" != "$na" ]; then
    echo "BUG REPRODUCED: --jobs=1 and --jobs=$jobs_n emit different binaries"
    exit 0
fi
echo "BUG NOT REPRODUCED or unexpected output: --jobs=1 and --jobs=$jobs_n match"
exit 1
