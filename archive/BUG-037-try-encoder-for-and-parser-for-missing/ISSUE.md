# `Json.to_str` and `Json.parse` say the builtin `Try` has no `encoder_for` or `parser_for`

> **Archived 2026-11-16:** filed as [roc-lang/roc#13112](https://github.com/roc-lang/roc/issues/13112) on 2026-11-16.

The builtin `Try(ok, err) := [Ok(ok), Err(err)]` declares `parser_for : _` and `encoder_for : _` in `Builtin.roc`, but `Json.to_str` of a `Try(Str, Str)` fails `roc check` with "missing method", saying the type has no `encoder_for`. A nominal tag union of the same shape declared in the app, with `encoder_for : _`, encodes as `{"Ok":"x"}`. `Try` should encode the same way.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

### Repro

`Probe.roc`:

```roc
Probe := [].{
	Outcome(ok, err) := [Ok(ok), Err(err)].{
		encoder_for : _
	}

	mine : Outcome(Str, Str)
	mine = Ok("x")

	theirs : Try(Str, Str)
	theirs = Ok("x")
}

expect Json.to_str(Probe.mine) == "{\"Ok\":\"x\"}"
expect Json.to_str(Probe.theirs) == "{\"Ok\":\"x\"}"
```

### Command

```
roc check Probe.roc
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

Hint: For this to work, the type would need to have a method named encoder_for
associated with it in the type's declaration.

── 1 error and 0 warnings ──────────────────────────────────────────── Probe.roc
```

### Expected

No errors, and both expects pass: `Try(Str, Str)` uses the `encoder_for` it declares, as `Outcome(Str, Str)` does.

### Notes

- Without the last `expect`, `roc test Probe.roc` passes: `Outcome` encodes as `{"Ok":"x"}`.
- Parsing fails the same way: `parsed : Try(Try(Str, Str), _)` with `parsed = Json.parse("{\"Ok\":\"x\"}")` reports that `Try(Str, Str)` has no `parser_for`.
- A record field of type `Try(a, [Missing])` does parse and encode (an absent field), as docs/langref/parsers.md describes.
- `nightly-2026-10-21-5349569` behaves the same.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-037-try-encoder-for-and-parser-for-missing
