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

Each bug directory has a `flake.nix` and `flake.lock` that pin its exact
environment independently of the root flake catalog. Each repro's README
includes a **Shell with the exact compiler** section with the shell command,
compiler release, and version check. Use that shell rather than the root
`nix develop` default, which may select a different compiler.

From that bug's directory, use Nix directly (current repro shells support
x86_64 and aarch64 Linux):

```sh
nix develop .                          # shell with the exact compiler
nix develop . --command bash repro.sh   # deterministic PASS/FAIL harness
```

Only Nix with flakes enabled is required; no additional environment manager
is needed.

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

A repro script uses whichever `roc` is active, so bugs can also be checked
against another compiler through `nix develop .#latest` from the repo root.

## Bugs

Each `bugs/BUG-XXX-*` directory is a self-contained repro with a pinned
`flake.nix` and `flake.lock`, source, `README.md`, and executable `repro.sh`.

- [BUG-009: A mistyped platform requirement segfaults when its nominal type holds a tag-union alias](./bugs/BUG-009-mistyped-requirement-alias-segfault/README.md)
- [BUG-010: A `..` in XDG_CACHE_HOME makes building a URL-platform app fail](./bugs/BUG-010-dotdot-cache-path-outside-workspace/README.md)

## Improvements

Ideas are documented separately from compiler defects and need not have a
harness. There are currently no active improvements.

## Adding a repro

1. `mkdir bugs/BUG-XXX-short-description`
2. Copy the smallest set of Roc sources that reproduces the issue. Keep each
   repro self-contained (no imports outside its directory except a pinned
   platform), even if that means duplicating support files between bugs.
3. Add a `README.md` with a description, expected behavior, actual behavior
   (including the exact panic/crash output), and the repro commands. Include a
   **Shell with the exact compiler** section naming the pinned release and
   showing `nix develop .` from the bug's directory and `roc version` with
   the expected compiler build. Document the harness command:
   `nix develop . --command bash repro.sh`.
4. Add an executable `repro.sh` that accepts only the expected failure as
   success and leaves no local build artifacts behind.
5. Add a `flake.nix` whose default dev shell selects the affected compiler
   by its exact release tag from a pinned roc-overlay revision and includes
   the harness dependencies.
6. Stage the new `flake.nix` so Nix can see it in the Git checkout. Run
   `nix flake lock` in the bug directory and commit its `flake.lock`.
