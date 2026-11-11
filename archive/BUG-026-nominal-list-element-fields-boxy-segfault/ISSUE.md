# `roc check` segfaults in boxy_lowering when a nominal record's list elements miss a field (since nightly-2026-11-11)

A nominal record type has a `List` field of records. One value of the type is defined correctly, and a second one gives a list element without one of the element's fields. `roc check` segfaults in the `boxy_lowering` stage instead of reporting the missing field, as it did up to `nightly-2026-11-10-f7d1f19`.

**Nightly:** `nightly-2026-11-11-7679cc5` (linux x86_64)

### Repro

`Main.roc`:

```roc
Main := [].{}

Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { files: [{ url: "u" }] }
```

### Command

```
roc check Main.roc
```

### Observed

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x8046d3200

Work in progress on thread 75043 (main), outermost first:
  post-check    boxy_lowering
```

The exit status is 139. `--no-cache` crashes the same way.

### Expected

A type mismatch at `model` saying the list element is missing the field `size`, as `nightly-2026-11-10-f7d1f19` reports:

```
Hint: This record is missing the field: size
```

### Notes

- Each of these makes `roc check` report a type mismatch instead of crashing: removing `empty`, defining `empty` after `model`, leaving `empty` unannotated, making `Model` a structural alias (`Model : { ... }`), or making the field a single record instead of a list of records.
- An extra field (`{ url: "u", size: 1, extra: 2 }`) crashes the same way, and so does an opaque type (`Model :: { ... }`). A field of the wrong type (`size: "big"`) is reported correctly.
- Regression: `nightly-2026-10-21-5349569`, `nightly-2026-10-23-18478ff`, `nightly-2026-11-09-9e85de7` and `nightly-2026-11-10-f7d1f19` report the missing field; `nightly-2026-11-11-7679cc5` segfaults.
- Related: roc-lang/roc#12946 (open), a different `boxy_lowering` segfault, in `--specialize=no` builds that reuse cache entries from a specialized build.
- A reproduction script, with the compiler it was found on pinned by Nix: [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-026-nominal-list-element-fields-boxy-segfault)

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-11-7679cc5` before posting.*
