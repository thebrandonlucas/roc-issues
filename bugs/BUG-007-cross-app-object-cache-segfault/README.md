# BUG-007: A shared object cache segfaults a second app's dev build

Found with Roc `nightly-2026-09-23-c7852fd` and basic-cli built from source at
[roc-lang/basic-cli@473caa2](https://github.com/roc-lang/basic-cli/commit/473caa2cc4f3fe9ce4e4682158bb80ebc2e19169)
(PR #499).

## Description

`Primer.roc` and `Repro.roc` are two apps on the same platform that both import
the local module `Lib.roc`. `Primer.roc` does not use `Lib`; `Repro.roc` calls
`Lib.parse`. Each app checks cleanly and builds cleanly on a cold cache.

When both apps build with `--opt=dev` and share one cache, building `Primer.roc`
first writes an object pack for `Lib`. Building `Repro.roc` next loads that pack
(`pack hits: 15`) and segfaults the compiler.

`Lib.roc` was reduced from basic-cli's `Url` module, where the bug first
appeared: any basic-cli app built after another basic-cli app in the same
cache could crash once it called `Url.parse`.

## Expected behavior

`roc build Repro.roc --opt=dev` succeeds whether or not `Primer.roc` was built
first. It succeeds with `--no-cache`, and on a cold cache.

## Actual behavior

```text
pack hits: 15 external procs: 7 evaluator artifacts: 0 packs loaded: 31 keys: 385

Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x20

Stack trace:
Cannot print stack trace: stack tracing is disabled

Please report this issue at: https://github.com/roc-lang/roc/issues
```

The exit status is 139.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-23-c7852fd`,
pinned by this repro's `Kaifile` and `Kaifile.lock`:

```sh
nix run github:thebrandonlucas/kai -- shell repro
roc version # verify the compiler build contains c7852fd
```

If `kai` is already on `PATH`, use `kai shell repro` instead. The root
`nix develop` shell selects a different compiler; use this per-repro shell.

Inside that shell, reproduce manually with:

```sh
ln -s "$(nix build path:$PWD/platform --no-link --print-out-paths)" .basic-cli
export XDG_CACHE_HOME=$(mktemp -d)
roc build Primer.roc --opt=dev --output=primer
roc build Repro.roc --opt=dev --output=repro   # exit 139
```

### Automated harness

From this directory:

```sh
nix run github:thebrandonlucas/kai -- run repro
```

If `kai` is already on `PATH`, use `kai run repro` instead.

The harness builds the platform, copies the sources to a temporary directory
with a fresh cache, and checks that `Repro.roc` builds with `--no-cache`. It
then builds `Primer.roc` and `Repro.roc` and reports success only when the
second build exits 139 with the expected segfault.

## Platform

No published basic-cli release works with this compiler: `roc check` hangs on
0.22.2 and 0.23.0-rc1 (see roc-lang/roc#11621). `platform/flake.nix` therefore
builds basic-cli 473caa2 from source. Its `flake.lock` pins nixpkgs,
rust-overlay and the basic-cli source. The build only works on Linux, and the
first run compiles the Rust host.

## Observations

- **Compilers:** it reproduces on `nightly-2026-09-22-e494788`,
  `nightly-2026-09-23-c7852fd` and `nightly-2026-09-24-f45bfbe`, the newest
  nightly on 2026-09-25.
- **Backends:** only `--opt=dev` crashes. `--opt=speed`, `--opt=size` and
  `--opt=interpreter` builds of the same sequence succeed.
- **Cache:** `--no-cache` avoids the crash, and so does a cold cache.
  Rebuilding `Repro.roc` after its own cold build also succeeds.
- **The failing cache entry:** in the original failure, deleting cache entries
  left exactly one object pack required: basic-cli's `Url` module, written by an
  app that never used `Url`. The pack for that module has the same key in every
  app, but its contents differ from app to app.
- **Changes that make the crash disappear:**
  - Wrapping the function value in a lambda:
    `List.all(bytes, |b| is_hex(b))` instead of `List.all(bytes, is_hex)` in
    `parse_hex_groups`.
  - Removing that `List.all(bytes, is_hex)` call.
  - Removing `query_pairs`, even though `Repro.roc` never calls it.
  - Removing either branch of `parse_authority`.
  - Any warning in `Lib.roc`, such as an unused variable. This probably
    disables caching for the module.
- **Not needed:** `roc check` before the builds, or `Primer.roc` using `Lib` at
  all.
- **Related upstream:** roc-lang/roc#11673 (fixed by #11676 on 2026-09-25,
  after the newest nightly) is a warm-cache failure where a module pack caches
  a function passed as a value under a key that does not cover its lambda set.
  roc-lang/roc#11627 (open) reports that a pack's contents depend on more than
  its module and imports. This repro may share either root cause.
