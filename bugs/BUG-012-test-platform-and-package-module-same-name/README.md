# BUG-012: `roc test` panics when a platform and its package both have a module with the same name

Found with Roc `nightly-2026-09-26-d6267b4`, the newest nightly on
2026-09-27, which this repro's shell pins. No host is needed.

## Description

The platform in `platform/` has a module `S` (not exposed) and depends on a
package `lib`:

```roc
platform ""
	requires {
		main : Str
	}
	exposes []
	packages {
		lib: "../lib/main.roc",
	}
	provides { "roc_main": main_for_host }

import S
import lib.Twice

main_for_host : Str
main_for_host = Twice.twice(S.wrap(main))
```

`lib` has its own module that is also named `S` (here a copy of the
platform's file):

```roc
# lib/Twice.roc
import S

Twice := [].{
	twice : Str -> Str
	twice = |s| S.wrap(S.wrap(s))
}
```

`App.roc` is an ordinary app on the platform. `roc check App.roc` succeeds
and `roc test lib/main.roc` passes, but `roc test App.roc` panics.

## Expected behavior

`roc test App.roc` runs the expects of the app and of every module it
compiles, as `roc check` checks them:

```text
All (3) tests passed in ...
```

## Actual behavior

```text
thread 120090 panic: compiled module plan contains duplicate source module /tmp/dup/platform/main.roc.S
Cannot print stack trace: stack tracing is disabled
```

The exit status is 134 (SIGABRT).

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-26-d6267b4`,
pinned by this repro's `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-26-d6267b4
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
roc check App.roc        # exit 0
roc test lib/main.roc    # exit 0
roc test App.roc         # exit 134, panics
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache.
It checks that `roc check App.roc` and `roc test lib/main.roc` succeed, then
reports success only when `roc test App.roc` fails with the duplicate module
panic.

## Observations

- **Only `roc test`:** `roc check App.roc` and running the app
  (`roc App.roc`) work, and so do `roc check` and `roc test` of `lib` alone.
- **The shared name is the trigger:**
  - Renaming `lib`'s module to `T` makes `roc test App.roc` pass (3 tests).
  - So does removing `S` from `lib`, or the platform not depending on `lib`.
  - It still panics when the platform exposes `S`, and when `lib` imports
    the platform's own `S.roc` file through a second package root
    (`package [S] {}` beside the platform's `main.roc`).
- **The panic names the platform's module** (`platform/main.roc.S`), even
  when the files differ.
- **How it was found:** Kai's platform has modules named `Sexpr` and `Plan`,
  and so does a package the platform depends on. As a result, no app or
  plugin package on Kai's platform can run `roc test`.
- **Upstream status:** no existing issue or PR found on 2026-09-27.
  roc-lang/roc#10715 (merged 2026-08-10, "Resolve every import naming one
  source module to one environment") changed how same-named imports resolve,
  but is not about the test runner.
