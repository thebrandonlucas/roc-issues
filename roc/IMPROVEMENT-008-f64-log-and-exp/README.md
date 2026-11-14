# Add natural logarithm and exponential functions for F64

`F64` has `sqrt`, `pow`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan` and
`atan2`, but no natural logarithm and no exponential function. Numerical
code such as statistics and decay curves needs both; today each program
must port them (fdlibm's `e_log.c` and `e_exp.c`, about 150 lines of Roc
over `F64.to_bits` and `F64.from_bits`).

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

### Repro

`Logs.roc`:

```roc
Logs := {}

a = F64.ln(2.0)
b = F64.exp(1.0)
c = F64.log(2.0)
```

### Command

```
roc check Logs.roc
```

### Observed

```
── ✗ does not exist ─────────────────────────────────────────────── Logs.roc:3:5

F64.ln does not exist.

a = F64.ln(2.0)
    ^^^^^^

F64 is in scope, but it has no associated ln.

── ✗ does not exist ─────────────────────────────────────────────── Logs.roc:4:5

F64.exp does not exist.

b = F64.exp(1.0)
    ^^^^^^^

F64 is in scope, but it has no associated exp.

── ✗ does not exist ─────────────────────────────────────────────── Logs.roc:5:5

F64.log does not exist.

c = F64.log(2.0)
    ^^^^^^^

F64 is in scope, but it has no associated log.

── 3 errors and 0 warnings ──────────────────────────────────────────── Logs.roc
```

### Proposed

`F64.ln` and `F64.exp`, and the same for `F32`, with IEEE 754 results for
special inputs (`ln(0) = -inf`, `ln` of a negative number or NaN is NaN,
`exp(-inf) = 0`). Ideally both give the same bits on every target, so a
computation run natively and in WebAssembly agrees.

## Related

- [roc-lang/roc#5107](https://github.com/roc-lang/roc/issues/5107) (open):
  logarithm builtins for `F32`, `F64` and `Dec`; its API (names, `_try`
  variants, behaviour for inputs ≤ 0) still needs design. It does not cover
  `exp`.
- [roc-lang/roc#9596](https://github.com/roc-lang/roc/issues/9596)
  (closed): unimplemented builtins, including the logarithm.
