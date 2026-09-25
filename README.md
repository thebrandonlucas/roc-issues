# roc-issues-repro

Self-contained reproductions of Roc compiler bugs, pinned to the exact
compiler the bug was found on.

## Setup

The flake pins a [roc-overlay](https://github.com/thebrandonlucas/roc-overlay)
catalog containing every recorded compiler release. The default compiler is
selected in `flake.nix`.

With [direnv](https://direnv.net/): `direnv allow` selects that default
compiler. Without direnv, run `nix develop` from the repo root.

Verify the default compiler:

```sh
roc version
# Roc compiler version release-fast-c9147c28
```

## Running reproductions

Each bug directory has a `Kaifile` and `kai.lock` that pin its exact
environment independently of the root flake catalog. From that bug's directory,
bootstrap Kai through Nix and run either command:

```sh
nix run github:thebrandonlucas/kai -- run repro    # deterministic PASS/FAIL harness
nix run github:thebrandonlucas/kai -- shell repro  # interactive developer shell
```

If Kai 0.0.6 or newer is already on `PATH`, use `kai run repro` or
`kai shell repro` directly.

A successful harness means the expected bug was reproduced; an unrelated crash
or failure is not accepted as success. Improvement directories are design ideas
and do not have runnable harnesses.

## Switching Roc versions

Every release in the pinned overlay catalog is exposed as both a package and a
dev shell. List them with:

```sh
nix flake show
```

Switch the current shell to any recorded release:

```sh
nix develop '.#nightly-2026-July-15-c2d30e8'
roc version
```

Useful aliases:

```sh
nix develop .#found   # compiler on which the bug was found
nix develop .#latest  # newest compiler in the pinned catalog
```

For a one-off command without entering a shell:

```sh
nix run .#found -- version
nix run .#latest -- version
nix run '.#nightly-2026-July-15-c2d30e8' -- check path/to/main.roc
```

Outside Kai, a repro script uses whichever `roc` is active, so bugs can also
be checked against another compiler through `nix develop .#latest`.

## Bugs

Each `bugs/BUG-XXX-*` directory is a self-contained repro with a pinned
`Kaifile` and `kai.lock`, source, `README.md`, and executable `repro.sh`.

- [BUG-007: A shared object cache segfaults a second app's dev build](./bugs/BUG-007-cross-app-object-cache-segfault/README.md)
- [BUG-008: Interpolating a reserved word in an imported module panics](./bugs/BUG-008-reserved-word-interpolation-panic/README.md)

## Improvements

Ideas are documented separately from compiler defects and need not have a
harness. There are currently no active improvements.

## Adding a repro

1. `mkdir bugs/BUG-XXX-short-description`
2. Copy the smallest set of Roc sources that reproduces the issue. Keep each
   repro self-contained (no imports outside its directory except a pinned
   platform), even if that means duplicating support files between bugs.
3. Add a `README.md` with a description, expected behavior, actual behavior
   (including the exact panic/crash output), and the repro commands.
4. Add an executable `repro.sh` that accepts only the expected failure as
   success and leaves no local build artifacts behind.
5. Add a `Kaifile` whose `repro` environment pins the affected compiler and
   whose `repro` task runs the harness.
6. Run `kai update` in the bug directory and commit its `kai.lock`.
