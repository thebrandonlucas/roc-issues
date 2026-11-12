# Unary minus directly before a `var` name is rejected as unexpected expression syntax

Found with Roc `nightly-2026-11-07-ad3a5d2`, which this bug's shell in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-027-unary-minus-before-var-parse-error) pins.
Still reproduces on `nightly-2026-11-11-7679cc5`, the newest nightly on
2026-11-11. No platform is needed.

## Description

`Var.roc` negates a `var` in place:

```roc
negated : I64 -> I64
negated = |start| {
	var $n = start
	$n = -$n
	$n
}

main! = |_| Ok({})
```

`roc check` stops at the `-`: it does not accept unary minus directly before a
`$` name. Negating an ordinary name (`-n`) or a parenthesized `var`
(`-($n)`) parses, as `Plain.roc` shows.

## Expected behavior

`roc check Var.roc` reports no errors, as `roc check Plain.roc` does for `-n`
and `-($n)`.

## Actual behavior

```text
── ✗ unexpected expression syntax ────────────────────────────────── Var.roc:4:7

I was parsing an expression, and this token cannot start an expression here.

$n = -$n
     ^

Expressions can be names, literals, tags, records, lists, tuples, lambdas,
blocks, conditionals, matches, or function calls.

For example:
    add(1, 2)

I found - here.

── ✗ type mismatch ───────────────────────────────────────────────── Var.roc:4:8
```

The type mismatch that follows is a consequence of the parse error.

## Reproduction

### Shell with the exact compiler

From this bug's directory in [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-027-unary-minus-before-var-parse-error), enter a shell with Roc `nightly-2026-11-07-ad3a5d2`,
pinned by its `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-07-ad3a5d2
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually with:

```sh
roc check Plain.roc   # no errors: -n and -($n)
roc check Var.roc     # unexpected expression syntax at Var.roc:4:7
```

### Automated harness

From the same directory of [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-027-unary-minus-before-var-parse-error):

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache. It
checks that `Plain.roc` has no errors, then reports success only when
`roc check Var.roc` reports unexpected expression syntax at `Var.roc:4:7`.

## Observations

- **Compilers:** it reproduces on `nightly-2026-11-07-ad3a5d2` and
  `nightly-2026-11-11-7679cc5`.
- **Parses:** `-n` for an ordinary name, `-($n)`, `$n.negate()`, `0 - $n`.
- **How it was found:** porting floating-point code from C, where
  `if (j < 0) n = -n;` became `$n = -$n`. The code now uses `$n.negate()`.
