# `roc check` segfaults, or reports a wrong field error, on a record update whose new list's elements miss a field

A record update replaces a `List` field with a list whose element record lacks one of the element type's fields. This is a type error, but `roc check` either segfaults while type-checking the module or reports that the record has no field `files`, offering the inner record's fields instead. Which of the two happens is the same on every run for a given setup, but changes with incidental things such as the length of the working directory's name and whether `XDG_CACHE_HOME` is set.

**Nightly:** `nightly-2026-11-09-9e85de7` (linux x86_64)

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

Run from a directory named `w` with `XDG_CACHE_HOME` unset, or from one named `work` with it set:

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7ffff7d50000

Work in progress on thread 1714721 (compile worker 2), outermost first:
  type-check    module Main (Main.roc)
```

The exit status is 139. With the other two combinations:

```
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:9:13

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

A type mismatch saying the list element is missing the field `size`, as `roc check` reports for the same record built without the update (`model = { files: [{ url: "u" }] }`):

```
Hint: This record is missing the field: size
```

### Notes

- `files: [{ url: "u", size: 1 }]` checks with no errors.
- Without the update, `model = { files: [{ url: "u" }] }`, the missing `size` is reported correctly.
- With a record field instead of a list (`file : { url : Str, size : U64 }` and `{ ..empty, file: { url: "u" } }`), the mismatch is reported correctly.
- A structural alias, `Model : { ... }`, behaves the same, so the nominal type isn't needed.
- Seen on `nightly-2026-10-21-5349569` through `nightly-2026-11-09-9e85de7`.
- Related: roc-lang/roc#11057 (closed), a misleading error when updating a nominal record's field with a tag.
- Harness (it hits the segfault): https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-021-record-update-list-missing-field-segfault

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-09-9e85de7` before posting.*
