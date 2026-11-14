# Provide Unicode case mapping for Str

`Str` has `with_ascii_lowercased`, `with_ascii_uppercased` and
`caseless_ascii_equals`, which change or ignore the case of ASCII letters
only, so `"ΛΌΓΟΣ"` cannot be lowercased to `"λόγος"`. Case-insensitive
search over text in any other script needs Unicode case mapping.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

### Repro

`Case.roc`:

```roc
Case := {}

expect {
	lower = "ΛΌΓΟΣ".with_ascii_lowercased()
	dbg lower
	lower == "λόγος"
}
```

### Command

```
roc test Case.roc
```

### Observed

```
[dbg] "ΛΌΓΟΣ"

── ✗ fail ───────────────────────────────────────────────────────── Case.roc:3:1
...
Ran 1 tests in 43.7 ms.:
    0 passed
    1 failed
    0 compiler errors
```

### Proposed

A `lowercase`/`uppercase` (or case fold) for `Str` using the Unicode default
case mappings, as builtins or in a maintained package that builds with
current nightlies. A locale-independent default, as JavaScript's
`toLowerCase` uses, covers search.

### Notes

- The builtins' documentation points to
  [roc-lang/unicode](https://github.com/roc-lang/unicode) for Unicode
  capitalization.
