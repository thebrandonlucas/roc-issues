# Spec steps for a right-click, a request's body, and Enter in a textarea

**roc-signals:** `0.6.0` (unchanged in `0.7.0-rc1`) · **Nightly:** `nightly-2026-11-18-a520eed` (linux x86_64)

Three things an app does that a `.scm` spec cannot drive or check, in either
runner:

1. **A right-click.** `contextmenu` is outside the spec grammar
   (testing.md, "Pointer gestures": its timing differs by operating
   system). `(pointer-down LOC :button secondary)` presses the button but
   raises no `contextmenu`, so an app's own context menu, opened from a
   `contextmenu` handler, has no spec.
2. **A request's body.** `expect-request` checks `:method`, `:url`,
   `:cache` and `:credentials`, and nothing else. A spec can see that a
   form posted to `/api/messages`, but not what it sent, which is usually
   what the form's logic decides.
3. **Enter in a textarea.** `(press LOC "Enter")` in a `textarea` is
   refused unless a keymap prevents it, because the runners do not model
   the newline. So a spec cannot check that plain Enter in a composer that
   sends on Ctrl+Enter starts a new line and sends nothing, and `fill`
   cannot press a key.

### Proposed

1. A `(context-menu LOC)` step that dispatches one `contextmenu` at the
   element (after the press of a secondary button, if a spec wants that
   too), with the browser's menu always suppressed.
2. `:body "text"` on `expect-request` (the exact body as sent), and perhaps
   `:headers`, as `stub-http` already takes them for answers.
3. Model Enter in a textarea as inserting `"\n"` at the end of the value
   with one `input` event, as `fill` would, or let a spec write
   `(press LOC "Enter" :allow-default)` and then assert the value with
   `expect-value`.
