# `roc check` segfaults on a record update of an imported nominal record whose new list's element has an extra field

A record update of a value of a nominal record type from another module replaces a `List` field with a list whose element record has a field the element type lacks. This is a type error, but `roc check Project.roc` segfaults (or overflows its stack) while type-checking `Project`, on most runs with a fresh cache. It should report the extra field.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

### Repro

`main.roc`:

```roc
package [Model, Project] {}
```

`Model.roc`:

```roc
Model := { items : List({ name : Str }) }.{
	Other : Str

	empty : Model
	empty = Model.{ items: [] }
}
```

`Project.roc`:

```roc
import Model

expect {
	model = { ..Model.empty, items: [{ name: "a", extra: Bool.False }] }
	model.items.len() == 1
}
```

### Command

```
roc check Project.roc
```

### Observed

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7320ecc50000

Work in progress on thread 209978 (compile worker 2), outermost first:
  type-check    module Project (Project.roc)
```

The exit status is 139. Some runs instead print `The Roc compiler overflowed its stack memory and had to exit.` for the same module (exit status 134), and some report a type mismatch that names the wrong field:

```
── ✗ type mismatch ──────────────────────────────────────────── Project.roc:4:14

This record does not have a field named items.

model = { ..Model.empty, items: [{ name: "a", extra: Bool.False }] }
            ^^^^^^^^^^^

This is often due to a typo. The most similar fields are:

    - name

So maybe items should be name?

Note: You cannot add new fields to a record with the record update syntax.
```

### Expected

A type mismatch saying the list element has the field `extra`, which `{ name : Str }` does not.

### Notes

- In 12 runs, each with a fresh cache, 8 segfaulted and 4 reported the mismatch above. With `--jobs=1` the result is the same on every run in a given directory, but which one it is changes with the directory and environment.
- `items: [{ name: "a" }]` checks with no errors.
- With a record field instead of a list (`item : { name : Str }` and `item: { name: "a", extra: Bool.False }`), this nightly and `nightly-2026-10-21-5349569` report that the type of the field `item` is incompatible, without a crash.
- With `Model`, `empty` and the `expect` all in `Model.roc`, this nightly reports the wrong-field mismatch on every run; `nightly-2026-10-21-5349569` segfaults on every run.
- Related: roc-lang/roc#12968, the same crash for a list element that misses a field; it was closed by roc-lang/roc#12986, which was merged after this nightly.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-034-record-update-list-extra-field-segfault

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-13-03dce41` before posting.*
