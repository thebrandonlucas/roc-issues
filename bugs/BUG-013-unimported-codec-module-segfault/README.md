# BUG-013: `roc check` segfaults when an app calls a package's derived decoder without importing its codec module

Found with Roc `nightly-2026-09-26-d6267b4`, the newest nightly on
2026-09-27, which this repro's shell pins. No host is needed.

## Description

`api/` is a package of four modules copied from Kai's platform API (tests and
helpers removed): `Sexpr` is an S-expression codec driven by derived
`encoder_for`/`parser_for`; `Layout`, `Plan` and `Protocol` are nominal types
that declare `is_eq`, `encoder_for` and `parser_for` and nest each other.
`Protocol.decode_response : Str -> Try(Response, [...])` calls
`Sexpr.parse(text)` to decode a nested `Protocol.Response`.

`App.roc` calls it and imports only `api.Protocol`:

```roc
app [main] {
	pf: platform "platform/main.roc",
	api: "api/main.roc",
}

import api.Protocol

main = |text| if Protocol.decode_response(text).is_ok() "ok" else "no"
```

`roc check App.roc` segfaults. `Valid.roc` is the same app with one extra,
unused line, `import api.Sexpr`, and checks cleanly (with an unused-import
warning).

## Expected behavior

`roc check App.roc` succeeds, as for `Valid.roc`.

## Actual behavior

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x400

Stack trace:
Cannot print stack trace: stack tracing is disabled

Please report this issue at: https://github.com/roc-lang/roc/issues
```

The exit status is 139.

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
roc check Valid.roc   # succeeds, one unused-import warning
roc check App.roc     # exit 139, segfaults
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache,
checks that `Valid.roc` passes, and reports success only when
`roc check App.roc` exits 139 with the expected segfault.

## Observations

- **The workaround is an import:** adding `import api.Sexpr` to the app
  avoids the crash; importing `api.Plan` or `api.Layout` instead does not.
- **Not about compile-time evaluation:** `main` is a function here, so
  nothing is evaluated while checking. The same crash happens with
  basic-cli as the platform and `decode_response` called from `main!`.
- **Not reproduced with a small hand-written codec type:** a package with a
  copy of `Sexpr` and a two-level nominal record and tag union checks
  cleanly, so the trigger needs something in the real, deeper type graph
  (`Response` → `Body` → `Candidate` → `Plan` → `Step`, with `Layout` in
  `Request`).
- **How it was found:** in Kai, the crash hid real type errors (a record
  pattern missing a field, an unconstrained error payload); they were only
  reported once the crash was out of the way. Kai's CLI imports `api.Sexpr`.
- **Upstream status:** no existing issue or PR found on 2026-09-27.
