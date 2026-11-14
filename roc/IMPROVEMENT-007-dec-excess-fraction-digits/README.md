# Let `Dec.from_str` and JSON decoding accept more than 18 fraction digits

`Dec.from_str` and `Json.parse` into a `Dec` field reject a decimal with
more than 18 fraction digits, such as `0.0007735999999999999`: the first
returns `Err(BadNumStr)`, the second fails the whole document with
`InvalidJson("Invalid JSON")`, naming neither the field nor the reason.
Numbers printed from a float often have 19 or more fraction digits, so such
a document is valid JSON that cannot be decoded into `Dec`.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

### Repro

`Main.roc`:

```roc
Main := [].{}

# 18 fraction digits: decodes.
expect {
	parsed : Try({ c : Dec }, _)
	parsed = Json.parse("{\"c\":0.011101999999999999}")
	parsed.is_ok()
}

# 19 fraction digits.
expect {
	parsed : Try({ c : Dec }, _)
	parsed = Json.parse("{\"c\":0.0007735999999999999}")
	dbg parsed
	parsed.is_ok()
}

expect {
	d = Dec.from_str("0.0007735999999999999")
	dbg d
	d.is_ok()
}
```

### Command

```
roc test Main.roc
```

### Observed

```
[dbg] Err(InvalidJson("Invalid JSON"))

── ✗ fail ───────────────────────────────────────────────────────── Main.roc:11:1
...
[dbg] Err(BadNumStr)

── ✗ fail ──────────────────────────────────────────────────────── Main.roc:18:1
...
Ran 3 tests in 180.9 ms.:
    1 passed
    2 failed
    0 compiler errors
```

### Proposed

Either or both:

- When parsing text (`Dec.from_str`, JSON decoding into `Dec`), round a
  decimal with more than 18 fraction digits to 18, e.g.
  `0.0007735999999999999` to `0.000773600000000000`.
- Make the JSON error say which field failed and why (too many fraction
  digits for `Dec`).

Decoding the field as `F64` and converting it works today.

### Notes

- A `Dec` literal with 19 fraction digits is rejected at compile time
  ("does not fit in the inferred type"), which the author can fix.
- From this directory in
  [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/IMPROVEMENT-007-dec-excess-fraction-digits),
  `nix develop ../..#latest --command bash repro.sh` runs `Main.roc` on the
  nightly above.

## Related

- [roc-lang/roc#10550](https://github.com/roc-lang/roc/issues/10550)
  (closed): another `Dec.from_str` `Err(BadNumStr)` case, exponential
  notation such as `"2e5"`.
- [roc-lang/roc#12098](https://github.com/roc-lang/roc/issues/12098)
  (closed): Dec JSON exponent arithmetic saturates instead of overflowing,
  another edge case of decoding JSON numbers into `Dec`.
