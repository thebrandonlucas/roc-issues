# Let an app measure elements and the viewport

> **Archived 2026-11-13:** filed as [lukewilliamboswell/roc-signals#204](https://github.com/lukewilliamboswell/roc-signals/issues/204) on 2026-11-12; closed in favour of [#211](https://github.com/lukewilliamboswell/roc-signals/issues/211) (pointer positions within a declared zone), [#213](https://github.com/lukewilliamboswell/roc-signals/issues/213) (scroll requests) and [#214](https://github.com/lukewilliamboswell/roc-signals/issues/214) (sizes, visibility and scroll offsets reported as they change). Measuring a box on demand (`Measure(ref)`) is declined: the native spec runner has no layout.

> **Rechecked 2026-11-12:** still missing in roc-signals `0.5.0`: no measurement or scroll request, and pointer events still have an empty payload.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (first found on `0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`).

An app cannot read an element's position and size, the viewport, or the
scroll position, and cannot scroll. Elm's `Browser.Dom.getElement`,
`getViewportOf` and `setViewport` have no counterpart, and no event payload
carries pointer or touch coordinates.

A reading app uses them to:

- place a word's popup above or below the word, shifted to stay inside the
  viewport and no taller than the room between header and footer;
- follow which passage of a long reader page is in view as the learner
  scrolls, and scroll a passage into view when they step to it;
- turn a horizontal swipe into the next or previous passage.

## Proposed improvement

- A request that answers with an element's bounding box and the viewport
  (for example `Measure(ref)` answering `Box({ x, y, width, height, viewport })`),
- a scroll request (`ScrollTo(ref)`) and a throttled scroll subscription,
- pointer and touch coordinates in `pointerdown`/`pointermove`/`pointerup`
  payloads.

For specs: a fake layout the runners can be given per element.

## Current workaround

Word popups open in their natural place below the word. Swipe navigation is
left out (the buttons and keyboard remain). Used by the study workspace of
[Lyceum Study](https://github.com/lyceum-quest/study), `signals/WorkspaceView.roc`.
Remove it once the platform can measure.
