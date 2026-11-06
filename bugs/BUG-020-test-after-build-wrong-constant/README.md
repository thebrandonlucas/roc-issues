# BUG-020: `roc test` after `roc build` fails an expect that passes without the cache

> **Rechecked 2026-11-05:** changed on nightly-2026-11-03-34bd006: the expect now fails every time, including on an empty cache and with `--no-cache`, not only after `roc build`. Update the description before filing. Not filed upstream yet.

Found with Roc `nightly-2026-10-21-5349569`, which this repro's shell pins.
`nightly-2026-11-01-48d3369` behaves the same.

## Description

`pkg/Steps.roc` holds a top-level constant that only an `expect` uses. The constant
is computed by parsing text that has a comment line:

```roc
sentence = first_sentence("# sent_id = 1\n1\ta\ta\tc\t_\t_\t0\tx\t_\tt_1\n...")

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
```

Building an app that imports the package and then testing the package, with no
source change between them, fails that `expect`. `sentence.rows.len()` is still
right; the rows' contents are wrong. `roc test` alone passes, and so does
`roc test --no-cache` after the build. Dropping the comment line from the text also
makes it pass. A smaller hand-written `parse` did not reproduce it, so `pkg/Conllu.roc`
is kept as found.

The failed result is then cached, so later `roc test` runs keep reporting it until a
source changes. The app has to import the package; it does not need to use the
constant.

## Expected behavior

`roc test pkg/main.roc` gives the same result whether or not `roc build app.roc`
ran first.

## Actual behavior

```text
── ✗ fail ─────────────────────────────────────────────────── pkg/Steps.roc:15:1

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ran 5 tests in 35.9 ms.:
    4 passed
    1 failed
```

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-10-21-5349569`, pinned by
this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

### Harness

```sh
nix develop . --command bash repro.sh
```

The harness succeeds only if the `expect` fails after the build and passes with
`--no-cache`. It needs network access to fetch basic-cli.

## Workaround

Run `roc test --no-cache`. apo does this in its `test` task.
