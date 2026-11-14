# `roc docs` reports its own broken-link error as an unreported compiler error

> **Archived 2026-11-14:** filed as [roc-lang/roc#13068](https://github.com/roc-lang/roc/issues/13068) on 2026-11-14.

When a doc comment links to a name that does not exist, `roc docs main.roc`
lists the broken link and exits 1, but then also prints an "unreported
error" box saying the compiler stopped with `BrokenDocLinks` without saying
why, and calling that a compiler bug. The broken links should be the whole
report.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64)

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

`main.roc` and `Greet.roc` in this directory: a package exposing `Greet`,
whose `hello` has the doc comment `## Says hello. See [nonexistent].`

### Command

```
roc docs main.roc
```

### Observed

```
Error: 1 doc reference(s) point at non-existent anchors:
  .../Greet.roc:3: [nonexistent] -> #Greet.nonexistent
── ✗ unreported error ──────────────────────────────────────────────────────────

The compiler stopped with the error BrokenDocLinks but did not say why.

This is a bug in the compiler: whatever failed should have explained itself.
Please report it at https://github.com/roc-lang/roc/issues, including the
command you ran.
```

The exit status is 1.

### Expected

The list of broken links and exit status 1, with no "unreported error"
report.

### Notes

- With `See [hello].` instead, `roc docs main.roc` prints
  `Generated docs for main.roc` and exits 0.
- `generated-docs/` is still written when the links are broken.
- The same on `nightly-2026-10-21-5349569` and `nightly-2026-11-12-ce942d6`.

## Related

[roc-lang/roc#9886](https://github.com/roc-lang/roc/issues/9886) (closed) is
about which links `roc docs` counts as broken, not how it reports them.

### Shell with the exact compiler

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-033-docs-broken-links-unreported-error),
`nix develop .` gives `nightly-2026-11-12-ce942d6`, the newest nightly in
its pinned roc-overlay, and the repo's root flake gives the nightly above:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-12-ce942d6
```

### Harness

```sh
nix develop . --command bash repro.sh          # BUG REPRODUCED
nix develop ../..#latest --command bash repro.sh   # BUG REPRODUCED
```

The script first runs `roc docs` on the same package with the link pointing
at `hello`, which must succeed, then accepts only the broken link listed
together with the `BrokenDocLinks` unreported error. It works in a temporary
directory with a fresh cache.
