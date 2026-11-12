# Keep lambda-set specialization from multiplying code in large apps

This is a performance problem, not a correctness bug. Measured on
`nightly-2026-11-07-ad3a5d2` building [Lyceum Study](https://github.com/lyceum-quest/study)
(a Greek reading app, about 9,000 lines of Roc: the app in `signals/` on
[roc-signals](https://github.com/lukewilliamboswell/roc-signals) 0.3.0 and its
packages) at commit `7297b69`, on a 23 GB, x86-64 Linux machine.

## What happens

The app's view is a tree of roc-signals combinators (`Engine.element`, `each`,
`when`, `switch`, `watch`, `Val.map` and handlers) with thousands of call sites,
each with its own closure. With the default lambda-set specialization, every
site's combination of closure types gets its own code:

| `roc build --target=wasm32 …` | build time | `.wasm` | gzipped |
|---|---|---|---|
| `--opt=speed` (default) | ~10 min | 18.9 MB | 4.9 MB |
| `--opt=size` | ~8 min | 12.4 MB | 3.6 MB |
| `--opt=size --specialize=no` (boxy lowering) | 27 s | 1.8 MB | 0.7 MB |
| `--opt=dev` | 9 s | 23.1 MB | 7.2 MB |

In the `--opt=size` module, 11.8 MB of the 12.4 MB is code, in 2,791
functions; the largest single function is 2.9 MB and the next nine are
0.2–0.8 MB each. `--timings` for that build (8 m 47 s):

| phase | time | peak RSS |
|---|---|---|
| Type checking | 47 ms | 1.1 GB |
| Shared lowering + compile-time eval | 10.4 s | 1.0 GB |
| Specializing (LIR passes 46.9 s, ARC 8.4 s) | 57.1 s | 5.4 GB |
| LLVM IR generation | 13.6 s | 2.2 GB |
| LLVM optimize + emit | 262.4 s | 6.0 GB |
| Linking | 183.8 s | 6.1 GB |

Two builds at once run a 23 GB machine out of memory.

Boxy lowering avoids the blowup and passes all of the app's specs, but its
code is much slower where work is heavy: opening a 432-passage work (parsing
its CoNLL-U and passages) takes 6.5 s instead of 0.33 s; typing 15
characters into a field takes 0.33 s instead of 0.16 s.

## Proposed improvement

Bound what specialization does to code size: for example, specialize
small hot functions but box closures passed through deep generic
combinator trees (or past a per-function size budget), so a UI app gets
close to boxy-lowering size and build time with specialized speed in its
hot loops. Separately, the link step (3 minutes for one wasm module) looks
worth a look on its own.

## Current workaround

None in the app yet. Builds take about ten minutes and the shipped module
is 12.4 MB (3.6 MB gzipped). `--specialize=no` is usable for fast spec runs
during development, at the cost of testing a different lowering than ships.

## Related

- The app also hit slow type checking caused by unannotated local closures
  in view functions (about 5 minutes and 8 GB for `roc check` until they were
  lifted to annotated top-level functions; 5 s after); a minimal repro of
  that is still being worked out.
