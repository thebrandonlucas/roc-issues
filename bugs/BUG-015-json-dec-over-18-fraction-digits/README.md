# `Json.parse` rejects a `Dec` with more than 18 fraction digits

> **Rechecked 2026-11-09:** still reproduces on nightly-2026-11-09-9e85de7, without basic-cli (the issue uses expects; basic-cli 0.26.0 no longer compiles cleanly on this nightly).

Found with Roc `nightly-2026-09-19-d025939`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-015-json-dec-over-18-fraction-digits) pins.
Still present in `nightly-2026-09-26-d6267b4`. Uses basic-cli 0.22.2 only for
printing.

## Description

`Dec` stores 18 fraction digits. Decoding a JSON number with 19 or more
fraction digits into a `Dec` field fails the whole parse with
`InvalidJson("Invalid JSON")`, and `Dec.from_str` returns `Err(BadNumStr)`.
The input is valid JSON. Claude Code's `--output-format json` produces such
numbers in `total_cost_usd` (for example `0.0007735999999999999`), so a record
decoder for that output fails on a few calls while succeeding on others.

## Expected behavior

The number is rounded (or truncated) to 18 fraction digits, as for any other
decimal that `Dec` cannot represent exactly:

```text
19 places: Ok({ c: 0.000773600000000000 })
```

## Actual behavior

```text
18 places: Ok({ c: 0.011101999999999999 })
19 places: Err(InvalidJson("Invalid JSON"))
Dec.from_str: Err(BadNumStr)
```

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-015-json-dec-over-18-fraction-digits), enter a shell with Roc `nightly-2026-09-19-d025939`,
pinned by its `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-19-d025939
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
roc main.roc
```

### Automated harness

From the same directory of [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-015-json-dec-over-18-fraction-digits):

```sh
nix develop . --command bash repro.sh
```

The harness copies `main.roc` to a temporary directory with a fresh cache, so
it downloads basic-cli 0.22.2 and needs network access. It reports success only
when the 18-digit number decodes and both the 19-digit JSON decode and
`Dec.from_str` fail as shown above.

## Observations

- **Boundary:** 18 fraction digits decode and 19 fail. The 19-digit value
  `0.0007735999999999999` is well within `Dec`'s range, so only the extra
  digit is rejected.
- **Compilers:** the harness reproduces the bug on
  `nightly-2026-09-19-d025939` and `nightly-2026-09-26-d6267b4`. On the newer
  nightly, basic-cli 0.22.2 also prints 75 unrelated `redundant open tag union`
  warnings before the output.

## Related

[roc-lang/roc#10550](https://github.com/roc-lang/roc/issues/10550) (closed)
is a different `Dec.from_str` `Err(BadNumStr)` case: exponential notation
such as `"2e5"`.
