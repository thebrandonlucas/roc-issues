# Let an app import modules from outside its own directory

> **Rechecked 2026-11-05:** still needed: the workaround moved with the passage pipeline from [Lyceum Study](https://github.com/lyceum-quest/study) (a Greek reading app, then called Aristos) to [Archeion](https://github.com/lyceum-quest/archeion) (its text pipeline), [`scripts/Passages.roc`](https://github.com/lyceum-quest/archeion/blob/master/scripts/Passages.roc) and [`scripts/passages.roc`](https://github.com/lyceum-quest/archeion/blob/master/scripts/passages.roc), on 2026-10-14.

This is a capability gap, not a compiler bug. An app can import only modules
that sit in its own directory: `import Shared` in `sub/app.roc` resolves to
`sub/Shared.roc`, and there is no way to name `../Shared.roc` (`roc check`
reports `sub/Shared.roc: FileNotFound`). Checked on `nightly-2026-09-19-d025939`
with basic-cli `0.22.2`.

Projects that keep several apps in nested folders (for example a generation
loop in `scripts/generate/` and a build tool in `scripts/`) therefore cannot
share a module without duplicating it or moving every app into one folder.

## Proposed improvement

Allow a relative module path in `import` (or an app header entry naming extra
module directories), so sibling and parent modules can be shared.

## Current workaround

Keep the shared module next to the app that imports it directly, and give it a
thin companion app that prints its results (JSON on stdout); apps in other
folders run that companion as a subprocess. Remove the workaround once modules
can be imported across directories.

Used by: Lyceum Study (then Aristos) `scripts/Passages.roc`, reached from
`scripts/generate/loop.roc` through `scripts/passages.roc`.
