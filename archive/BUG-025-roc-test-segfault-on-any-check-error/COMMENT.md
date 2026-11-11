# Comment on roc-lang/roc#12948

This isn't specific to `Json` or floats: on `nightly-2026-11-09-9e85de7`, any error that `roc check` reports in code an `expect` reaches makes `roc test` segfault on the dev backend. The smallest case I found:

`Main.roc`:

```roc
Main := [].{}

expect "a" == 1
```

```
$ roc test Main.roc

Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7ffe00000001

No compiler work was recorded on thread … (main).
```

Exit status 139. `roc test --opt=interpreter Main.roc` reports the error and exits 1:

```
── ✗ type mismatch ──────────────────────────────── Main.roc:3:8

This string literal must have the same type as a number literal, and nothing in
this program determines a type that can be both.

expect "a" == 1
       ^^^
```

An out-of-range literal crashes the same way:

```roc
Main := [].{}

x : Dec
x = 0.0007735999999999999

expect x == x
```

- With `x : U8` and `x = 300`, or `x : U8` and `x = "a"`, it also crashes.
- If no `expect` uses the bad value (`x : U8`, `x = 300`, `expect 1 == 1`), `roc test` reports the error and exits 1.
- Regression: `nightly-2026-10-21-5349569` and `nightly-2026-10-23-18478ff` report the error and exit 1 for both files (fresh `XDG_CACHE_HOME` each run); `nightly-2026-11-09-9e85de7` segfaults.

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-09-9e85de7` before posting.*
