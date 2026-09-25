# BUG-008: Interpolating a reserved word in an imported module panics

Found with Roc `nightly-2026-09-23-c7852fd`. No platform is needed.

## Description

`M.roc` is a type module whose string interpolates the reserved word `module`:

```roc
M := [].{
	s = "${module}"
}
```

`N.roc` only imports it:

```roc
import M

N := [].{}
```

`roc check M.roc` reports the reserved word as an ordinary error.
`roc check N.roc` panics instead, because canonicalizing `M` as an imported
module records an `invalid_string_interpolation` diagnostic that
`ModuleEnv.diagnosticToReport` does not handle.

## Expected behavior

`roc check N.roc` reports the same error that `roc check M.roc` reports:

```text
I found module here.
That word is reserved by Roc, so it cannot be used as a name in this position.
```

## Actual behavior

```text
thread 724132 panic: Unhandled canonicalize diagnostic in diagnosticToReport: invalid_string_interpolation
Cannot print stack trace: stack tracing is disabled
```

The process aborts with exit status 134 and dumps core.

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
roc check M.roc   # exit 1, reports the reserved word
roc check N.roc   # exit 134, panics
```

### Automated harness

From this directory:

```sh
nix run github:thebrandonlucas/kai -- run repro
```

If `kai` is already on `PATH`, use `kai run repro` instead.

The harness copies the sources to a temporary directory with a fresh cache. It
checks that `roc check M.roc` reports the reserved word, then reports success
only when `roc check N.roc` exits 134 with the expected panic.

## Observations

- **Compilers:** it reproduces on `nightly-2026-09-23-c7852fd` and
  `nightly-2026-09-24-f45bfbe`, the newest nightly on 2026-09-25.
- **Words:** `module`, `platform` and `app` all panic. `if` does not; it
  produces ordinary parse errors instead.
- **Not needed:** a platform, an app, a binding of the reserved word, a
  function, or any use of `M` from `N`. The original code bound the word as a
  local (`platform = x`, then `"${platform}"`) and called the function from an
  app; that panics the same way.
- **Needs interpolation:** binding and returning the word (`module = x`, then
  `module`) in the imported module reports ordinary errors.
- **Source:** on upstream `main` at
  [roc-lang/roc@4ed925d](https://github.com/roc-lang/roc/commit/4ed925d73b)
  (2026-09-25), `src/canonicalize/ModuleEnv.zig` still lists
  `.invalid_string_interpolation` among the diagnostics that
  `diagnosticToReport` panics on. `src/canonicalize/Can.zig` pushes that
  diagnostic when an interpolated expression fails to canonicalize.
- **Upstream status:** no existing issue or PR found on 2026-09-25 for
  `invalid_string_interpolation`, "Unhandled canonicalize diagnostic", or
  reserved-word interpolation.
