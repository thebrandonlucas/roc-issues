# IMPROVEMENT-003: Let `roc bundle` include files outside the entry file's directory

This is a CLI capability gap, not a compiler bug. `roc bundle` stores every
file relative to the directory of its first `.roc` argument and rejects any
file outside it. That root became the entry file's directory on purpose
(roc-lang/roc#10845, closed), but there is no way to choose a different one.

Found on `nightly-2026-09-23-c7852fd`; still the behavior on
`nightly-2026-09-26-d6267b4`:

```sh
mkdir -p a b
printf 'package [] {}\n' > a/main.roc
printf 'hi\n' > b/README.md
roc bundle a/main.roc b/README.md
```

```text
Error: Cannot bundle '.../b/README.md' because it is outside the entry point directory '.../a'.
```

## Proposed improvement

Add a `--root <dir>` option (defaulting to the entry file's directory) that
sets the archive root, so one bundle can keep sibling directories such as
`platform/` and `plugins/std/` side by side, as the old compiler's bundles did
when run from the repository root.

## Current workaround

Copy the files into a staging directory with a generated entry file at its
root (for example `Bundle.roc` containing `Bundle := [].{}`) and pass that
entry first. The archive gains the extra `Bundle.roc`.

Used by: Kai's `build.zig` bundle step.
