# Comment on lukewilliamboswell/roc-signals#180

Another data point, from an app outside the repository on roc-signals
`0.5.0`: [blu.cx](https://github.com/thebrandonlucas/blu), a personal site and
blog, about 2,000 lines of Roc. It uses a store (location, navigation outbox,
the site's data), a `switch` over 17 kinds of page, nested `each` lists, and
`watch`, `on_post` and `Popstate` sites at the root. It does no heavy work:
it draws text.

All builds are `--target=wasm32 --opt=size` on linux x86_64, one build at a
time.

| Nightly | Specialized raw / gzip -9 | `--specialize=no` raw / gzip -9 | Build time |
|---|---|---|---|
| `nightly-2026-11-10-f7d1f19` | 7,572,924 / 2,236,668 | 1,024,852 / 371,412 | 8 m 6 s → 18 s |
| `nightly-2026-11-11-7679cc5` | segfault in `spec_constr` (roc-lang/roc#12976) | 1,023,962 / 371,272 | — → 26 s |

`--opt=dev` (specialized) on `nightly-2026-11-11-7679cc5`: 14,474,972 /
4,244,406 in 9 s.

With `--specialize=no`:

- **Native specs:** the app's 4 specs (loading, a failed download, every kind
  of page, links with back and forward) pass with a runner built
  `--target=x64musl --opt=size --specialize=no` on `nightly-2026-11-11-7679cc5`.
- **In Chrome** (Chromium build 1248, driven by Playwright, not the spec
  replay): the `--specialize=no` module, loaded by the release's
  `runtime.mjs`, draws every one of the site's 96 pages, each with the same
  text and document title as the site's static HTML for that page.
  Navigating between pages in place, back and forward, and links inside text
  the app draws work. Nothing was timed.
- **The build is reproducible:** building twice gives the same bytes, so
  the site keeps the built module in git and CI checks that it is what the
  source builds.

So `--specialize=no` is what this app ships. On `nightly-2026-11-11-7679cc5`
it is also the only optimized build: the specialized one crashes.

A second app of the same kind,
[kai.blu.cx](https://github.com/thebrandonlucas/kai.blu.cx) (Kai's website,
about 2,700 lines of Roc): a home page whose scroll and keys come through
ports, guides with `Push` and `Popstate`, and a changelog read from GitHub,
with local state (no store), `switch`, nested `each` and `remount_on`. On
`nightly-2026-11-11-7679cc5`, `--target=wasm32` on linux x86_64:

| Build | Raw / gzip -9 | Build time |
|---|---|---|
| `--opt=size` (specialized) | 4,076,358 / 1,366,540 | 2 m 7 s |
| `--opt=size --specialize=no` | 978,793 / 384,292 | 24 s |
| `--opt=dev` | 7,811,329 / 2,502,662 | 8 s |

Here the specialized `--opt=size` build does not crash. In headless Chromium
156, the `--specialize=no` module, loaded by the release's `runtime.mjs`,
passes a scripted walk of every page: keys, scrolling and tabs on the home
page, links, keys, back and the document title in the guides, and the
changelog's two requests. Screenshots of four pages are pixel for pixel the
same as the specialized module's and as the site's earlier Elm build.
Nothing was timed. This app ships `--specialize=no` too.
