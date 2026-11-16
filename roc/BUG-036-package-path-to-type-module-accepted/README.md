# A package dependency whose path is a type module, not a package, is accepted, and its values "do not exist"

A package header names a dependency by the path of a type module
(`base: "../Shared.roc"`) instead of a package's header file.
`roc check sub/main.roc` accepts the dependency and `import base.Shared`,
then reports `Shared.value does not exist` at its use, with nothing about
the path. It should say at the header that `../Shared.roc` is not a package.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

In this directory: `Shared.roc`, a type module with a value `value`;
`sub/main.roc`, a package whose dependency `base` is `"../Shared.roc"`; and
`sub/Uses.roc`, which imports `base.Shared` and uses `Shared.value`.

### Command

```
roc check sub/main.roc
```

### Observed

```
── ✗ does not exist ────────────────────────────────────────── sub/Uses.roc:5:13

Shared.value does not exist.

greeting = Shared.value
           ^^^^^^^^^^^^

── 1 error and 0 warnings ───────────────────────────────────────── sub/main.roc
```

### Expected

An error at the dependency in `sub/main.roc` saying that `../Shared.roc` is
not a package (it has no `package` header).

### Notes

- With `import base.Missing` in `sub/Uses.roc` (and no use of `Shared`),
  `roc check` reports no errors. With `base` pointing at a real package
  (`package [Shared] {}` beside the same `Shared.roc`), that import is
  reported as not naming a public module of the package, and `Shared.value`
  checks.
- A path to a file that does not exist is reported at the header ("Could
  not load the package at Nope.roc: FileNotFound.").

### Shell with the exact compiler

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-036-package-path-to-type-module-accepted),
`nix develop .` gives `nightly-2026-11-14-a87808d`, the newest nightly in
its pinned roc-overlay:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-14-a87808d
```

### Harness

```sh
nix develop . --command bash repro.sh              # BUG REPRODUCED
nix develop ../..#latest --command bash repro.sh   # BUG REPRODUCED
```

The script first checks the same `Uses.roc` against a real package holding
`Shared.roc`, which must pass, then accepts only `Shared.value does not
exist` with no error at the header.
