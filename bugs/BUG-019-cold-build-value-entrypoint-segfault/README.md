# BUG-019: `roc build` segfaults in lir_gen when a platform provides a value

> **Rechecked 2026-11-05:** still reproduces on nightly-2026-11-03-34bd006, although roc-lang/roc#12559 was closed as completed on 2026-10-26: comment there with the nightly and repro so it can be reopened.

Found with Roc `nightly-2026-10-23-18478ff`, which this repro's shell pins.
`nightly-2026-10-21-5349569` builds the same app. No real host is needed.

## Description

The platform in `platform/` requires `main : Str` and hands it to the host
as a value, not a function:

```roc
main_for_host : Str
main_for_host = main
```

`App.roc` is the smallest app for it:

```roc
app [main] { pf: platform "./platform/main.roc" }

main = "hi"
```

`roc check App.roc` passes, but `roc build App.roc` with an empty cache
segfaults in the `lir_gen` stage, before linking.

## Expected behavior

`roc build App.roc` compiles the app, as `nightly-2026-10-21-5349569` does.

## Actual behavior

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x0

Work in progress on thread 2448737 (main), outermost first:
  post-check    lir_gen
```

`roc build` exits with status 139.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-10-23-18478ff`,
pinned by this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-23-18478ff
```

Inside that shell, reproduce manually with a fresh cache and an empty
`libhost.a` in place of a host:

```sh
mkdir -p platform/targets/x64musl platform/targets/arm64musl
: > platform/targets/x64musl/libhost.a
: > platform/targets/arm64musl/libhost.a
XDG_CACHE_HOME=$(mktemp -d) roc build App.roc --output=app
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the app and platform to a temporary directory, adds empty
`libhost.a` files and checks that `roc check App.roc` passes. Then it runs
`roc build App.roc` with an empty cache. It reports success only when that
build exits 139 with a segfault in `lir_gen`.

## Observations

- **Regression:** `nightly-2026-10-21-5349569` builds the app ("BUG NOT
  REPRODUCED: roc build exited successfully"); `nightly-2026-10-23-18478ff`
  segfaults on every run.
- **Value, not type:** `main : U64` with `main = 42` crashes the same way.
- **Function entry point:** with `main_for_host : {} -> Str` and
  `main_for_host = |{}| main`, the build succeeds.
- **Cache:** running `roc check App.roc` first with the same
  `XDG_CACHE_HOME` makes the following `roc build` succeed. Only a build with
  an empty cache crashes.
- **Platform source:** the crash is the same for a local platform path and a
  bundled platform fetched by URL (found through BUG-010's harness, whose
  first build crashes this way on this nightly).

## Upstream status

Not reported upstream yet. Searching roc-lang/roc issues for "lir_gen" on
2026-10-25 found no matching segfault.
[roc-lang/roc#12559](https://github.com/roc-lang/roc/issues/12559) (open,
"--opt=speed build hangs when a Dict value is the empty record {}", since
nightly-2026-10-23) is another build regression from the same nightly whose
report mentions `lir_gen`, and may be related.
