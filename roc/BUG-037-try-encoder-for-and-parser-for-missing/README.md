# `Json.to_str` and `Json.parse` say the builtin `Try` has no `encoder_for` or `parser_for`

The builtin `Try(ok, err) := [Ok(ok), Err(err)]` declares `parser_for : _`
and `encoder_for : _` in `Builtin.roc`, but `Json.to_str` of a
`Try(Str, Str)` fails `roc check` with "missing method", saying the type has
no `encoder_for`, and `Json.parse` into one says it has no `parser_for`. A
nominal tag union of the same shape declared in the app, with
`encoder_for : _`, encodes as `{"Ok":"x"}`. `Try` should behave the same.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

In this directory: `Probe.roc`, a type module with a local
`Outcome(ok, err) := [Ok(ok), Err(err)]` that declares `encoder_for : _`, a
value of `Outcome(Str, Str)` and one of `Try(Str, Str)`, and an `expect`
that encodes each with `Json.to_str`. `Parse.roc` parses `{"Ok":"x"}` into
a `Try(Str, Str)`.

### Command

```
roc check Probe.roc
roc check Parse.roc
```

### Observed

```
── ✗ missing method ───────────────────────────────────────────── Probe.roc:14:8

A where clause requires the encoder_for method here, but the type being used
doesn't have that method.

expect Json.to_str(Probe.theirs) == "{\"Ok\":\"x\"}"
       ^^^^^^^^^^^^^^^^^^^^^^^^^

The value's type, which does not have a method named encoder_for, is:

    Try(Str, Str)
```

`roc check Parse.roc` reports the same for `parser_for`, at the
`Json.parse` call.

### Expected

No errors: `Try(Str, Str)` uses the `encoder_for` and `parser_for` it
declares, as `Outcome(Str, Str)` does.

### Notes

- Without the last `expect`, `roc test Probe.roc` passes: `Outcome` encodes
  as `{"Ok":"x"}`.
- A record field of type `Try(a, [Missing])` does parse and encode (an
  absent field), as docs/langref/parsers.md describes.
- `nightly-2026-10-21-5349569` behaves the same.

### Shell with the exact compiler

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-037-try-encoder-for-and-parser-for-missing),
`nix develop .` gives `nightly-2026-11-14-a87808d`, the newest nightly in
its pinned roc-overlay:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-14-a87808d
```

### Harness

```sh
nix develop . --command bash repro.sh              # BUG REPRODUCED
nix develop ../..#latest --command bash repro.sh   # BUG REPRODUCED
```

The script first runs `roc test` on `Probe.roc` without its last `expect`,
which must pass, then accepts only the missing `encoder_for` on
`Try(Str, Str)` at `Probe.roc:14` and the missing `parser_for` in
`Parse.roc`.
