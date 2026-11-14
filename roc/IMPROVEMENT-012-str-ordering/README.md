# Give `Str` an order by its UTF-8 bytes

`Str` has no `is_lt` and no `compare`, so `a < b` on two strings is a type
error and `List.sort_with` has nothing to sort strings with. The FAQ points to
`Str.to_utf8`, but `List(U8)` has no `<` either. A byte-wise order (which for
UTF-8 is code-point order) is well defined without any locale, and is what
sorting identifiers, ISO-8601 timestamps or keys for stable output needs.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

### Repro

`Order.roc`:

```roc
Order := {}

earlier : Str, Str -> Bool
earlier = |a, b| a < b
```

### Command

```
roc check Order.roc
```

### Observed

```
── ✗ missing method ───────────────────────────────────────────── Order.roc:4:18

The value before this < operator has a type that doesn't have a is_lt method.

earlier = |a, b| a < b
                 ^^^^^

The value's type, which does not have a method named is_lt, is:

    Str

Hint: The < operator calls a method named is_lt on the value preceding it,
passing the value after the operator as the one argument.
```

`Str.compare` does not exist, and `a < b` on two `List(U8)` gives the same
error.

### Proposed

A comparison of two strings by their UTF-8 bytes, under a name that says so
(for example `Str.compare_utf8 : Str, Str -> [Before, Same, After]`, the
shape `List.sort_with` takes), or `is_lt`/`compare` for `List(U8)`.

## Related

- roc-lang/roc#7667 (open): a clearer error when comparing two `Str`,
  pointing to the FAQ on why `Str` works as it does.
- roc-lang/roc#6551 (closed, not planned): a `Sort` ability, which left `Str`
  out on purpose.
