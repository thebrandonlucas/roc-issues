# BUG-017: the code `roc build` emits depends on the worker count

Found with Roc `nightly-2026-10-21-5349569`, which this repro's shell pins,
on x86_64 Linux. The program is the
[Kai](https://github.com/thebrandonlucas/kai) CLI at commit `3fd862f`, a
basic-cli 0.26.0 app.

## Description

Building the same source with the same flags gives a byte-identical binary
each time only as long as the number of worker threads stays the same.
`roc build --opt=size --target=x64musl` with `--jobs=1` emits a different
binary from `--jobs=2` or `--jobs=8` (the default on an 8-core host), so a
build's output depends on the machine it runs on.

Smaller programs did not show the difference: a hello world and a program of
150 small functions over 6 modules were identical across worker counts. The
repro therefore builds Kai's CLI at a pinned commit.

## Expected behavior

`roc build` emits the same binary for the same source, flags and target,
whatever `--jobs` is.

## Actual behavior

Repeated builds with one worker count match each other, but different
worker counts give different binaries (here the default was 8 workers):

```text
roc build cli/main.roc --opt=size --target=x64musl --jobs=1
roc build cli/main.roc --opt=size --target=x64musl --jobs=2
roc build cli/main.roc --opt=size --target=x64musl --jobs=2
roc build cli/main.roc --opt=size --target=x64musl
--jobs=1:            e1754b5210221e57da3510fd6d1a970b1f92cb1ce934545a01fda303bee5550b
--jobs=2 (first):    cf3d5e256fcab88b7c40d294f7c3bc48389c2d7a2f7469684765d80083d41c43
--jobs=2 (repeat):   cf3d5e256fcab88b7c40d294f7c3bc48389c2d7a2f7469684765d80083d41c43
default --jobs:      4694f6991d2912de2eaaf23ea553dd66b1481306a2f0ffda02a6f288f19d4356
BUG REPRODUCED: --jobs=1 and --jobs=2 emit different binaries
```

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

Inside that shell, reproduce manually from a checkout of Kai at
`3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3`:

```sh
roc build cli/main.roc --opt=size --target=x64musl --jobs=1 --output=kai-1
roc build cli/main.roc --opt=size --target=x64musl --jobs=2 --output=kai-2
sha256sum kai-1 kai-2
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness fetches Kai's whole source tree at the pinned commit (its
`cli/main.roc` imports `../platform/api.roc` and reads files from the
repository root) into a temporary directory with a fresh cache, so it
downloads basic-cli 0.26.0 and needs network access. It builds with
`--jobs=1`, twice with `--jobs=2` (set `JOBS_N` to compare another count) and
once with the default, then compares sha256 sums. It reports success only
when the two `--jobs=2` builds match and differ from the `--jobs=1` build.

## Observations

- **Deterministic per worker count:** repeated builds with the same `--jobs`
  are byte-identical, so the difference is not random; it follows from how
  work is split between workers.
- **Program size:** small programs did not differ; Kai's CLI is the smallest
  program found that does.
- **Workaround:** Kai builds its release binaries with `--jobs=1`, so their
  output does not depend on the build host's core count.

## Upstream status

Not reported upstream yet.
[roc-lang/roc#11449](https://github.com/roc-lang/roc/issues/11449), whose title
notes that the "worker count also changes emitted LIR" (open), is likely
related; this repro shows the effect on optimized binaries.
