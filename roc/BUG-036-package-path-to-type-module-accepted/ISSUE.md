# A package dependency whose path is a type module, not a package, is accepted, and its values "do not exist"

A package header names a dependency by the path of a type module (`base: "../Shared.roc"`) instead of a package's header file. `roc check sub/main.roc` accepts the dependency and `import base.Shared`, then reports `Shared.value does not exist` at its use, with nothing about the path. It should say at the header that `../Shared.roc` is not a package.

**Nightly:** `nightly-2026-11-14-a87808d` (linux x86_64)

### Repro

`Shared.roc`:

```roc
Shared := [].{
	value : Str
	value = "hi"
}
```

`sub/main.roc`:

```roc
package [Uses] {
	base: "../Shared.roc",
}
```

`sub/Uses.roc`:

```roc
import base.Shared

Uses := [].{
	greeting : Str
	greeting = Shared.value
}
```

### Command

```
roc check sub/main.roc
```

### Observed

```
── ✗ does not exist ────────────────────────────────────────── sub/Uses.roc:5:13

Shared.value does not exist.

greeting = Shared.value
           ^^^^^^^^^^^^

── 1 error and 0 warnings ───────────────────────────────────────── sub/main.roc
```

### Expected

An error at the dependency in `sub/main.roc` saying that `../Shared.roc` is not a package (it has no `package` header).

### Notes

- With `import base.Missing` in `sub/Uses.roc` (and no use of `Shared`), `roc check sub/main.roc` reports no errors. With `base` pointing at a real package (`package [Shared] {}` beside the same `Shared.roc`), the same import is reported as "The package import `base.Missing` does not name a public module declared by that package", and `Shared.value` checks.
- A path to a file that does not exist is reported at the header: "Could not load the package at Nope.roc: FileNotFound."
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-036-package-path-to-type-module-accepted

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-14-a87808d` before posting.*
