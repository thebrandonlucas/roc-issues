# A nominal tag union value is accepted where a structural tag union of the same shape is annotated

A value of a nominal tag union type is accepted where an annotation asks for a structural tag union with the same tags, and it keeps the nominal type there: in `Color.roc` below, `plain` is annotated `[Red, Green]` but holds `Color.Red`, and `Color.plain.name()` calls `Color`'s method on it. `roc check Color.roc` reports no errors and `roc test Color.roc` passes. The langref says no other tag union is equivalent to a nominal one, even with the same shape, so this should be a type mismatch at `plain = Color.Red`.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

### Repro

`Color.roc`:

```roc
Color := [Red, Green].{
	name : Color -> Str
	name = |color|
		match color {
			Red => "red"
			Green => "green"
		}

	plain : [Red, Green]
	plain = Color.Red
}

expect Color.plain.name() == "red"
```

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

A type mismatch at `plain = Color.Red`: it has the type `Color`, but the annotation says `[Red, Green]`.

### Notes

- With a different shape the mismatch is reported: `plain : Light -> [Red, Green, Blue]` with `plain = |light| light`, for `Light := [Red, Green]`, gives "It has the type: Light / But the annotation says it should be: [Blue, Green, Red]".
- Two nominal types of the same shape are not mixed: `relabel : Color -> Light` with `relabel = |c| c` is a type mismatch.
- The builtin `Try` behaves the same: a function annotated `Try(U64, Str) -> [Ok(U64), Err(Str)]` with body `|t| t` checks, and its result is still a `Try(U64, Str)`, so `Json.to_str` of it asks `Try` for `encoder_for`.
- `nightly-2026-10-21-5349569` behaves the same.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-035-nominal-value-accepted-as-structural-union

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-14-a87808d` before posting.*
