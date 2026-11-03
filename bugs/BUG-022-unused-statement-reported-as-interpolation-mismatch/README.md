# BUG-022: an unused `Str` statement is reported as an interpolation mismatch elsewhere

Found with Roc `nightly-2026-10-21-5349569`, which this repro's shell pins.
`nightly-2026-11-02-847b82c` reports the same. No platform is needed.

## Description

In `realise`, `Main.tool(name)?` is used as a statement, but its value is a
`Str`, so it should be `_ = Main.tool(name)?`:

```roc
served : Str -> Try(Str, _)
served = |name| Err(Failed("${name}: ${name}"))

realise : Str -> Try(Str, _)
realise = |name| {
	_ = Main.served(name)?
	Main.tool(name)?
	Ok(name)
}
```

`roc check` should say the statement's value is unused. Instead it reports a
mismatch between the values interpolated into the string in `served`, says
the call of `served` gives them the types `{}` and `Str`, and never names the
line with the mistake. Both values are `name`, a `Str`.

This is a wrong diagnostic, not a crash, but it is a compiler defect with a
deterministic harness, so it is recorded as a bug rather than an improvement.

## Expected behavior

The diagnostic that `roc check` gives for the same mistake when the errors
are annotated:

```text
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:11:3

This expression produces a value, but it's not being used.

Main.tool(name)?
^^^^^^^^^^^^^^^^

It has the type:

    Str

Since this expression is used as a statement, it must evaluate to {}.
If you don't need the value, you can ignore it with _ =.
```

## Actual behavior

```text
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

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

Inside that shell, reproduce manually with:

```sh
roc check Main.roc
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies `Main.roc` to a temporary directory with a fresh cache. It
reports success only when `roc check` reports the interpolation mismatch and
not the unused value.

## Observations

Each change below makes `roc check` report the unused value correctly:

- **Ignoring the value:** `_ = Main.tool(name)?` checks with no errors.
- **Annotated errors:** `Try(Str, [Failed(Str)])` instead of `Try(Str, _)` on
  `served` and `realise`.
- **One interpolated value:** `"${name}"` or `"a ${name}"` instead of
  `"${name}: ${name}"`.
- **Order:** the unused statement before the call of `served`.
- **No call of `served`:** removing `_ = Main.served(name)?`.

Effectful functions (`=>`, `tool!`, `served!`) behave the same.

**How it was found:** in Kai's download store, an effectful `realise!` with an
inferred error type called `served!`, whose error interpolated two values,
and then ran `Store.tool!("chmod", ...)?` as a statement, discarding the
`Str` it returns. `roc check` reported "The values interpolated into this
string must all have the same type" in `served!`, pointing at the call of
`served!`. Adding `_ =` to the `chmod` statement fixed it.

## Upstream status

Not reported upstream yet. Searching roc-lang/roc issues on 2026-11-03 for
"values interpolated into this string", "interpolated same type", "unused
string statement", "unused expression statement" and "produces a value, but
it's not being used" found no matching issue.
