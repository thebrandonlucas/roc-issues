# Sqlite queries whose row is a record fail `roc check` on Roc nightly-2026-11-10-f7d1f19 and later: `Sqlite.RowEncoding` has no `missing_field`

On basic-webserver 0.21.0, `roc check` rejects a `Sqlite.query!` or
`Sqlite.query_many!` whose row type is a record, saying
`Sqlite.RowEncoding` has no `missing_field` method. The app should check,
as it does on `nightly-2026-11-09-9e85de7`.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), basic-webserver `0.21.0`

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

`main.roc` in this directory: an app whose `init!` reads
`rows : List({ name : Str })` with `Sqlite.query_many!`.

### Command

```
roc check main.roc
```

### Observed

```
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

### Expected

No errors.

### Notes

- A single-column scalar row (`rows : List(Str)`) checks.
- Adding `missing_field = |_, name| MissingRequiredField(name)` to
  `RowEncoding` in a local copy of the platform makes `main.roc` check and
  build.
- Regression: works on `nightly-2026-11-09-9e85de7`, fails since
  `nightly-2026-11-10-f7d1f19`.

### Harness

From this directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/basic-webserver/BUG-032-sqlite-record-rows-need-missing-field),
whose `flake.nix` pins the nightly above (and the last good one as
`last-good`):

```sh
nix develop . --command bash repro.sh            # BUG REPRODUCED
nix develop .#last-good --command bash repro.sh  # BUG NOT REPRODUCED
```

The script first checks the same app with `rows : List(Str)`, which must
pass, then accepts only the `missing_field` error on `Sqlite.RowEncoding`.
