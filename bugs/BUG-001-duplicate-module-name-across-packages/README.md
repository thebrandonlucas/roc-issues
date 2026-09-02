# BUG-001: Duplicate module names across packages panic the compiler

Found with Roc `release-fast-c9147c28`
(`nightly-2026-July-14-c9147c2`).

## Description

Two local packages (`custom0`, `custom1`) each expose a module named `Plugin`
and contain component sub-packages (`backends.Local`, `commands.SplitCommand`,
`implementations.SplitLocal`) whose module names are also identical across the
two packages. The app imports them under distinct aliases:

```roc
import custom0.Plugin as Custom0
import custom1.Plugin as Custom1
```

Instead of compiling (or producing a diagnostic), the compiler panics:

```text
thread <id> panic: typed_cir invariant violated: duplicate module name <path>/custom0/main.roc.Plugin
```

The bug is **compile-cache dependent**:

- The **first** `roc check` on a cold cache succeeds.
- **Every subsequent run panics** until the cache is cleared
  (`rm -rf ~/.cache/roc`).

## Reproduction

From this directory:

```sh
kai run repro
```

For an interactive shell with the same pinned compiler:

```sh
kai shell repro
./repro.sh
```

The harness creates a temporary `HOME`, so it starts with a cold Roc cache and
does not touch the user's compiler cache. To run the same steps manually:

```sh
tmp_home=$(mktemp -d)
export HOME="$tmp_home"
export XDG_CACHE_HOME="$HOME/.cache"
roc check main.roc   # succeeds
roc check main.roc   # panics: typed_cir invariant violated
rm -rf "$tmp_home"
```

The harness reports success only when the warm-cache check contains the expected
duplicate-module panic.

## Layout

- `main.roc`, `Repro.roc` — the root package importing both plugins
- `custom0/`, `custom1/` — identical packages exposing `Plugin` with
  component sub-packages

## Notes

- The original context was `xkai` staging two custom plugins as isolated
  packages (`custom0`, `custom1`) where both plugin modules were named
  `Plugin.roc`. This repro is platform-free so it can run unchanged across
  compiler versions.
- A single plugin, or two plugins whose modules/components have different
  names, does not trigger the panic.
- Workaround used downstream: give the second top-level plugin module a
  different name while retaining identical component module filenames.
