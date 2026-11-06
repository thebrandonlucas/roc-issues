# `Json.parse` and `Dec.from_str` reject a decimal with more than 18 fraction digits

Decoding a JSON number with 19 or more fraction digits into a `Dec` field fails the whole parse with `InvalidJson("Invalid JSON")`, and `Dec.from_str` returns `Err(BadNumStr)` for the same text. The input is valid JSON and the value is well within `Dec`'s range; only the extra digit is rejected. Floating-point output often has such numbers: Claude Code's `--output-format json` writes `total_cost_usd` values like `0.0007735999999999999`.

**Nightly:** `nightly-2026-11-06-34f137a` (linux x86_64)

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

# 19 fraction digits: rejected.
expect {
	parsed : Try({ c : Dec }, _)
	parsed = Json.parse("{\"c\":0.0007735999999999999}")
	parsed.is_ok()
}

expect Dec.from_str("0.0007735999999999999").is_ok()
```

### Command

```
roc test Main.roc
```

### Observed

```
── ✗ fail ──────────────────────────────────────────────────────── Main.roc:11:1

expect {
    parsed : Try({ c : Dec }, _)
    parsed = Json.parse("{\"c\":0.0007735999999999999}")
    parsed.is_ok()
}

── ✗ fail ──────────────────────────────────────────────────────── Main.roc:17:1

expect Dec.from_str("0.0007735999999999999").is_ok()
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ran 3 tests:
    1 passed
    2 failed
    0 compiler errors
```

Printed, the two results are `Err(InvalidJson("Invalid JSON"))` and `Err(BadNumStr)`.

### Expected

All three pass: the number is rounded (or truncated) to 18 fraction digits, as for any other decimal `Dec` can't represent exactly, e.g. `Ok({ c: 0.000773600000000000 })`.

### Notes

- 18 fraction digits decode; 19 fail.
- Seen on every nightly from `nightly-2026-09-19-d025939` to `nightly-2026-11-06-34f137a`.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-015-json-dec-over-18-fraction-digits

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-06-34f137a` before posting.*
