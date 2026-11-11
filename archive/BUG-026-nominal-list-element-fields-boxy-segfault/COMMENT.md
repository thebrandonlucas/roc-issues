# Comment on roc-lang/roc#12968

Possibly related: since `nightly-2026-11-11-7679cc5`, the same file **without the update** also segfaults, in a later stage. `nightly-2026-11-10-f7d1f19` reports the missing field for it.

`Main.roc`:

```roc
Main := [].{}

Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { files: [{ url: "u" }] }
```

`roc check Main.roc` on `nightly-2026-11-11-7679cc5`:

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x8046d3200

Work in progress on thread 75043 (main), outermost first:
  post-check    boxy_lowering
```

Exit status 139, also with `--no-cache`. On `nightly-2026-11-10-f7d1f19`:

```
Hint: This record is missing the field: size
```

- It needs the earlier, annotated `empty`: without it, with `empty` defined after `model`, or with `empty` unannotated, the missing field is reported.
- A structural alias (`Model : { ... }`) or a single-record field (`file : { url : Str, size : U64 }`) reports a type mismatch; an opaque type (`Model :: { ... }`) crashes the same way.
- An extra element field (`{ url: "u", size: 1, extra: 2 }`) crashes too; a wrong field type (`size: "big"`) is reported.
- Regression: `nightly-2026-10-21-5349569`, `nightly-2026-10-23-18478ff`, `nightly-2026-11-09-9e85de7` and `nightly-2026-11-10-f7d1f19` report the missing field; `nightly-2026-11-11-7679cc5` segfaults.

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-11-7679cc5` before posting.*
