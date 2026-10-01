# BUG-014: Interpolating `var` in an imported module panics

Found with Roc `nightly-2026-09-19-d025939`, which this repro's shell pins.
Fixed in `nightly-2026-09-26-d6267b4`. No platform is needed.

## Description

`Mod.roc` is a type module whose string interpolates the keyword `var`:

```roc
Mod := [].{
	s = "${var}"
}
```

`N.roc` only imports it:

```roc
import Mod

N := [].{}
```

`roc check Mod.roc` reports the keyword as an ordinary error (exit 1).
`roc check N.roc` panics instead, because canonicalizing `Mod` as an imported
module records an `invalid_string_interpolation` diagnostic that
`diagnosticToReport` does not handle.

## Expected behavior

`roc check N.roc` reports the same error that `roc check Mod.roc` reports:

```text
I found var here.
That word is reserved by Roc, so it cannot be used as a name in this position.
```

## Actual behavior

```text
thread 278318 panic: Unhandled canonicalize diagnostic in diagnosticToReport: invalid_string_interpolation
Cannot print stack trace: stack tracing is disabled
```

The process aborts with exit status 134 and dumps core.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-19-d025939`,
pinned by this repro's `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-19-d025939
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
roc check Mod.roc   # exit 1, reports the keyword
roc check N.roc     # exit 134, panics
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache. It
checks that `roc check Mod.roc` reports the keyword, then reports success only
when `roc check N.roc` exits 134 with the expected panic.

## Observations

- **Original code:** in Aristos, a type module declared a top-level constant
  named `var` (`var : Str`, `var = "X"`) and interpolated it
  (`message = "set ${var}"`); an app on basic-cli 0.22.2 imported the module
  and printed `Mod.message`. That panics the same way. The declaration, the
  annotation and the app are not needed.
- **Same root cause as BUG-008:** BUG-008 (removed after its fix) panicked the
  same way when interpolating the reserved words `module`, `platform` or
  `app` in an imported module. This is the same panic with `var`, on an older
  nightly than BUG-008 was found on.
- **Compilers:** the harness reproduces the panic on
  `nightly-2026-09-19-d025939`, `nightly-2026-09-24-f45bfbe` and
  `nightly-2026-09-25-1ab6804`.
- **Workaround:** rename the constant (Aristos renamed it to `name`).

## Upstream status

Fixed by [roc-lang/roc#11718](https://github.com/roc-lang/roc/pull/11718)
("Canonicalize malformed expressions to unreported runtime errors", merged
2026-09-26), the fix for BUG-008's
[roc-lang/roc#11709](https://github.com/roc-lang/roc/issues/11709). Checked on
2026-09-28: on `nightly-2026-09-26-d6267b4`, `roc check N.roc` reports the
keyword as an ordinary error (exit 1) without panicking, and the original
Aristos module reports `var outside body` (`` `var` appeared outside a
function or block body``).
