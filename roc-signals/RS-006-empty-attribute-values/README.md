# Keep attributes whose value is the empty string

> **Rechecked 2026-11-12:** still present in roc-signals `0.5.0`: `runtime.mjs` `setAttr` removes `value=""` and any other non-boolean attribute set to `""`.

This is a defect in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (first found on `0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`).

`runtime.mjs`'s `setAttr` removes an attribute whose value is `""` (for any
non-boolean attribute, and for `value` after setting the property). HTML
gives the empty value meaning in places, most visibly `<option value="">`:
without the attribute an option's value is its text, so

```roc
Html.select(Engine.const("Works"), Engine.const(""), [], [Html.option("", "All works"), Html.option("a", "A")], h)
```

renders `<option>All works</option>`; the select's value `""` matches no
option and the select shows blank, and choosing "All works" reports
`"All works"` rather than `""`. `alt=""` (a decorative image) and `aria-label`
style uses have the same problem.

## Expected

`Engine.attr("value", "")` renders `value=""`; only boolean attributes treat
`""` as absent.

## Current workaround

Use a sentinel value (`"*"`) for the empty choice and map it back in the
handler. Used by the Today scope of [Lyceum Study](https://github.com/lyceum-quest/study),
`signals/LibraryView.roc` (`all_works`).
