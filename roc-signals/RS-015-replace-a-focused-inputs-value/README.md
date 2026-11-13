# Let an app replace the value of a text input that has focus

**roc-signals:** `0.5.0` · **Nightly:** `nightly-2026-11-11-7679cc5` (linux x86_64)

A controlled text input never shows a value the app writes while the input has
focus. `setValue` in `platform/runtime.mjs` (lines 316–332 of the 0.5.0 bundle)
defers any differing value until `focusout`, following design.md's
"Controlled inputs", so that echoes of the user's own typing don't move the
caret. That is right for echoes, but it also swallows a value the app means to
replace the text with.

The common case is a chat composer submitted with Enter. The form's submit
handler sends the draft and sets it to `""`. The input keeps focus, so the
empty value is deferred, and the input still shows the sent text. The user's
next keystroke sends an `input` event carrying the old text plus the new key,
which the app takes as the new draft, so the clear is lost and the next message
starts with the previous one. Clicking a submit button instead only works
because focus moves to the button first, so the deferred value is applied on
`focusout`.

### Repro

A spec against any app whose form clears its draft on submit, with the input
named `Message` and the form `Send a message`:

```scheme
(test "Enter clears the composer"
  (steps
    (fill (label "Message") "hi")
    (submit (label "Send a message"))
    (expect-value (label "Message") "")))
```

Expected: the value is `""`. Actual, in both runners: `"hi"`.

### Proposed

Any of these would do:

- A request that replaces a control's value even while it has focus, with the
  caret at the end, for example `SetValue(ref, text)` beside `Focus`, `Blur`
  and `SelectText`.
- A per-write marker on a controlled value meaning "this replaces, it is not
  an echo", for example a `Html.text_input` variant whose value signal carries
  a revision.
- Applying a deferred value at once when it comes from the same turn as a
  `submit` on the control's own form.

### Current workaround

Remount the input after each send, by putting it under an `Engine.when` on a
counter the submit increments (both branches the same input), then send
`Focus(ref)` so the fresh, empty input has focus. `Blur(ref)` followed by
`Focus(ref)` also works, but a ref name is a fixed string, so with several
composers on one page it can focus the wrong one.
[liton](https://github.com/thebrandonlucas/liton) uses the remount
(`ui/Liton.roc`, `composer_input`); remove it once the platform can replace a
focused value.
