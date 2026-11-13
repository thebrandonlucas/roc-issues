# Deliver key events that reach the document

> **Archived 2026-11-13:** filed as [lukewilliamboswell/roc-signals#203](https://github.com/lukewilliamboswell/roc-signals/issues/203) on 2026-11-12; closed in favour of [#212](https://github.com/lukewilliamboswell/roc-signals/issues/212), which delivers keys at the document and their modifiers, with a declared keymap in place of a `KeyDowns` subscription.

> **Rechecked 2026-11-12:** still missing in roc-signals `0.5.0`: listeners are on the mount root and the `keydown` payload is `event.key` only.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (first found on `0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`).

The runtime listens for events on the mount root and dispatches each to the
nearest element with a handler. A key pressed while nothing in the app has
focus targets `document.body`, outside the mount root, so no handler runs.
The `keydown` payload is also only the key: no modifier state, and no
indication of whether the target was a text field.

A reading app wants page-wide shortcuts (← and → or j and k between
passages, Escape to close a popup) that work as soon as the page loads, that
ignore keys typed into text fields, and that leave Ctrl/⌘ shortcuts to the
browser.

## Proposed improvement

- A subscription to document key events (for example `KeyDowns` answering
  `Key({ key : Str, ctrl : Bool, meta : Bool, alt : Bool, shift : Bool, editable : Bool })`,
  where `editable` says the target was a text field or select), and
- modifier state on element `keydown` payloads.

For specs: a step such as `(press "j")` in both runners.

## Current workaround

The app shell has `tabindex="-1"`, takes focus at mount (a `Focus` request
on its `ref`) and keeps it on clicks inside it, so key events reach its
`keydown` handler. Text fields carry a no-op `keydown` handler so their keys
stop there. Modifier keys cannot be told apart. Used by the study workspace
of [Lyceum Study](https://github.com/lyceum-quest/study), `signals/View.roc`.
Remove it once the platform delivers document key events.
