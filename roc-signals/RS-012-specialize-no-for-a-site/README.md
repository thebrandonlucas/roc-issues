# `--specialize=no` measured on a site built with roc-signals

> **Checked 2026-11-12:** measured on roc-signals `0.5.0` with
> `nightly-2026-11-10-f7d1f19` and `nightly-2026-11-11-7679cc5`.

A comment for [roc-signals#180](https://github.com/lukewilliamboswell/roc-signals/issues/180)
(whether to recommend `--specialize=no --opt=size` for roc-signals apps): the
module sizes and build times of [blu.cx](https://github.com/thebrandonlucas/blu)
(a personal site and blog) under both settings, and what was checked about
the `--specialize=no` module natively and in Chrome. The comment is in
`COMMENT.md`.

The same effect on a larger app, with the compiler's phase timings:
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/IMPROVEMENT-010-specialization-code-size).
