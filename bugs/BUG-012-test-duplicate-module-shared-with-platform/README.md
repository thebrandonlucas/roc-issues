# BUG-012: `roc test` panics when a platform's package imports the platform's own module file

Found with Roc `nightly-2026-09-26-d6267b4`, the newest nightly on
2026-09-27, which this repro's shell pins. No host is needed.

## Description

The platform in `platform/` exposes a module `S` and depends on a package
`lib`:

```roc
platform ""
	requires {
		main : Str
	}
	exposes [S]
	packages {
		lib: "../lib/main.roc",
	}
	provides { "roc_main": main_for_host }
```

A second root file in the platform directory, `platform/api.roc`, makes the
same `S.roc` file available as a package, for code that cannot import a
platform:

```roc
package [S] {}
```

`lib` imports `S` through that package:

```roc
package [Twice] {
	api: "../platform/api.roc",
}
```

`App.roc` is an ordinary app on the platform. `roc check App.roc` succeeds
and `roc test lib/main.roc` passes, but `roc test App.roc` panics. The same
happens for `roc test` of any package that depends on the platform.

## Expected behavior

`roc test App.roc` runs the app's and modules' expects, as `roc check` checks
them:

```text
All (2) tests passed in ...
```

## Actual behavior

```text
thread 119777 panic: compiled module plan contains duplicate source module /tmp/dup/platform/main.roc.S
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
roc test lib/main.roc    # exit 0, 1 test passed
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
  (`roc App.roc`) work; so do `roc check` and `roc test` of `lib` alone.
- **Needs the shared file:** with `lib` owning its own copy of `S.roc`
  (no `api.roc`), `roc test App.roc` passes. The panic names the
  platform's module (`platform/main.roc.S`) even though the second import
  goes through `api.roc`.
- **Related upstream:** roc-lang/roc#10715 (merged 2026-08-10, "Resolve
  every import naming one source module to one environment") made both
  imports resolve to one module, which is why `roc check` accepts this
  layout; the test runner's module plan apparently still lists it twice.
- **How it was found:** Kai's platform exposes its protocol modules and
  also serves them to Kai's CLI and a package the platform depends on
  through such a second root, so no app or plugin package on Kai's
  platform can run `roc test`.
- **Upstream status:** no existing issue or PR found on 2026-09-27.
