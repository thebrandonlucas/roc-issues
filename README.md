# roc-issues-repro

Self-contained reproductions of Roc compiler bugs, pinned to the exact
compiler the bug was found on.

## Setup

The flake pins [roc-overlay](https://github.com/thebrandonlucas/roc-overlay)
to the commit whose `nightly` is `nightly-2026-July-14-c9147c2`
(`roc version` = `release-fast-c9147c28`).

With [direnv](https://direnv.net/): `direnv allow` and you're done.

Without direnv: `nix develop` from the repo root, or run one-off commands via
`nix run .#roc -- <args>` / `nix shell` from this flake.

Verify the compiler:

```sh
roc version
# Roc compiler version release-fast-c9147c28
```

## Bugs

Each `bugs/BUG-XXX-*` directory is a self-contained repro with its own
`README.md` and `repro.sh`.

- [BUG-001: Duplicate module names across packages panic the compiler](./bugs/BUG-001-duplicate-module-name-across-packages/README.md)
- [BUG-002: `roc test` aborts in LIR lowering through the plugin union registry path](./bugs/BUG-002-plugin-run-registry-test-segfault/README.md)

## Adding a repro

1. `mkdir bugs/BUG-XXX-short-description`
2. Copy the smallest set of Roc sources that reproduces the issue. Keep each
   repro self-contained (no imports outside its directory except the pinned
   platform), even if that means duplicating support files between bugs.
3. Add a `README.md` with a description, expected behavior, actual behavior
   (including the exact panic/crash output), and the repro commands.
4. Add a `repro.sh` that runs the repro and prints PASS/FAIL.
5. If the bug was found on a different compiler, note the version in the
   README and consider adding a named package for it in `flake.nix`.
