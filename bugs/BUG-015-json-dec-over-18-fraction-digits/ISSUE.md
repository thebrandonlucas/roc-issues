# `Json.parse` and `Dec.from_str` reject a decimal with more than 18 fraction digits

Decoding a JSON number with 19 or more fraction digits into a `Dec` field fails the whole parse with `InvalidJson("Invalid JSON")`, and `Dec.from_str` returns `Err(BadNumStr)` for the same text. The input is valid JSON and the value is well within `Dec`'s range; only the extra digit is rejected. Floating-point output often has such numbers: Claude Code's `--output-format json` writes `total_cost_usd` values like `0.0007735999999999999`.

**Nightly:** `nightly-2026-11-03-34bd006` (linux x86_64)

### Repro

`main.roc`:

```roc
app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst" }
import cli.Stdout
main! = |_args| {
	a : Try({ c : Dec }, _)
	a = Json.parse("{\"c\":0.011101999999999999}")
	b : Try({ c : Dec }, _)
	b = Json.parse("{\"c\":0.0007735999999999999}")
	Stdout.line!("18 places: ${Str.inspect(a)}\n19 places: ${Str.inspect(b)}\nDec.from_str: ${Str.inspect(Dec.from_str("0.0007735999999999999"))}")
}
```

### Command

```
roc main.roc
```

### Observed

```
18 places: Ok({ c: 0.011101999999999999 })
19 places: Err(InvalidJson("Invalid JSON"))
Dec.from_str: Err(BadNumStr)
```

### Expected

The number is rounded (or truncated) to 18 fraction digits, as for any other decimal `Dec` can't represent exactly:

```
19 places: Ok({ c: 0.000773600000000000 })
```

### Notes

- 18 fraction digits decode; 19 fail.
- Seen on every nightly from `nightly-2026-09-19-d025939` to `nightly-2026-11-03-34bd006`.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-015-json-dec-over-18-fraction-digits

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-03-34bd006` before posting.*
