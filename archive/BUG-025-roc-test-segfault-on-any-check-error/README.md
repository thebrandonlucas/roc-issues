# `roc test` segfaults when an expect reaches code with a check error

> **Archived 2026-11-11:** fixed upstream before it was posted: `nightly-2026-11-10-f7d1f19` and `nightly-2026-11-11-7679cc5` report the error and exit 1. It was the same crash as [roc-lang/roc#12948](https://github.com/roc-lang/roc/issues/12948), whose own example is also fixed on those nightlies; `COMMENT.md` is the unposted comment for it.

On `nightly-2026-11-09-9e85de7`, `roc test` on the default dev backend
segfaults (exit 139) whenever an `expect` reaches code that `roc check`
rejects, for example:

```roc
Main := [].{}

expect "a" == 1
```

`roc test --opt=interpreter` reports the type mismatch instead.

## Observations

- An out-of-range literal used by an expect (`x : Dec`,
  `x = 0.0007735999999999999`, `expect x == x`) crashes the same way, as do
  `x : U8` with `x = 300` or `x = "a"`.
- With no expect using the bad value, `roc test` reports the error and
  exits 1.
- `nightly-2026-10-21-5349569` and `nightly-2026-10-23-18478ff` report the
  error and exit 1; `nightly-2026-11-09-9e85de7` segfaults;
  `nightly-2026-11-10-f7d1f19` and `nightly-2026-11-11-7679cc5` report the
  error again. Each run used a fresh `XDG_CACHE_HOME`.
