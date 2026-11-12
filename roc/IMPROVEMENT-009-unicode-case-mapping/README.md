# Provide Unicode case mapping for Str

This is a capability gap, not a compiler bug. `Str` has `with_ascii_lowercased`,
`with_ascii_uppercased` and `caseless_ascii_equals`, which change or ignore the
case of ASCII letters only. There is no way to lowercase other letters
(`"ΛΌΓΟΣ"` stays `"ΛΌΓΟΣ"`). Checked on `nightly-2026-11-07-ad3a5d2`.

The builtins' documentation points to the
[roc-lang/unicode](https://github.com/roc-lang/unicode) package for Unicode
capitalization. Whether that package offers case mapping that builds with the
current compiler has not been checked.

Case-insensitive search over user text needs it: a search box in an app for
reading Greek should find `λόγος` when the learner types `Λόγος`.

## Proposed improvement

A `lowercase`/`uppercase` (or case-fold) for `Str` using the Unicode default
case mappings, either as builtins or in a maintained package that builds with
current nightlies. A locale-independent default (as JavaScript's
`toLowerCase` and Elm's `String.toLower` use) covers search.

## Current workaround

Use `with_ascii_lowercased`, so non-ASCII letters match only in the case typed.

Used by: the library search of [Lyceum Study](https://github.com/lyceum-quest/study)
(a Greek reading app), `packages/study/Library.roc` (`Library.shown`), which
ports a search that used Elm's `String.toLower`.
