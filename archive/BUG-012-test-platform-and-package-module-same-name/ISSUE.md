# `roc test` crashes when a platform and its package both have a module with the same name

A platform has a module `S`, and the package it depends on has its own module `S`. `roc check` passes and `roc test` on the package alone passes, but `roc test App.roc` crashes: the process dies of SIGTRAP with no output at all.

**Nightly:** `nightly-2026-11-11-7679cc5` (linux x86_64)

### Repro

`App.roc`:

```roc
app [main] { pf: platform "platform/main.roc" }

main = "x"

expect main == "x"
```

`platform/main.roc`:

```roc
platform ""
	requires {
		main : Str
	}
	exposes []
	packages {
		lib: "../lib/main.roc",
	}
	provides { "roc_main": main_for_host }

import S
import lib.Twice

main_for_host : Str
main_for_host = Twice.twice(S.wrap(main))
```

`platform/S.roc` and `lib/S.roc` (the same content):

```roc
S := [].{
	wrap : Str -> Str
	wrap = |s| "(${s})"
}

expect S.wrap("a") == "(a)"
```

`lib/main.roc`:

```roc
package [Twice] {}
```

`lib/Twice.roc`:

```roc
import S

Twice := [].{
	twice : Str -> Str
	twice = |s| S.wrap(S.wrap(s))
}
```

### Command

```
roc test App.roc
```

### Observed

No output. The process dies of SIGTRAP (exit status 133). On `nightly-2026-11-09-9e85de7` it segfaults instead:

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7c

No compiler work was recorded on thread 1698942 (main).
```

### Expected

All 3 tests pass, as on `nightly-2026-10-28-bad769b`:

```
All (3) tests passed
```

### Notes

- `roc check App.roc` reports no errors, and `roc test lib/main.roc` passes.
- Regression: passes on `nightly-2026-10-28-bad769b` and earlier back to `nightly-2026-10-21-5349569`; crashes since `nightly-2026-10-29-a0a9fc2`. (On nightlies before 2026-10-21 it panicked with "compiled module plan contains duplicate source module".)
- Related: roc-lang/roc#11065 (closed), the same kind of crash for two packages that expose a module with the same name.
- A reproduction script, with the compiler it was found on pinned by Nix: [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-012-test-platform-and-package-module-same-name)

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-11-7679cc5` before posting.*
