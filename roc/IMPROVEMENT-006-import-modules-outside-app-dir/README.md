# Let an app import modules from outside its own directory

An app can import only modules in its own directory: `import Shared` in
`sub/app.roc` looks for `sub/Shared.roc`, and there is no way to name the
`Shared.roc` one level up. Two apps in different directories cannot share a
module without copying it.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), basic-cli `0.28.0`

### Repro

`Shared.roc`:

```roc
Shared := {}.{
	greeting : Str
	greeting = "hi"
}
```

`sub/app.roc`:

```roc
app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.28.0/2yhxoR7cZPSYbyUzPWULFw8AA6QEcdsgFNRmzu7pZbst.tar.zst" }

import pf.Stdout
import Shared

main! = |_args| Stdout.line!(Shared.greeting)
```

### Command

```
roc check sub/app.roc
```

### Observed

```
── ✗ file not found ────────────────────────────────────────────────────────────

sub/Shared.roc: FileNotFound.

── 1 error and 0 warnings ────────────────────────────────────────── sub/app.roc
```

### Proposed

A relative path in `import` (or an app header entry naming extra module
directories), so an app can import a module from a sibling or parent
directory.

### Notes

- With `Shared.roc` copied into `sub/`, the app checks and prints `hi`.
- `import ..Shared` and `import "../Shared.roc" as Shared` do not parse as
  module imports.
