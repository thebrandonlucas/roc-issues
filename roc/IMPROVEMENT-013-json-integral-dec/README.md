# Encode an integral `Dec` in JSON without a fraction

An unannotated number literal defaults to `Dec`, and `Json.to_str` writes an
integral `Dec` with a fraction: `{ version: 2 }` becomes `{"version":2.0}`.
`Json.parse` into a `U32` field then rejects that text with
`InvalidJson("Invalid JSON")`, though it is valid JSON and the number is an
integer. JSON has one number type, so `2` would be the same value and would
read back into any integer field.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### Repro

`Version.roc`:

```roc
Version := {}

encoded : Str
encoded = Json.to_str({ version: 2 })

expect {
	dbg encoded
	parsed : Try({ version : U32 }, _)
	parsed = Json.parse(encoded)
	dbg parsed
	parsed.is_ok()
}
```

### Command

```
roc test Version.roc
```

### Observed

```
[dbg] "{\"version\":2.0}"
[dbg] Err(InvalidJson("Invalid JSON"))

── ✗ fail ────────────────────────────────────────────────────── Version.roc:6:1
...
Ran 1 tests in 97.7 ms.:
    0 passed
    1 failed
    0 compiler errors
```

### Proposed

Write an integral `Dec` as `2`, as JavaScript and most JSON encoders do. Short
of that, a `Json.parse` error that names the field and says it expected an
integer, rather than "Invalid JSON".

### Notes

- This follows from the literal's default type, not a defect in the
  encoder: `2.U32` encodes as `2`, `2.5` as `2.5`, and `Str.inspect(2)` also
  gives `2.0`. `Json.parse` into a `Dec` field reads both `2` and `2.0`.
