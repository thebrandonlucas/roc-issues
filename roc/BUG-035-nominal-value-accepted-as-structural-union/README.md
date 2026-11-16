# A nominal tag union value is accepted where a structural tag union of the same shape is annotated

A value of a nominal tag union type is accepted where an annotation asks
for a structural tag union with the same tags, and it keeps the nominal type
there. `plain : [Red, Green]` holds `Color.Red`, and `Color.plain.name()`
calls `Color`'s method on it; `roc check` reports no errors and `roc test`
passes. The langref says no other tag union is equivalent to a nominal one,
even with the same shape, so this should be a type mismatch.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

In this directory: `Color.roc`, a type module `Color := [Red, Green]` with a
method `name` and a value `plain : [Red, Green]` set to `Color.Red`, and an
`expect` that calls `Color.plain.name()`. `Light.roc` is the control: the
same kind of annotation with a different shape.

### Command

```
roc check Color.roc
```

### Observed

```
No errors found in 23ms for Color.roc
```

`roc test Color.roc` prints `All (1) tests passed`.

### Expected

A type mismatch at `plain = Color.Red`: it has the type `Color`, but the
annotation says `[Red, Green]`.

### Notes

- With a different shape (`Light.roc`: `Light -> [Red, Green, Blue]` for
  `Light := [Red, Green]`) the mismatch is reported.
- Two nominal types of the same shape are not mixed: `Color -> Light` with
  `|c| c` is a type mismatch.
- The builtin `Try` behaves the same: a function annotated
  `Try(U64, Str) -> [Ok(U64), Err(Str)]` with body `|t| t` checks, and its
  result is still a `Try(U64, Str)`, so `Json.to_str` of it asks `Try` for
  `encoder_for`.
- `nightly-2026-10-21-5349569` behaves the same.

### Shell with the exact compiler

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-035-nominal-value-accepted-as-structural-union),
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

The script first checks `Light.roc`, which must report the type mismatch,
then accepts only a `roc check Color.roc` with no errors and a passing
`roc test Color.roc`.
