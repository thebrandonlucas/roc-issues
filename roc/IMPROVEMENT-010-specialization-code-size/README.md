# Keep lambda-set specialization from multiplying code in large apps

A UI app built from combinators (`Engine.element`, `each`, `when`,
`switch`, `Val.map`, handlers) has thousands of call sites, each with its
own closure, and lambda-set specialization gives every combination of
closure types its own code. For a roc-signals app of about 10,900 lines of
Roc, `--opt=size` takes 6.5 minutes and 5.5 GB to build a module five times
the size of the `--specialize=no` one, which builds in half a minute but
runs much slower where work is heavy.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), roc-signals `0.5.0`

### Measurements

`roc build --no-cache --target=wasm32 <flags> main.roc`, one build at a
time on an 8-core x86_64 Linux machine with 23 GB:

| Flags | `.wasm` (bytes) | gzip -9 | Build time | Peak RSS |
|---|---|---|---|---|
| `--opt=size` | 11,203,476 | 3,474,485 | 387 s | 5.5 GB |
| `--opt=size --specialize=no` | 2,171,413 | 822,217 | 32 s | 1.3 GB |

### Proposed

Bound what specialization does to code size: for example, specialize small
hot functions but box closures passed through deep generic combinator trees
(or past a per-function size budget), so a UI app gets close to
`--specialize=no` size and build time with specialized speed in its hot
loops.

### Notes

- `--specialize=no` code is much slower where work is heavy: in this app,
  parsing a 432-item document took 6.5 s instead of 0.33 s, and typing 15
  characters into a field 0.33 s instead of 0.16 s (measured on
  `nightly-2026-11-07-ad3a5d2`).
- In a second roc-signals 0.5.0 app (about 4,000 lines, `nightly-2026-11-11-7679cc5`),
  the `--specialize=no` module (2.3 MB against 10.3 MB) is slow in reference
  counting rather than in the app's own work. Opening a list of 200 rich
  rows takes 2.6 s instead of 0.31 s, and replacing it with a 6-row list
  6.9 s instead of 0.05 s. A CPU profile of the `--debug` module puts about
  95% of that in `.Lwalk.incref` (57%), `roc_builtins_list_decref_with`,
  `RocList.makeUnique` and `roc_llvm_rc_decref`, under the engine's list
  operations: they seem to find their lists shared, so each copies its list
  and increfs every element deeply. The same app's native spec runner
  (`--target=x64musl`) rebuilds after a one-line change in 595 s specialized
  and 73 s without.

## Related

- [lukewilliamboswell/roc-signals#180](https://github.com/lukewilliamboswell/roc-signals/issues/180):
  whether to recommend `--specialize=no --opt=size` for roc-signals apps,
  with measurements of smaller apps.
