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

## Related

- [lukewilliamboswell/roc-signals#180](https://github.com/lukewilliamboswell/roc-signals/issues/180):
  whether to recommend `--specialize=no --opt=size` for roc-signals apps,
  with measurements of smaller apps.
