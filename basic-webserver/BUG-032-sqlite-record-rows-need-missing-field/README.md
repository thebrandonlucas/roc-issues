# Sqlite queries whose row is a record fail `roc check` on Roc nightly-2026-11-10-f7d1f19 and later: `Sqlite.RowEncoding` has no `missing_field`

> **Rechecked 2026-11-13:** still reproduces on `nightly-2026-11-12-ce942d6` (`repro.sh` prints BUG REPRODUCED); `nightly-2026-11-09-9e85de7` checks the app.

Found with Roc `nightly-2026-11-11-7679cc5` and
[basic-webserver](https://github.com/roc-lang/basic-webserver) `0.21.0`;
this directory's `flake.nix` pins `nightly-2026-11-12-ce942d6`, the newest
nightly it was checked on. This is a platform issue: it goes to
roc-lang/basic-webserver.

## Description

`main.roc` is a basic-webserver 0.21.0 app whose `init!` reads
`rows : List({ name : Str })` with `Sqlite.query_many!`. `roc check
main.roc` reports that `Sqlite.RowEncoding` has no `missing_field` method.
`Sqlite.query!` into a record fails the same way.

Since [roc-lang/roc#12933](https://github.com/roc-lang/roc/pull/12933)
(commit `a192c5805`, first in `nightly-2026-11-10-f7d1f19`), Roc's
[parser docs](https://github.com/roc-lang/roc/blob/main/docs/langref/parsers.md)
say: "A format that supports required record fields also defines
`missing_field : encoding, Str -> err`." 0.21.0's `Sqlite.RowEncoding`
defines no `missing_field`, and neither does basic-webserver's main branch.

## Expected behavior

`roc check main.roc` reports no errors, as on `nightly-2026-11-09-9e85de7`.

## Actual behavior

```text
── ✗ missing method ────────────────────────────────────────────── main.roc:17:9

This use needs the missing_field method, but the type being used doesn't have
that method.

rows = Sqlite.query_many!({ db, query: "SELECT 'a' AS name;", params: {}, limits: Sqlite.default_query_limits }) ? |_| Exit(3)
       ^^^^^^^^^^^^^^^^^^

The value's type, which does not have a method named missing_field, is:

    Sqlite.RowEncoding

Hint: For this to work, the type would need to have a method named
missing_field associated with it in the type's declaration.

── 1 error and 0 warnings ───────────────────────────────────────────── main.roc
```

The exit status is 1.

## Reproduction

```sh
nix develop . --command bash repro.sh
```

The harness first checks a control, the same app reading `rows : List(Str)`,
which must pass, then accepts only the `missing_field` error on
`Sqlite.RowEncoding` as the bug. It works in a temporary `HOME` (it
downloads the platform) and leaves nothing behind. On the last good nightly:

```sh
nix develop .#last-good --command bash repro.sh   # prints BUG NOT REPRODUCED
```

## Shell with the exact compiler

This directory pins Roc `nightly-2026-11-12-ce942d6` from
[roc-overlay](https://github.com/roc-lang/roc-overlay) revision
`67491987eb6ef2423d9a6e5901f6a8e439d8566c`:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-12-ce942d6
```

`nix develop .#last-good` gives `nightly-2026-11-09-9e85de7`, the last
nightly that checks the app.

## Observations

- Regression: checks on `nightly-2026-11-09-9e85de7`; fails on
  `nightly-2026-11-10-f7d1f19`, `nightly-2026-11-11-7679cc5` and
  `nightly-2026-11-12-ce942d6`.
- A single-column scalar row (`rows : List(Str)`) checks. A two-field
  record row fails the same way.
- Adding these lines to `RowEncoding` in a local copy of the 0.21.0
  platform (`QueryError` already has `MissingRequiredField(Str)`) makes
  `main.roc` check and build on `nightly-2026-11-12-ce942d6`:

  ```roc
  missing_field : RowEncoding, Str -> QueryError
  missing_field = |_, name| MissingRequiredField(name)
  ```

## Related

- [roc-lang/basic-webserver#264](https://github.com/roc-lang/basic-webserver/pull/264),
  the automated bump of basic-webserver's nightly pin to
  `nightly-2026-11-12-ce942d6`: its "Linux examples under Memcheck" CI job
  fails with this error on `examples/sqlite.roc`.
