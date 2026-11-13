# Point at `{ name }` when a one-name block is used where a record is expected

`{ a, b }` is a record with punned fields, but `{ a }` is a block whose value
is `a`. When `{ a }` was meant as a record, the type error is reported where
the mismatch surfaces, which can be far from the braces and does not mention
them. A hint at the block (write `{ a: a }` for a one-field record) would make
the cause plain.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### Repro

`Shorthand.roc`:

```roc
Shorthand := {}

Message : [User({ text : Str }), System({ text : Str })]

user = |text| User({ text })

messages : List(Message)
messages = [System({ text: "boot" }), user("hi")]
```

### Command

```
roc check Shorthand.roc
```

### Observed

```
── ✗ type mismatch ────────────────────────────────────────── Shorthand.roc:8:44

This string literal is being used where a non-string type is needed.

messages = [System({ text: "boot" }), user("hi")]
                                           ^^^^

The type was determined to be:

    { text: Str }
```

### Proposed

When a type mismatch involves a block that is a single name in braces, and the
expected type is a record with a field of that name, add a hint at the block:
`{ text }` is a block that evaluates to `text`; a one-field record is written
`{ text: text }`. A warning on every such block would also do.

### Notes

- With an annotation (`user : Str -> Message`) the error is at
  `User({ text })`, with `User(Str)` in the type it shows; it still does not
  point at the braces.
