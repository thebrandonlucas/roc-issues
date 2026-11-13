# Comment on lukewilliamboswell/roc-signals#180

Measurements from two apps on roc-signals `0.5.0`, built with
`nightly-2026-11-12-ce942d6` (`roc build --no-cache --target=wasm32`, linux
x86_64, one build at a time). Sizes are raw / gzip -9 bytes.

**A site of 17 kinds of page** (about 2,000 lines of Roc: a store, a
`switch` over the pages, nested `each`, and `watch`, `on_post` and
`Popstate` at the root; it draws text and does no heavy work):

| Build | Size | Build time |
|---|---|---|
| `--opt=size` | 6,675,136 / 2,066,850 | 4 m 44 s |
| `--opt=size --specialize=no` | 1,024,902 / 371,723 | 20 s |
| `--opt=dev` | 12,122,641 / 3,408,018 | 11 s |

- Its 4 native specs (loading, a failed download, every kind of page,
  links with back and forward) pass with a runner built
  `--target=x64musl --opt=size --specialize=no`.
- In Chromium, driven by Playwright, the `--specialize=no` module (built
  with `nightly-2026-11-11-7679cc5`) and the release's `runtime.mjs` draw
  all 96 pages with the same text and document title as the site's static
  HTML; navigating in place, back and forward, and links inside drawn text
  work. Nothing was timed.
- Building twice gives the same bytes.

**A site of a few pages** (about 2,700 lines: scroll and keys through
ports, `Push` and `Popstate`, two HTTP requests, local state with no store,
`switch`, nested `each` and `remount_on`):

| Build | Size | Build time |
|---|---|---|
| `--opt=size` | 4,128,560 / 1,366,027 | 2 m 3 s |
| `--opt=size --specialize=no` | 978,812 / 384,211 | 19 s |
| `--opt=dev` | 6,630,028 / 2,052,592 | 7 s |

- In headless Chromium 156, the `--specialize=no` module (built with
  `nightly-2026-11-11-7679cc5`) passes a scripted walk of every page: keys,
  scrolling, tabs, links, back and forward, the document title and both
  requests. Screenshots of four pages match the specialized module's pixel
  for pixel. Nothing was timed.

Both sites ship `--specialize=no`.
