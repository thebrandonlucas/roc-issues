# BUG-020: `roc test` fails an expect because parsed rows hold garbage strings

Found with Roc `nightly-2026-10-21-5349569`, where it needed a `roc build` first
(see "History"). This repro's shell now pins `nightly-2026-11-03-34bd006`, where
`roc test` alone fails. No platform is needed.

## Description

`pkg/Steps.roc` holds a top-level constant that only an `expect` uses. It is
computed by parsing CoNLL-U text that starts with a comment line:

```roc
sentence = first_sentence("# sent_id = 1\n1\ta\ta\tc\t_\t_\t0\tx\t_\tt_1\n...")

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
```

`roc test pkg/main.roc` fails that `expect`, with or without a cache. The row
count is right (3), but every row's `id` (and `form`) is the single byte
`0xFF`, the same on every run. The comment lines are parsed correctly.
`pkg/Conllu.roc` is the parser from the project where this was found, cut down
to `parse` and `blocks`; a smaller hand-written parser did not reproduce it.

## Expected behavior

All tests pass, as on `nightly-2026-10-21-5349569`:

```text
All (1) tests passed
```

## Actual behavior

```text
── ✗ fail ─────────────────────────────────────────────────── pkg/Steps.roc:15:1

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ran 1 test:
    0 passed
    1 failed
    0 compiler errors
```

`dbg sentence.rows.map(|r| r.id)` prints `["\xFF", "\xFF", "\xFF"]`.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-11-03-34bd006`, pinned by
this repro's `flake.nix` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-03-34bd006
```

Inside that shell:

```sh
roc test pkg/main.roc
```

### Harness

```sh
nix develop . --command bash repro.sh
```

The harness copies `pkg/` to a temporary directory with a fresh cache and
succeeds only if the `expect` over the parsed rows fails.

## Observations

- **Comment line:** without `# sent_id = 1\n` at the start of the text, the
  test passes.
- **Regression:** passes on `nightly-2026-10-21-5349569`; fails on
  `nightly-2026-10-25-72704da` and every nightly since, through
  `nightly-2026-11-03-34bd006` (`2026-10-22` to `2026-10-24` not tested).

## History

On `nightly-2026-10-21-5349569` the same test failed only when `roc test` ran
after `roc build` of an app importing the package (the app was `app.roc`, now
removed), and passed alone or with `--no-cache`. Since `nightly-2026-10-25` it
fails every time, so the build is no longer needed and the repro was cut down on
2026-11-06.
