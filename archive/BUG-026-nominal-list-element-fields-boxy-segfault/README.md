# `roc check` segfaults in boxy_lowering when a nominal record's list elements miss a field

> **Archived 2026-11-11:** posted as [a comment on roc-lang/roc#12968](https://github.com/roc-lang/roc/issues/12968) on 2026-11-11 (the same file without the record update); `ISSUE.md` is the unposted standalone version.

Found with Roc `nightly-2026-11-11-7679cc5`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-026-nominal-list-element-fields-boxy-segfault) pins.
`nightly-2026-11-10-f7d1f19` reports the error correctly. No platform is needed.

## Description

`Main.roc` defines a nominal record type with a list of records, one correct
value of it, and one whose list element misses the field `size`:

```roc
Main := [].{}

Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { files: [{ url: "u" }] }
```

## Expected behavior

`roc check Main.roc` reports a type mismatch at `model`:

```text
Hint: This record is missing the field: size
```

## Actual behavior

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x8046d3200

Work in progress on thread 75043 (main), outermost first:
  post-check    boxy_lowering
```

`roc check` exits with status 139.

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-026-nominal-list-element-fields-boxy-segfault), enter a shell with Roc `nightly-2026-11-11-7679cc5`, pinned by its
`flake.nix` (Linux; the compiler is Roc's own download, pinned by hash):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-11-7679cc5
roc check Main.roc
```

### Automated harness

From the same directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies `Main.roc` to a temporary directory with a fresh cache and
reports success only when `roc check` exits 139 with a segfault in
`boxy_lowering`.

## Observations

- **Regression:** `nightly-2026-10-21-5349569`, `nightly-2026-10-23-18478ff`,
  `nightly-2026-11-09-9e85de7` and `nightly-2026-11-10-f7d1f19` report the
  missing field;
  `nightly-2026-11-11-7679cc5` segfaults on every run, with or without
  `--no-cache`.
- **Reported as a type mismatch instead:** without `empty`; with `empty` defined after
  `model`; with `empty` unannotated; with a structural alias
  (`Model : { ... }`); with a single record field
  (`file : { url : Str, size : U64 }`), or a nominal
  list (`Files := List({ ... })`) in place of the record.
- **Crashes the same way:** a list element with an extra field
  (`{ url: "u", size: 1, extra: 2 }`), an inner record with one field
  (`List({ url : Str })` and `[{}]`), and an opaque type (`Model :: { ... }`).
- **Not affected:** a field of the wrong type (`size: "big"`) is reported as
  a type mismatch.
- **How it was found:** while rechecking a record-update bug in
  [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault)
  (`roc check` segfaults or reports a wrong field when a record update's new
  list elements miss a field), whose file without the `..empty` update
  crashes this way on this nightly.

## Related

[roc-lang/roc#12946](https://github.com/roc-lang/roc/issues/12946) (open) is a
different `boxy_lowering` segfault, in `--specialize=no` builds that reuse
cache entries from a specialized build.
