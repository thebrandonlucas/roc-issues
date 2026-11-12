# Let an HTTP request include credentials

> **Rechecked 2026-11-12:** still missing in roc-signals `0.5.0`: `Http` has no credentials field and `runtime.mjs` builds `{ method, headers, signal }` (plus a body); the `fetch` mount option still works.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (first found on `0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`).

`Engine.Request`'s `Http({ method, url, headers, body, timeout_ms })` has no way
to ask for credentials, and `runtime.mjs` calls
`fetch(url, { method, headers, signal, body })`, so the browser's default
`credentials: "same-origin"` applies: a request to another origin carries no
cookies. An app whose account API lives on another origin (a session cookie
set by `accounts.example.org`, read by an app on `study.example.org`) cannot
learn who is signed in or sync on their behalf. Elm offers this as
`Http.riskyRequest`; with `XMLHttpRequest` it is `withCredentials`.

## Proposed improvement

A `credentials` field on `Http` requests (`Omit`, `SameOrigin`, `Include`,
defaulting to the browser's same-origin), passed through to `fetch`. For
specs: the runners can record it so a spec can assert it.

## Current workaround

`mountRocEngineApp` accepts a `fetch` option, so the page's script passes a
fetch that adds `credentials: "include"` to every request:

```js
const withCredentials = (url, init) => fetch(url, Object.assign({}, init, { credentials: "include" }));
runtime.mountRocEngineApp({ wasmUrl, root, fetch: withCredentials });
```

Used by [Lyceum Study](https://github.com/lyceum-quest/study),
`browser-bridge.js`. Remove it once requests can ask for credentials.
