# `Sqlite.query!` and `Sqlite.query_many!` into a record fail `roc check` on Roc nightly-2026-11-10-f7d1f19 and later: `RowEncoding` has no `missing_field`

On basic-webserver 0.21.0, `roc check` rejects a `Sqlite.query!` or `Sqlite.query_many!` call whose row type is a record with required fields, saying `Sqlite.RowEncoding` has no `missing_field` method. Since roc-lang/roc#12933 (first in `nightly-2026-11-10-f7d1f19`), Roc's [parser docs](https://github.com/roc-lang/roc/blob/main/docs/langref/parsers.md) say "A format that supports required record fields also defines `missing_field : encoding, Str -> err`", and `RowEncoding` doesn't define it (on `main` either). The app should check, as it does on `nightly-2026-11-09-9e85de7`.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### Repro

`main.roc`:

```roc
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.21.0/4viZsnWjdYsyH4Q87ESFAwM5c55Hnc15nAGW1UwzWpFU.tar.zst",
}

import pf.Path
import pf.Server
import pf.Sqlite

Context : { db : Sqlite.Db }

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64)])
init! = || {
	db = Sqlite.open!(Sqlite.default_config(Path.utf8("repro.db"))) ? |_| Exit(2)
	rows : List({ name : Str })
	rows = Sqlite.query_many!({ db, query: "SELECT 'a' AS name;", params: {}, limits: Sqlite.default_query_limits }) ? |_| Exit(3)
	if rows.is_empty() Err(Exit(4)) else Ok({ config: Server.default_config, context: { db } })
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |_request, _context| Err(ServerErr("unused"))
```

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

No errors, as on `nightly-2026-11-09-9e85de7`.

### Notes

- A single-column scalar row (`rows : List(Str)`) checks. `Sqlite.query!` into `{ name : Str }` and a two-field record row fail the same way.
- Adding this to `RowEncoding` in a local copy of the 0.21.0 platform makes the repro check and build on `nightly-2026-11-12-ce942d6` (`QueryError` already has `MissingRequiredField(Str)`):

  ```roc
  missing_field : RowEncoding, Str -> QueryError
  missing_field = |_, name| MissingRequiredField(name)
  ```
- Regression: works on `nightly-2026-11-09-9e85de7`, fails since `nightly-2026-11-10-f7d1f19`.
- Related: #264, the automated bump of the nightly pin to `nightly-2026-11-12-ce942d6`; its "Linux examples under Memcheck" job fails with this error on `examples/sqlite.roc`.
- A reproduction script, with the compiler pinned by Nix: [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/basic-webserver/BUG-032-sqlite-record-rows-need-missing-field)

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-12-ce942d6` before posting.*
