#!/usr/bin/env bash
# Reproduces BUG-017: `roc build --opt=size` emits different binaries for the
# same source, depending on the number of worker threads (`--jobs`) and, on
# newer nightlies, between builds with the same worker count.
set -eu
cd "$(dirname "$0")"

# Kai's CLI at a pinned commit: the smallest program found to show the effect.
kai_repo=https://github.com/thebrandonlucas/kai.git
kai_rev=3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3
# Worker count compared against --jobs=1, and how many builds to make with it.
jobs_n=${JOBS_N:-2}
repeats=${REPEATS:-2}

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

names=(jobs1)
labels=("--jobs=1")
build jobs1 --jobs=1
for i in $(seq 1 "$repeats"); do
    names+=("jobsN-$i")
    labels+=("--jobs=$jobs_n (#$i)")
    build "jobsN-$i" --jobs="$jobs_n"
done
names+=(default)
labels+=("default --jobs")
build default

sums=()
for i in "${!names[@]}"; do
    sums[i]=$(sha256sum "$out/${names[$i]}" | cut -d' ' -f1)
    printf '%-20s %s\n' "${labels[$i]}:" "${sums[$i]}"
done

# Any two builds of the same source that differ reproduce the bug; say which.
differ=
n_last=$repeats
for i in $(seq 2 "$n_last"); do
    if [ "${sums[$i]}" != "${sums[1]}" ]; then
        differ="${differ}--jobs=$jobs_n builds #1 and #$i differ; "
    fi
done
for i in $(seq 1 "$n_last"); do
    if [ "${sums[$i]}" != "${sums[0]}" ]; then
        differ="${differ}--jobs=1 and --jobs=$jobs_n #$i differ; "
    fi
done
last=$((${#sums[@]} - 1))
for i in $(seq 0 $((last - 1))); do
    if [ "${sums[$last]}" != "${sums[$i]}" ]; then
        differ="${differ}the default --jobs build differs from ${labels[$i]}; "
    fi
done
if [ -n "$differ" ]; then
    echo "BUG REPRODUCED: builds of the same source differ (${differ%; })"
    exit 0
fi
echo "BUG NOT REPRODUCED: all ${#sums[@]} builds are identical"
exit 1
