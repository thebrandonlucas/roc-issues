# BUG-015: `Json.parse` rejects a `Dec` with more than 18 fraction digits

Found with Roc `nightly-2026-09-19-d025939`, which this repro's shell pins.
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

From this directory, enter a shell with Roc `nightly-2026-09-19-d025939`,
pinned by this repro's `flake.nix` and `flake.lock` (Linux):

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

From this directory:

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

## Upstream status

No existing upstream issue found (searched roc-lang/roc on 2026-10-01).
[roc-lang/roc#10550](https://github.com/roc-lang/roc/issues/10550) (closed)
is a different `Dec.from_str` `Err(BadNumStr)` case: exponential notation
such as `"2e5"`.
