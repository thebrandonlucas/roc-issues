# `--specialize=no` measured on two sites built with roc-signals

A comment for
[roc-signals#180](https://github.com/lukewilliamboswell/roc-signals/issues/180)
(whether to recommend `--specialize=no --opt=size` for roc-signals apps):
module sizes and build times of two small sites under both settings, and
what was checked about their `--specialize=no` modules. The comment is
[`COMMENT.md`](./COMMENT.md).

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), roc-signals `0.5.0`

The same effect on a larger app:
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/IMPROVEMENT-010-specialization-code-size).
