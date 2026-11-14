# `roc check` segfaults on a record update whose list element misses a field

> **Archived 2026-11-11:** filed as [roc-lang/roc#12968](https://github.com/roc-lang/roc/issues/12968) on 2026-11-11.

> **Closed 2026-11-13:** roc-lang/roc#12968 closed as completed.

Found with Roc `nightly-2026-10-21-5349569`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault) pins.
`nightly-2026-11-02-847b82c` crashes the same way. No platform is needed.

## Description

`Model` is a record with a list of records. A record update of a `Model`
value replaces that list with one whose element lacks the `size`
field:

```roc
Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { ..empty, files: [{ url: "u" }] }
```

This is a type error the checker should report. Instead `roc check`
segfaults while type-checking the module.

## Expected behavior

A type mismatch saying the list element is missing the field `size`, as
building the record without the update does:

```text
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:9:30

This expression is used in an unexpected way.
...
Hint: This record is missing the field: size
```

## Actual behavior

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x766aaef90000

Work in progress on thread 2977818 (compile worker 2), outermost first:
  type-check    module Main (Main.roc)
```

`roc check` exits with status 139, on every run.

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault), enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by its `flake.nix` (Linux):

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

From the same directory of [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault):

```sh
nix develop . --command bash repro.sh
```

The harness copies `Main.roc` to a temporary directory with a fresh cache and
runs `roc check Main.roc`. It reports success only when the check exits 139
with a segfault in the type-check of `Main`.

## Observations

- **Correct field types:** `files: [{ url: "u", size: 1 }]` checks with no
  errors.
- **No update:** `model = { files: [{ url: "u" }] }` reports the missing
  `size` field correctly.
- **No list:** with a record field instead of a list,
  `file : { url : Str, size : U64 }` and `{ ..empty, file: { url: "u" } }`,
  the field mismatch is reported correctly.
- **Structural alias:** `Model : { ... }` instead of `Model := { ... }`
  segfaults the same way, so the nominal type is not needed.
- **Wrong error instead of a crash:** with `Model : { name : Str, files : ... }`
  and the element bound first as `file : { url : Str }`,
  `{ ..empty, files: [file] }` does not crash but reports a wrong error at
  the update: "This record does not have a field named files", offering `url`
  and `size`, the inner record's fields, as the closest names.
- **Across modules:** with `Model` in an imported module, a list nested one
  level deeper and the element bound first, repeated runs with a fresh cache
  sometimes segfault and sometimes report that same wrong "does not have a
  field named" error, so the checker likely reads memory it should not.
- **How it was found:** checking a module of [Kai](https://github.com/thebrandonlucas/kai) (a CLI for Nix and Guix written in Roc), its `direct` backend, whose
  test fixture built a `Model` by updating `Model.empty(...)` with a list of
  download records, while the record type inside the `Model` nominal had a
  field that the fixture's record alias lacked. `roc check` crashed in the
  type-check of that module instead of naming the missing field; making the
  two record types agree made it pass.

## Related

[roc-lang/roc#11057](https://github.com/roc-lang/roc/issues/11057) (closed, a
misleading error when updating a nominal record field with a tag) is the
closest.
