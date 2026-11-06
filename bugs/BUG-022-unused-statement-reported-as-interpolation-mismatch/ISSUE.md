# An unused `Str` statement is reported as an interpolation type mismatch in another function

In `realise`, `Main.tool(name)?` is used as a statement although its value is a `Str` (it should be `_ = Main.tool(name)?`). Instead of saying the value is unused, `roc check` reports that the values interpolated into a string in `served` have different types (`{}` and `Str`), points at the call of `served`, and never names the line with the mistake. Both interpolated values are `name`, a `Str`.

**Nightly:** `nightly-2026-11-06-34f137a` (linux x86_64)

### Repro

`Main.roc`:

```roc
Main := [].{
	tool : Str -> Try(Str, [Failed(Str)])
	tool = |purpose| Ok(purpose)

	served : Str -> Try(Str, _)
	served = |name| Err(Failed("${name}: ${name}"))

	realise : Str -> Try(Str, _)
	realise = |name| {
		_ = Main.served(name)?
		Main.tool(name)?
		Ok(name)
	}
}
```

### Command

```
roc check Main.roc
```

### Observed

```
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:6:29

The values interpolated into this string must all have the same type.

served = |name| Err(Failed("${name}: ${name}"))
                           ^^^^^^^^^^^^^^^^^^

But this use gives them different types:

_ = Main.served(name)?
    ^^^^^^^^^^^^^^^^^^

One of them has the type:

    {}

But another has the type:

    Str

Hint: Convert the values to one type before interpolating them, for example
with .to_str().

── 1 error and 0 warnings ───────────────────────────────────────────── Main.roc
```

### Expected

The diagnostic `roc check` gives for the same mistake when the error types are annotated:

```
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:11:3

This expression produces a value, but it's not being used.

Main.tool(name)?
^^^^^^^^^^^^^^^^

It has the type:

    Str

Since this expression is used as a statement, it must evaluate to {}.
If you don't need the value, you can ignore it with _ =.
```

### Notes

Each of these makes `roc check` report the unused value correctly:

- `_ = Main.tool(name)?` (ignoring the value) checks with no errors.
- Annotated errors, `Try(Str, [Failed(Str)])` instead of `Try(Str, _)`, on `served` and `realise`.
- One interpolated value: `"${name}"` or `"a ${name}"` instead of `"${name}: ${name}"`.
- The unused statement before the call of `served`.
- Removing the call `_ = Main.served(name)?`.

Effectful versions (`=>`, `tool!`, `served!`) behave the same. Seen on every nightly from `nightly-2026-10-21-5349569` to `nightly-2026-11-06-34f137a`.

- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-022-unused-statement-reported-as-interpolation-mismatch

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-06-34f137a` before posting.*
