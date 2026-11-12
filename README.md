# roc-issues

Drafts of issues for [Roc](https://www.roc-lang.org) and projects built on
it, each in a folder named for the project whose tracker it goes to. Bugs
come with a self-contained reproduction pinned to the exact compiler they
were found on.

| Folder | Project | Filed at |
|---|---|---|
| [`roc/`](./roc) | The Roc compiler and its builtins | [roc-lang/roc](https://github.com/roc-lang/roc/issues) (ideas: Roc Zulip first) |
| [`basic-cli/`](./basic-cli) | [basic-cli](https://github.com/roc-lang/basic-cli), Roc's platform for command-line apps | [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli/issues) (ideas: Roc Zulip first) |
| [`basic-webserver/`](./basic-webserver) | [basic-webserver](https://github.com/roc-lang/basic-webserver), Roc's platform for web servers | [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver/issues) (ideas: Roc Zulip first) |
| [`roc-signals/`](./roc-signals) | [roc-signals](https://github.com/lukewilliamboswell/roc-signals), a Roc platform for browser apps | [lukewilliamboswell/roc-signals](https://github.com/lukewilliamboswell/roc-signals/issues) |
| [`archive/`](./archive) | Drafts that were filed, fixed or dropped, from every project | — |

Within a folder, the prefix says what a draft is: `BUG-XXX` (a defect, with a
harness where it can have one), `IMPROVEMENT-XXX` (a missing capability) or,
for roc-signals, `RS-XXX`. Numbers are never reused, across folders too.

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


## Reproducing on the newest nightly

`nightly.json` pins the nightly the ready issues were last checked on, and
`latest` builds it from Roc's own download for each platform:

```sh
nix develop .#latest          # a shell with that compiler
cd roc/BUG-027-*/             # then follow the issue's Command
```

`scripts/recheck.sh` moves the pin to the newest nightly and reruns every
issue (see AGENTS.md, "Rechecking on the newest nightly").

## Roc

Each `roc/BUG-XXX-*` directory is a self-contained repro with a pinned
`flake.nix` and `flake.lock`, source, `README.md`, and executable `repro.sh`.
Improvements are design ideas and need not have a harness.

Bugs:

- [BUG-018: intermittent SIGSEGV/SIGABRT in `roc check` on CI runners](./roc/BUG-018-intermittent-check-crash-on-ci/README.md) (observed on CI only)
- [BUG-027: Unary minus directly before a `var` name is rejected as unexpected expression syntax](./roc/BUG-027-unary-minus-before-var-parse-error/README.md)
- [BUG-028: A derived `parser_for` does not exist when used before its type's declaration](./roc/BUG-028-derived-parser-for-before-declaration/README.md)

Improvements:

- [IMPROVEMENT-005: Make a warm `roc app.roc` as fast as a warm cached build](./roc/IMPROVEMENT-005-warm-roc-run-overhead/README.md)
- [IMPROVEMENT-006: Let an app import modules from outside its own directory](./roc/IMPROVEMENT-006-import-modules-outside-app-dir/README.md)
- [IMPROVEMENT-007: Let `Dec.from_str` and JSON decoding accept more than 18 fraction digits](./roc/IMPROVEMENT-007-dec-excess-fraction-digits/README.md)
- [IMPROVEMENT-008: Add natural logarithm and exponential functions for F64](./roc/IMPROVEMENT-008-f64-log-and-exp/README.md)
- [IMPROVEMENT-009: Provide Unicode case mapping for Str](./roc/IMPROVEMENT-009-unicode-case-mapping/README.md)
- [IMPROVEMENT-010: Keep lambda-set specialization from multiplying code in large apps](./roc/IMPROVEMENT-010-specialization-code-size/README.md)

## basic-cli

- [IMPROVEMENT-004: Let basic-cli read a file without following symlinks and set its mode](./basic-cli/IMPROVEMENT-004-basic-cli-no-follow-open-and-chmod/README.md)

## basic-webserver

- [IMPROVEMENT-011: Let a server keep a client connection open across requests and replace it when it drops](./basic-webserver/IMPROVEMENT-011-long-lived-client-connections/README.md)

## roc-signals

Found porting a browser app to roc-signals. They are platform gaps, not
compiler bugs, so they have no harness; each says which roc-signals release
it was last checked on (all on `0.5.0`, 2026-11-12).

- [RS-003: Publish the browser spec runner with each release](./roc-signals/RS-003-browser-spec-runner-in-release/README.md)
- [RS-004: Deliver key events that reach the document](./roc-signals/RS-004-document-key-events/README.md)
- [RS-005: Let an app measure elements and the viewport](./roc-signals/RS-005-layout-measurement/README.md)
- [RS-006: Keep attributes whose value is the empty string](./roc-signals/RS-006-empty-attribute-values/README.md) (a defect)
- [RS-008: Let an HTTP request include credentials](./roc-signals/RS-008-http-credentials/README.md)
- [RS-013: Let a view draw a tree whose depth comes from data](./roc-signals/RS-013-data-depth-trees/README.md)

## Archived

Drafts that were filed, no longer reproduce or are no longer needed, kept
with a dated note at the top of each README explaining why. They stay in one
flat `archive/` folder so links from filed issues keep working.

- [BUG-009: A mistyped platform requirement segfaults when its nominal type holds a tag-union alias](./archive/BUG-009-mistyped-requirement-alias-segfault/README.md) (fixed in `nightly-2026-09-28-9927ba8`)
- [BUG-010: A `..` in XDG_CACHE_HOME makes building a URL-platform app fail](./archive/BUG-010-dotdot-cache-path-outside-workspace/README.md)
- [BUG-011: `roc fmt` deletes a multiline-string line that has an invalid escape](./archive/BUG-011-fmt-deletes-invalid-escape-string-line/README.md) (fixed in `nightly-2026-10-01-a932c65`)
- [BUG-013: `roc check` segfaults when an app calls a package's derived decoder without importing its codec module](./archive/BUG-013-unimported-codec-module-segfault/README.md) (fixed in `nightly-2026-10-02-bba1acc`)
- [BUG-014: Interpolating `var` in an imported module panics](./archive/BUG-014-var-constant-interpolation-panic/README.md) (fixed in `nightly-2026-09-26-d6267b4`)
- [BUG-017: the code `roc build` emits depends on the worker count](./archive/BUG-017-build-output-depends-on-jobs/README.md)
- [BUG-023: a record `Json.parse` decoder passed to `List.map_try` panics `roc check`](./archive/BUG-023-json-record-decoder-through-map-try-panic/README.md) (fixed in `nightly-2026-09-28-9927ba8`)
- [IMPROVEMENT-002: Let basic-cli apps handle SIGINT (Ctrl-C)](./archive/IMPROVEMENT-002-basic-cli-sigint-handling/README.md)
- [IMPROVEMENT-003: Let `roc bundle` include files outside the entry file's directory](./archive/IMPROVEMENT-003-bundle-files-outside-entry-dir/README.md)
- [BUG-020: `roc test` fails an expect because parsed rows hold garbage strings](./archive/BUG-020-test-after-build-wrong-constant/README.md)
- [BUG-022: an unused `Str` statement is reported as an interpolation mismatch elsewhere](./archive/BUG-022-unused-statement-reported-as-interpolation-mismatch/README.md)
- [BUG-019: `roc build` segfaults in lir_gen when a platform provides a value](./archive/BUG-019-cold-build-value-entrypoint-segfault/README.md)
- [BUG-016: two calls of one method on an inferred type get a single type](./archive/BUG-016-method-on-inferred-type-unified-across-calls/README.md)
- [BUG-025: `roc test` segfaults when an expect reaches code with a check error](./archive/BUG-025-roc-test-segfault-on-any-check-error/README.md)
- [BUG-024: A type mismatch on an interpolated string literal is reported at a different expression](./archive/BUG-024-interpolated-literal-mismatch-wrong-region/README.md)
- [BUG-021: `roc check` segfaults on a record update whose list element misses a field](./archive/BUG-021-record-update-list-missing-field-segfault/README.md)
- [BUG-026: `roc check` segfaults in boxy_lowering when a nominal record's list elements miss a field](./archive/BUG-026-nominal-list-element-fields-boxy-segfault/README.md)
- [BUG-012: `roc test` panics when a platform and its package both have a module with the same name](./archive/BUG-012-test-platform-and-package-module-same-name/README.md)
- [RS-002: Let an app use IndexedDB (or another asynchronous host store)](./archive/RS-002-asynchronous-storage/README.md) (filed as lukewilliamboswell/roc-signals#201; addressed by ports in `0.4.0`)
- [RS-001: Let an app read the wall-clock time](./archive/RS-001-wall-clock-time/README.md) (filed as lukewilliamboswell/roc-signals#200)
- [RS-007: Let an app drag things with the pointer and animate the result](./archive/RS-007-pointer-drag-and-view-transitions/README.md) (filed as lukewilliamboswell/roc-signals#199)

## Adding a repro

1. `mkdir roc/BUG-XXX-short-description` (or the folder of the project the
   bug belongs to), with the next number not used anywhere in the repo
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
