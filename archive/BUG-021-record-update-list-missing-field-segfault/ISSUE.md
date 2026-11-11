# `roc check` segfaults, or reports a wrong field error, on a record update whose new list's elements miss a field

A record update replaces a `List` field with a list whose element record lacks one of the element type's fields. This is a type error, but when the record is a nominal type `roc check` segfaults while type-checking the module. With a plain record type it reports that the record has no field `files`, offering the inner record's fields instead. It should report the missing field `size`.

**Nightly:** `nightly-2026-11-11-7679cc5` (linux x86_64)

### Repro

`Main.roc`:

```roc
Main := [].{}

Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { ..empty, files: [{ url: "u" }] }
```

### Command

```
roc check Main.roc
```

### Observed

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7916d81a0000

Work in progress on thread 68828 (compile worker 2), outermost first:
  type-check    module Main (Main.roc)
```

The exit status is 139.

With a plain record type in place of `Model`:

```roc
Main := [].{}

empty : { files : List({ url : Str, size : U64 }) }
empty = { files: [] }

model : { files : List({ url : Str, size : U64 }) }
model = { ..empty, files: [{ url: "u" }] }
```

it reports a field that does exist as missing:

```
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:7:13

This record does not have a field named files.

model = { ..empty, files: [{ url: "u" }] }
            ^^^^^

This is often due to a typo. The most similar fields are:

    - size
    - url

So maybe files should be size?

Note: You cannot add new fields to a record with the record update syntax.

── 1 error and 0 warnings ───────────────────────────────────────────── Main.roc
```

### Expected

For both files, a type mismatch saying the list element is missing the field `size`, as `roc check` reports when the record is built without the update (`model = { files: [{ url: "u" }] }`, with no `empty`):

```
Hint: This record is missing the field: size
```

### Notes

- `files: [{ url: "u", size: 1 }]` checks with no errors.
- The list matters: with a record field instead (`file : { url : Str, size : U64 }` and `{ ..empty, file: { url: "u" } }`), the missing `size` is reported correctly.
- A structural alias, `Model : { ... }`, gives the wrong field error, not the segfault.
- The wrong field error is the same on every nightly from `nightly-2026-10-21-5349569` to `nightly-2026-11-11-7679cc5`. With the nominal type, nightlies up to `nightly-2026-11-10-f7d1f19` gave either the segfault or the wrong field error, the same on every run for a given setup but changing with the working directory's name and whether `XDG_CACHE_HOME` is set; `nightly-2026-11-11-7679cc5` segfaults in every setup tried.
- Related: roc-lang/roc#11057 (closed), a misleading error when updating a nominal record's field with a tag.
- A reproduction script, with the compiler it was found on pinned by Nix: [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault)

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-11-7679cc5` before posting.*
