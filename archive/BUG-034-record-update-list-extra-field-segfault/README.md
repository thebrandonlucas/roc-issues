# `roc check` segfaults on a record update of an imported nominal record whose new list's element has an extra field

> **Archived 2026-11-14:** filed as [roc-lang/roc#13067](https://github.com/roc-lang/roc/issues/13067) on 2026-11-14.

A record update of a value of a nominal record type from another module
replaces a `List` field with a list whose element record has a field the
element type lacks. This is a type error, but `roc check Project.roc`
segfaults (or overflows its stack) while type-checking `Project`, on most
runs with a fresh cache. It should report the extra field.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

In this directory: `main.roc`, a package exposing `Model` and `Project`;
`Model.roc`, a nominal `Model := { items : List({ name : Str }) }` with an
associated `Other : Str` and `empty`; and `Project.roc`, whose `expect`
evaluates `{ ..Model.empty, items: [{ name: "a", extra: Bool.False }] }`.

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

The exit status is 139. Some runs instead print `The Roc compiler overflowed
its stack memory and had to exit.` for the same module (exit status 134), and
some report a type mismatch at the update that names the wrong field: "This
record does not have a field named items", offering `name` instead.

### Expected

A type mismatch saying the list element has the field `extra`, which
`{ name : Str }` does not.

### Notes

- In 12 runs, each with a fresh cache, 8 segfaulted and 4 reported the
  wrong-field mismatch. With `--jobs=1` the result is the same on every run
  in a given directory, but which one it is changes with the directory and
  environment.
- `items: [{ name: "a" }]` checks with no errors.
- With a record field instead of a list, this nightly and
  `nightly-2026-10-21-5349569` report that the type
  of the field `item` is incompatible, without a crash.
- With `Model`, `empty` and the `expect` all in `Model.roc`, this nightly
  reports the wrong-field mismatch on every run;
  `nightly-2026-10-21-5349569` segfaults on every run.
- `nightly-2026-10-21-5349569` and `nightly-2026-11-12-ce942d6` crash the
  same way.

## Related

[roc-lang/roc#12968](https://github.com/roc-lang/roc/issues/12968) is the
same crash for a list element that misses a field. It was closed by
[roc-lang/roc#12986](https://github.com/roc-lang/roc/pull/12986), merged
after `nightly-2026-11-13-03dce41`; its repro still segfaults on that
nightly.

### Shell with the exact compiler

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-034-record-update-list-extra-field-segfault),
`nix develop .` gives `nightly-2026-11-12-ce942d6`, the newest nightly in
its pinned roc-overlay, and the repo's root flake gives the nightly above:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-12-ce942d6
```

### Harness

```sh
nix develop . --command bash repro.sh              # BUG REPRODUCED
nix develop ../..#latest --command bash repro.sh   # BUG REPRODUCED
```

The script first checks the same update with an element of the right type,
which must pass, then runs `roc check --jobs=1 Project.roc` once and
`roc check Project.roc` up to 10 times, each with a fresh cache, and accepts
only a segfault or stack overflow in the type-check of `Project`.
