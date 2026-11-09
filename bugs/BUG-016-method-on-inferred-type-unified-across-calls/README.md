# Two calls of one method on an inferred type get a single type

> **Rechecked 2026-11-09:** still reproduces on nightly-2026-11-09-9e85de7, without a platform.

Found with Roc `nightly-2026-10-21-5349569`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-016-method-on-inferred-type-unified-across-calls) pins.
`nightly-2026-09-26-d6267b4` compiled the same code. Uses basic-cli 0.26.0
only for printing.

## Description

In an unannotated function, `command.args` has an inferred type. Calling
`keep_oks` on it twice, once keeping `Name`'s payload and once `Count`'s,
should check each call on its own. Instead the compiler records a single
`keep_oks` requirement for both calls, so the two lambdas' types are merged:
the tag union becomes `[Count(U64), Name(U64)]`, one payload type for both
tags, and `List.keep_oks` no longer matches it at the call site.

## Expected behavior

`main.roc` compiles and prints `(["a"], [2])`.

## Actual behavior

```text
── ✗ type mismatch ────────────────────────────── main.roc:30:41
The keep_oks method on List has an incompatible type.
Stdout.line!(Str.inspect(split({ args: args })))
                                       ^^^^
The method keep_oks has the type:
    List(Arg), (Arg -> Try(after, _err)) -> List(after)
But I need it to have the type:
    List(Arg), ([Count(U64), Name(U64)] -> [Err({}), Ok(U64), ..]) -> _ret
```

Annotating the two results instead reports that a type "would need two
different, incompatible keep_oks methods".

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-016-method-on-inferred-type-unified-across-calls), enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by its `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

Inside that shell, reproduce manually with:

```sh
roc check main.roc
```

### Automated harness

From the same directory of [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-016-method-on-inferred-type-unified-across-calls):

```sh
nix develop . --command bash repro.sh
```

The harness copies `main.roc` to a temporary directory with a fresh cache, so
it downloads basic-cli 0.26.0 and needs network access. It reports success only
when the merged `[Count(U64), Name(U64)]` type appears.

## Observations

- **Annotation:** with `split : { args : List(Arg) } -> (List(Str), List(U64))`
  the code compiles. The bug needs the receiver's type to be inferred.
- **Workaround:** calling the function form, `List.keep_oks(command.args, ...)`,
  compiles, since each call of a function is instantiated on its own.
- **Regression:** the platform of [Kai](https://github.com/thebrandonlucas/kai) (a CLI for Nix and Guix written in Roc) had this shape and compiled with
  `nightly-2026-09-26-d6267b4`.
