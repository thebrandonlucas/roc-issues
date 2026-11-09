# A type mismatch on an interpolated string literal is reported at a different expression

Found with Roc `nightly-2026-10-21-5349569`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-024-interpolated-literal-mismatch-wrong-region) pins.
Still reproduces on `nightly-2026-10-23-18478ff`, the newest nightly on
2026-10-23. No platform is needed.

## Description

`App.roc` puts an interpolated string literal and a value of a non-string type
in the same list:

```roc
version = "1.0"

number : I64
number = 1

list = ["v${version}", number]

main! = |_| Ok({})
```

The type mismatch itself is correct: the list's elements must share one type,
and `I64` is not a string. But the report blames the string literal while
pointing at `number`, so the region and the message disagree and the literal
that needs changing is never shown.

`Plain.roc` is the same program with a plain literal, `["v1.0", number]`. It
reports the mismatch at the literal.

## Expected behavior

`roc check App.roc` reports the mismatch at the interpolated string literal,
as `roc check Plain.roc` does for the plain one:

```text
── ✗ type mismatch ──────────────────────────────────────────────── App.roc:6:9

This string literal is being used where a non-string type is needed.

list = ["v${version}", number]
        ^^^^^^^^^^^^^

The type was determined to be:

    I64
```

## Actual behavior

```text
── ✗ type mismatch ─────────────────────────────────────────────── App.roc:6:24

This string literal is being used where a non-string type is needed.

list = ["v${version}", number]
                       ^^^^^^

The type was determined to be:

    I64

── 1 error and 0 warnings ────────────────────────────────────────────── App.roc
```

The exit status is 1.

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-024-interpolated-literal-mismatch-wrong-region), enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by its `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
roc check Plain.roc   # exit 1, mismatch reported at the literal (Plain.roc:4:9)
roc check App.roc     # exit 1, mismatch reported at `number` (App.roc:6:24)
```

### Automated harness

From the same directory of [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-024-interpolated-literal-mismatch-wrong-region):

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache. It
checks that `Plain.roc` reports the mismatch at its string literal. It then
reports success only when `roc check App.roc` reports the string literal
mismatch at `number` (`App.roc:6:24`) instead of at the interpolated literal
(`App.roc:6:9`).

## Observations

- **Compilers:** it reproduces on `nightly-2026-10-21-5349569` and
  `nightly-2026-10-23-18478ff`.
- **Reported at the other expression:**
  - The other element comes after the interpolated literal, even with plain
    literals between them: `["v${version}", "w", number]` points at `number`.
  - `if` branches: `|b| if b "v${version}" else number` points at `number`.
  - A nominal type whose `from_quote` lets plain literals have that type, in
    place of `I64`.
  - Nested lists whose inner type comes from another definition: with
    `roc : List(Tool)` and `roc = []`, `[["roc.${version}"], roc]` points at
    the `[]` in `roc = []`, in a different definition.
- **Reported at the interpolated literal:**
  - The other element comes first: `[number, "v${version}"]`.
  - An annotation fixes the type: `list : List(I64)` with
    `list = ["v${version}"]`.
- **How it was found:** a configuration file built a `List(Tool)`, where
  `Tool` has `from_quote`, as `["rocpkgs.${version}", "zig", ...]` inside one
  tag of a larger unannotated list. The error was reported about 40 lines
  further down, at an unrelated `roc.concat([` call in another tag whose
  payload had to unify with this one.
- **Related upstream:** roc-lang/roc#12249 and roc-lang/roc#12319 (both
  merged before `5349569`) moved other interpolation errors to the
  interpolation; roc-lang/roc#12213 (closed) is another misleading report for
  interpolated values. None covers this case.
- **Upstream status:** no existing issue or PR found on 2026-10-23.
