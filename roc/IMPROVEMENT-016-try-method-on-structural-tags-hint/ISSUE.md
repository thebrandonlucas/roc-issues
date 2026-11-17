# Point at `Try` when a `Try` method is called on bare `Ok`/`Err` tags

An `Ok(...)` or `Err(...)` that nothing annotates is a structural tag union,
not a `Try`, so `Try`'s methods (`map_ok`, `ok_or`, `map_err`, ...) are not
found on it. The "missing method" error shows the type as `[Err([Empty]), Ok(Str)]`,
which looks like a `Try`, and says nothing more. A hint naming `Try` would make
the fix plain.

**Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

### Repro

`Parse.roc`:

```roc
Parse := {}

show : Str -> Str
show = |s| {
	parse = |t| if t == "" Err(Empty) else Ok(t)
	parse(s).map_ok(|t| t.concat("!")).ok_or("none")
}

expect show("a") == "a!"
```

### Command

```
roc check Parse.roc
```

### Observed

```
── ✗ missing method ───────────────────────────────────────────── Parse.roc:6:11

This map_ok method is being called on a value whose type doesn't have that
method.

parse(s).map_ok(|t| t.concat("!")).ok_or("none")
         ^^^^^^

The value's type, which does not have a method named map_ok, is:

    [Err([Empty]), Ok(Str)]

── 1 error and 0 warnings ──────────────────────────────────────────── Parse.roc
```

### Proposed

When the receiver is a structural tag union whose tags are among `Ok` and
`Err`, and `Try` has a method of that name, add a hint: these tags are a
`Try` only where a `Try` is expected; annotate the value (or the function
returning it) as `Try(ok, err)`, or call `Try.map_ok(...)`.

### Notes

- Annotating `parse : Str -> Try(Str, [Empty])`, or writing
  `Try.map_ok(parse(s), |t| t.concat("!")).ok_or("none")`, checks and passes.
- `Ok(s).map_ok(...)` gives the same error, with the type `[Ok(Str)]`.
