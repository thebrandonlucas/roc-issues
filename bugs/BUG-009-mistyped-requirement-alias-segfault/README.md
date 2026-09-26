# BUG-009: A mistyped platform requirement segfaults when its nominal type holds a tag-union alias

Found with Roc `nightly-2026-09-23-c7852fd`. Still reproduces on
`nightly-2026-09-26-d6267b4`, the newest nightly on 2026-09-26, which this
repro's shell pins. No host or package is needed.

## Description

The platform in `platform/` requires `main : P`. `P` is a nominal record whose
field type is `Step`, a tag-union alias declared in `P`'s own associated
block:

```roc
P := { step : Step }.{
	Step : [Run(Str)]

	name : P -> Str
	name = |_| "p"
}
```

The platform passes the app's `main` to `P.name` in a top-level constant, so
it is evaluated at compile time:

```roc
main_for_host : Str
main_for_host = P.name(main)
```

`App.roc` provides a value of the wrong type:

```roc
app [main] { pf: platform "platform/main.roc" }

main = 42
```

`roc check App.roc` segfaults instead of reporting the type mismatch.

## Expected behavior

`roc check App.roc` reports the mismatch, as it does when `Step` is declared
as a nominal type (`Step := [Run(Str)]`) instead of an alias:

```text
── ✗ type mismatch ───────────────────────────────────────────────── App.roc:3:8

This number is being used where a non-number type is needed.

main = 42
       ^^

Other code expects this to have the type:

    P
```

## Actual behavior

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0xa4

Stack trace:
Cannot print stack trace: stack tracing is disabled

Please report this issue at: https://github.com/roc-lang/roc/issues
```

The exit status is 139. The fault address differs between compilers and runs
(`0x0` on `c7852fd`).

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
roc check Valid.roc   # exit 0, a well-typed app
roc check App.roc     # exit 139, segfaults
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache. It
checks that the well-typed `Valid.roc` passes and that `App.roc` reports a type
mismatch once `Step` is changed to a nominal type. It then reports success only
when `roc check App.roc` exits 139 with the expected segfault.

## Observations

- **Compilers:** it reproduces on `nightly-2026-09-23-c7852fd`,
  `nightly-2026-09-24-f45bfbe`, `nightly-2026-09-25-1ab6804` and
  `nightly-2026-09-26-d6267b4`.
- **Commands:** `roc build` and `roc App.roc` also segfault once the platform
  has a `targets:` section (an empty `libhost.a` is enough).
- **Still crashes:**
  - `Step : [Run, Stop]` (no payloads).
  - `P := Step` instead of a record.
  - A wrong type other than a number, such as `main = "x"`.
  - On `d6267b4`, the platform using `Str.inspect(main)` instead of
    `P.name(main)`. On `c7852fd` that variant reports the type mismatch.
- **Reports the type mismatch instead:**
  - `Step := [Run(Str)]` (a nominal type instead of an alias).
  - The union inlined: `P := { step : [Run(Str)] }`.
  - A record alias: `Step : { s : Str }`.
  - A platform that never uses `main` in a constant.
- **How it was found:** two copies of one package that differed by a comment
  gave two distinct nominal `P` types, which is a correct type error. Because
  `P` held a tag-union alias, the error became this crash.
- **Related upstream:** roc-lang/roc#11525 (closed, fixed by #11599, already in
  `c7852fd`) segfaulted on a nominal record field typed with a tag-union alias
  that falls back to its `??` default. It shares the alias-in-nominal
  ingredient, but its fix does not cover this case.
- **Upstream status:** no existing issue or PR found on 2026-09-26.
