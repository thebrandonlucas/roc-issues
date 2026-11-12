# Publish the browser spec runner with each release

This is a release-packaging gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.3.0`.

The testing guide says specs run natively and replay in headless Chrome, and
to "run both before you trust a change". An app outside the repository gets
the native runner with the platform bundle (`roc build --target=x64musl`), but
the browser runner, `tests/browser/replay.mjs` with its `cdp.mjs`, is not a
release asset: the 0.3.0 release has the bundle, `runtime.mjs`, the docs and
the examples archive, whose `runtime/check.mjs` only mounts each app.

## Proposed improvement

Publish the replay runner (and what it imports) as a release asset that
matches that release's `runtime.mjs` and step grammar, for example
`roc-signals-browser-runner-<version>.zip`.

## Current workaround

Replay from a checkout of the release tag, with the app's own steps:

```sh
RUNNER --emit-steps specs/*.scm > steps.jsonl
CHROME=/path/to/chrome node tests/browser/replay.mjs \
  --wasm app.wasm --runtime runtime.mjs --steps steps.jsonl --json-lines
```

This works with Chromium 156 for an app built on 0.3.0, but ties the app's
browser specs to a checkout of the platform repository.
