# Make a warm `roc app.roc` as fast as a warm cached build

> **Archived 2026-11-13:** no longer shown on `nightly-2026-11-12-ce942d6`: with a warm cache, `roc app.roc` on basic-cli `0.28.0` takes 0.13–0.15 s against 0.09–0.12 s for a cached `roc build --opt=dev` plus the binary, for a hello world and for an app importing a 600-function module alike. The larger gap below was measured on `nightly-2026-09-23-c7852fd` with a platform that no longer links.

This is a performance gap, not a correctness bug. With a warm cache, running an
app with `roc app.roc` costs about 0.5 s more than building it with
`roc build --opt=dev` and running the binary, and the gap grows with the
amount of code the app imports.

Measured on `nightly-2026-09-23-c7852fd` (not re-measured on later nightlies), with the platform and plugin prototype of [Kai](https://github.com/thebrandonlucas/kai) (a CLI for Nix and Guix written in Roc), which reads a project's `Kaifile.roc`:

| Step (warm cache) | Time |
|---|---|
| `roc check app.roc` | 0.04 s |
| `roc build --opt=dev app.roc` (cached) | 0.08 s |
| the built binary | under 0.01 s |
| `roc app.roc` | 0.5–0.9 s wall, about 1 s CPU, 240 MB RSS |

A smaller app on a smaller platform ran in 0.09 s, and the same app grew from
0.28 s to 0.62 s once the platform imported one more package
(`Weaver`, a CLI parser).

## Proposed improvement

Let `roc app.roc` reuse the cached build (or cached evaluation) when no source
changed, so a warm run costs about the same as `roc build --opt=dev` plus
running the binary.

## Current workaround

Run a cached `roc build --opt=dev` and then execute the binary. On
`c7852fd` that path could segfault when two apps shared a cache
(roc-lang/roc#11710, fixed by roc-lang/roc#11676 in
`nightly-2026-09-26-d6267b4`).

Used by: Kai, which evaluates each project's `Kaifile.roc` on every command.
