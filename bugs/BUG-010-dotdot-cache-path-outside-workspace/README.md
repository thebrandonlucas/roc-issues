# BUG-010: A `..` in XDG_CACHE_HOME makes building a URL-platform app fail with PathOutsideWorkspace

Found with Roc `nightly-2026-09-23-c7852fd`. Still reproduces on
`nightly-2026-09-26-d6267b4`, the newest nightly on 2026-09-26, which this
repro's shell pins. No real host is needed.

## Description

`platform/main.roc` is a minimal platform that requires `main : Str`. It is
bundled with `roc bundle` and served from localhost, and an app uses it as a
URL package:

```roc
app [main] { pf: platform "http://127.0.0.1:<port>/<hash>.tar.zst" }

main = "hi"
```

When `XDG_CACHE_HOME` is spelled with a `..` that climbs out of the app's
directory (for example `$PWD/../cache` from inside the app directory),
`roc check` passes, but `roc build` and running the app (`roc App.roc`) stop
with an error the compiler does not explain. The same commands work when
`XDG_CACHE_HOME` names the same directory canonically.

## Expected behavior

`roc build App.roc` succeeds, as it does with a canonical `XDG_CACHE_HOME`:

```text
0 errors and 0 warnings found in 59ms while successfully building:
```

## Actual behavior

```text
── ✗ unreported error ──────────────────────────────────────────────────────────

The compiler stopped with the error PathOutsideWorkspace but did not say why.

This is a bug in the compiler: whatever failed should have explained itself. Please report it at https://github.com/roc-lang/roc/issues, including the command you ran.
```

The exit status is 1.

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-26-d6267b4`,
pinned by this repro's `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-26-d6267b4
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
t=$(mktemp -d)
cp -R platform "$t/platform"
mkdir -p "$t/platform/targets/x64musl" "$t/platform/targets/arm64musl" "$t/srv" "$t/app"
touch "$t/platform/targets/x64musl/libhost.a" "$t/platform/targets/arm64musl/libhost.a"
(cd "$t/platform" && roc bundle main.roc targets/*/libhost.a --output-dir "$t/srv")
python3 -m http.server 8791 --bind 127.0.0.1 --directory "$t/srv" &
cd "$t/app"
printf 'app [main] { pf: platform "http://127.0.0.1:8791/%s" }\n\nmain = "hi"\n' \
  "$(ls "$t/srv")" > App.roc
XDG_CACHE_HOME=$PWD/../cache roc check App.roc          # exit 0
XDG_CACHE_HOME=$PWD/../cache roc build App.roc          # exit 1, PathOutsideWorkspace
XDG_CACHE_HOME=$t/cache roc build App.roc               # exit 0
kill %1
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness bundles the platform in a temporary directory and serves it from
localhost on a free port. It checks that `roc build` succeeds with a canonical
`XDG_CACHE_HOME` and that `roc check` passes with the `..` spelling. It then
reports success only when `roc build` with the `..` spelling exits 1 with the
PathOutsideWorkspace error.

## Observations

- **Compilers:** it reproduces on `nightly-2026-09-23-c7852fd`,
  `nightly-2026-09-24-f45bfbe`, `nightly-2026-09-25-1ab6804` and
  `nightly-2026-09-26-d6267b4`.
- **Commands:** `roc build` and `roc App.roc` fail; `roc check` passes. A warm
  cache (filled with a canonical path first) fails the same way.
- **Which spellings fail** (run from the app directory `app/`):
  - `$PWD/../cache` fails.
  - `./cache` fails.
  - `cache`, `$PWD/./cache`, `$PWD/sub/../cache` (which resolves inside the
    app directory) and a path through a symlink all work.
- **Not needed:** a working host. The empty `libhost.a` only satisfies the
  `targets:` section; without that section the build stops earlier with a
  "missing targets section" error.
- **Needs a URL platform:** the same app with a local path platform
  (`platform "../platform/main.roc"`) builds with the `..` spelling.
- **Likely cause:** on upstream `main` at
  [roc-lang/roc@d6267b4](https://github.com/roc-lang/roc/commit/d6267b4efa),
  `BuildEnv.addWorkspaceRoot` in `src/compile/compile_build.zig` skips a
  package directory when it is textually within an existing workspace root
  (`isWithinRoot` is a string prefix check). The downloaded package's
  directory, `app/../cache/roc/packages/<hash>`, starts with the app's root
  `app/`, so it is not registered. `ensurePackage` then resolves the path to
  `cache/roc/packages/<hash>`, which is outside every registered root, and
  returns `error.PathOutsideWorkspace`, which no report explains.
- **Upstream status:** no existing issue or PR found on 2026-09-26 for
  `PathOutsideWorkspace` or `XDG_CACHE_HOME`.
