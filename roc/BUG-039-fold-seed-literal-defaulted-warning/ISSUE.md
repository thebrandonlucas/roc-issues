# A fold's literal seed is reported as "literal defaulted" when the step is `sum + x`

In an annotated function, `list.fold(0, |sum, x| sum + x)` over a `List(U32)`
gets a "literal defaulted" warning on the `0`, which says nothing determines
the literal's type and names `U32` as "the default type". `roc check` and
`roc test` exit with status 2. Written `x + sum`, the same fold has no
warning. The literal can only be a `U32` here, so there should be no warning.

**Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

### Repro

`Fold.roc`:

```roc
Fold := {}

show : List(U32) -> Str
show = |list| list.fold(0, |sum, x| sum + x).to_str()

expect show([2, 3]) == "5"
```

### Command

```
roc check Fold.roc
```

### Observed

```
── ● literal defaulted ─────────────────────────────────────────── Fold.roc:4:25

Nothing in this definition's type determines the type of this number literal,
so it was given the default type U32 instead.

show = |list| list.fold(0, |sum, x| sum + x).to_str()
                        ^

Hint: To use a different numeric type here, add a suffix or a type annotation.

── 0 errors and 1 warning ───────────────────────────────────────────── Fold.roc
```

Exit status 2. `roc test Fold.roc` prints the same warning, passes the test,
and also exits with 2.

### Expected

No warning: the `0` is a `U32` because the elements are. The language
reference gives this warning when defaulting to `Dec` makes a function's
inferred type more specific; here the function is annotated and the type is
not `Dec`.

### Notes

- With `|sum, x| x + sum` there is no warning.
- The "default type" it names follows the element type: with a `List(U64)` it
  says `U64`.
- No warning when the fold's result is the function's annotated result
  (`total : List(U32) -> U32` with `total = |list| list.fold(0, |sum, x| sum + x)`),
  nor for `(0 + x).to_str()` with `x : U32`.
- `nightly-2026-10-21-5349569` and `nightly-2026-11-07-ad3a5d2` behave the
  same.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-039-fold-seed-literal-defaulted-warning
