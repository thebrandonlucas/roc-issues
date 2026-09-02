# BUG-006: Effectful `Path` fold crashes at runtime

Found with Roc `nightly-2026-08-13-2fdd90e` and
[basic-cli 0.22.0](https://github.com/roc-lang/basic-cli/releases/tag/0.22.0).

## Description

The app folds `Path.join` over a relative path inside an effectful helper, checks
the resulting path with `Path.is_dir!`, and returns the helper directly from
`main!`. It builds successfully, then crashes at runtime:

```text
[ROC CRASHED] dispatch on a value that can never exist
```

The existing directory passed by the harness should make the helper return
`Ok({})`.

## Reproduction

From this directory:

```sh
kai run repro
```

For an interactive shell with the same pinned compiler:

```sh
kai shell repro
./repro.sh
```

or manually inside that shell:

```sh
roc build Repro.roc --opt=dev --output=repro
./repro .
```

The harness builds into a temporary directory and reports success only when the
expected impossible-dispatch crash appears.

## Regression window

The same source passes with `nightly-2026-08-12-606470f` and crashes with
`nightly-2026-08-13-2fdd90e`. Recursion and directory traversal are not needed
to trigger the regression.
