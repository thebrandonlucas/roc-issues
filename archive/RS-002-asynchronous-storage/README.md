# Let an app use IndexedDB (or another asynchronous host store)

> **Archived 2026-11-12:** filed as [lukewilliamboswell/roc-signals#201](https://github.com/lukewilliamboswell/roc-signals/issues/201) with the `0.3.0` text, but already addressed by roc-signals `0.4.0`, whose typed ports (`Port.call`, `Port.command`, `Port.subscription`, registered with `Program.with_ports` and answered by JavaScript passed to `mountRocEngineApp`) are the generic host request proposed below, with spec steps (`expect-port-call`, `answer-port`). The release's Reading List example keeps its records in IndexedDB this way. Still so in `0.5.0`.

> **Closed 2026-11-13:** roc-signals#201 closed: ports (`0.4.0`) resolve it; [#218](https://github.com/lukewilliamboswell/roc-signals/issues/218) adds a page of port recipes, IndexedDB among them.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`.

The only storage an app can use is local storage (`StorageGet`, `StorageSet`,
`StorageRemove` and the boot keys). An app that is ported from, or must share
data with, a page that keeps its records in IndexedDB (structured records in
object stores, more than local storage's few megabytes) cannot reach them.

## What works today

The custom-element route that design.md suggests for third-party widgets
carries requests and answers:

- the app renders `<my-store data-request="...">`, and a page script defines
  the element, performing the request in `attributeChangedCallback`;
- the element answers by setting its `value` and dispatching a bubbling
  `change` event, which reaches a `change` handler on the element with
  `target.value` as the payload (runtime.mjs `payloadOf`).

It is awkward in ways an effect would not be:

1. The attribute is written only when its value changes, so every request
   needs a fresh id, and a transition can send only one batch (a second write
   in the same turn replaces the first).
2. Answers are DOM events, not effect results: no `on_result` with the value
   the request was issued for, no in-flight bound, no delivery to a surviving
   owner when the issuing site is disposed. The app matches answers to
   requests by id itself, and the element must stay mounted for the app's
   whole life.
3. Specs fake answers with `(change (test-id "store") "<json>")` and check
   requests with `expect-attr` on the attribute's JSON. This works in both
   runners, but nothing ties a faked answer to a request the app issued.

## Proposed improvement

Either IndexedDB requests (`IdbGet`, `IdbGetAll`, `IdbPut`, `IdbDelete`,
`IdbClear` with database, version and store, answered like `StorageGet`), or a
generic request the page answers, such as `Host(name, payload)` answered with
`Value(text)` by a handler the page registers with the runtime. The second
would also cover other asynchronous browser APIs without app-specific code in
the platform. Specs would stub either as they stub HTTP.

## Current workaround

The custom element above, with a JSON batch of `{id, operation, store, key,
value}` messages per attribute value and one JSON answer per message,
`{id, ok, value, now}`, per `change` event (`now` is the wall clock; see the
wall-clock draft in this folder).
