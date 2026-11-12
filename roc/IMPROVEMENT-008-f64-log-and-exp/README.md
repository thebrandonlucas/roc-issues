# Add natural logarithm and exponential functions for F64

This is a capability gap, not a compiler bug. `F64` has `sqrt`, `pow`, `sin`,
`cos`, `tan`, `asin`, `acos`, `atan` and `atan2`, but no natural logarithm and
no exponential function (`ln`/`log`, `exp`). Checked on
`nightly-2026-11-07-ad3a5d2` and `nightly-2026-11-11-7679cc5`.

Numerical code such as spaced-repetition schedulers (forgetting curves are
`exp` and `pow`, parameter clipping uses `ln`) and statistics needs both.

## Proposed improvement

Add `F64.ln` (natural logarithm) and `F64.exp`, and the same for `F32`, with
IEEE 754 results for special inputs (`ln(0) = -inf`, `ln` of a negative number
or NaN is NaN, `exp(-inf) = 0`). Ideally both give the same bits on every
target, so a computation run natively and in WebAssembly agrees.

## Current workaround

Port fdlibm `e_log.c` and `e_exp.c` to Roc using `F64.to_bits` and
`F64.from_bits` for the word manipulation (about 150 lines). This is exact and
portable, but every project needing a logarithm must carry its own copy.

Used by: the FSRS scheduler port of [Lyceum Study](https://github.com/lyceum-quest/study)
(a Greek reading app), `packages/fsrs/FsrsMath.roc`, which ports both to
match the JavaScript reference implementation bit for bit.

## Related

- roc-lang/roc#5107 (open) tracks logarithm builtins for `F32`, `F64` and
  `Dec`; its API (names, `_try` variants, behaviour for inputs ≤ 0) still
  needs design. It does not cover `exp`.
- roc-lang/roc#9596 (closed) tracked unimplemented builtins and lists the
  logarithm item.
