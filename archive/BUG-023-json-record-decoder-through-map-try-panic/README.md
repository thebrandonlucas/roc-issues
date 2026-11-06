# BUG-023: a record `Json.parse` decoder passed to `List.map_try` panics `roc check`

> **Archived 2026-11-05:** fixed upstream (roc-lang/roc#11730, closed 2026-09-27); nightly-2026-11-03-34bd006 no longer panics.

Found with Roc `nightly-2026-09-26-d6267b4`, which this repro's shell pins.
`nightly-2026-09-27-a3ce7f1` panics the same way. `nightly-2026-09-19-d025939`
and `nightly-2026-09-28-9927ba8` check it cleanly. The repro needs basic-cli
0.22.2, which the harness downloads.

## Description

`label` decodes a record with `Json.parse(...)?` and has no annotation. `main!`
passes it to `List.map_try` and unwraps the result with `?`:

```roc
app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst" }

main! = |_args| {
	_ = List.map_try([""], label)?
	Ok({})
}

label = |line| {
	unit : { label : Str }
	unit = Json.parse(line)?
	Ok(unit.label)
}
```

## Expected behavior

`roc check main.roc` reports no errors (only basic-cli's warnings), as on
`nightly-2026-09-19-d025939` and `nightly-2026-09-28-9927ba8`:

```text
── 0 errors and 75 warnings ─────────────────────────────────────────── main.roc
```

## Actual behavior

```text
thread 1533706 panic: compiler bug: instantiation widened a closed tag union
Cannot print stack trace: stack tracing is disabled
```

It panics the same way with a fresh cache and with basic-cli 0.26.0.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-26-d6267b4`,
pinned by this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-26-d6267b4
```

Inside that shell, reproduce manually with:

```sh
roc check main.roc
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies `main.roc` to a temporary directory with a fresh `HOME` and
cache (so it downloads basic-cli 0.22.2). It reports success only when
`roc check` panics with "instantiation widened a closed tag union".

## Observations

Each change below makes `roc check` pass:

- **Direct call:** `_ = label("")?` instead of passing `label` to `List.map_try`.
- **No `?` on the result:** `_ = List.map_try([""], label)`.
- **Decoding a `Str`** instead of a record.
- **An annotation on `label`**, open or closed:
  `Str -> Try(Str, [InvalidJson(Str), ..])` or `Str -> Try(Str, [InvalidJson(Str)])`.
- **An inline lambda** in place of `label`.

The same functions in a type module with no platform check cleanly.

**How it was found:** Archeion's `scripts/adopt-apo.roc` panicked when checked
with `nightly-2026-09-26-d6267b4` (its `with_empty_literal` decodes a record
and is passed to `List.map_try` in `main!`). Archeion pins
`nightly-2026-09-19-d025939`, so Archeion itself was not affected. The newer
compiler was tried only because the pinned one could not be downloaded at the
time (GitHub release downloads returned 504).

## Upstream status

Fixed upstream. It is the same failure as
[roc-lang/roc#11730](https://github.com/roc-lang/roc/issues/11730), where a record
`Json.parse` decoder is passed through two functions (opened 2026-09-26). That
issue was closed by [roc-lang/roc#11752](https://github.com/roc-lang/roc/pull/11752)
("Preserve codec error constraints across generalization", merged 2026-09-27).

Checked on 2026-11-05:

- `nightly-2026-09-27-a3ce7f1` still panics.
- `nightly-2026-09-28-9927ba8` (the first nightly with #11752) passes.
- `nightly-2026-10-21-5349569`, `nightly-2026-10-23-18478ff` and
  `nightly-2026-11-03-34bd006` pass with basic-cli 0.26.0. They no longer
  build basic-cli 0.22.2.

No workaround is needed: Archeion pins an unaffected compiler, and any upgrade
past `nightly-2026-09-27` already has the fix.
