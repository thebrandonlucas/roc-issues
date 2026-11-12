# Let an app drag things with the pointer and animate the result

> **Archived 2026-11-12:** filed as [lukewilliamboswell/roc-signals#199](https://github.com/lukewilliamboswell/roc-signals/issues/199).

> **Rechecked 2026-11-12:** still missing in roc-signals `0.5.0` (protocol version 4): pointer payloads are empty, the only handler policies are `:prevent` and `:files`, and the spec language rejects `pointer-down`.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (protocol version 4; first found at commit
`6aee90cbc3d9d39a80d9a41e6666ff75c2aa0e0f`, protocol version 3, with Roc
`nightly-2026-11-07-ad3a5d2`).

An app can listen for `pointerdown`, `pointermove` and `pointerup`: the
runtime adds one delegated listener per event type on the mount root
(`platform/runtime.mjs`, `listen`). But `payloadOf` gives those events an
empty payload, so a handler learns that the pointer moved and not where. There
is no way to capture the pointer, to stop an event reaching an outer handler,
or to animate a DOM change. So an app cannot let the user drag a pane, a card
or a list item and drop it where the pointer is, with a preview while dragging
and an animated move into place, which is how tiling window managers such as
Hyprland and i3 feel and what dashboards (Home Assistant sections, Grafana)
offer.

A tiling agent UI uses it to:

- drag a pane by its header and drop it beside, above, below or into another
  pane, choosing by where in the target the pointer is (the four triangles of
  Hyprland's dwindle, or i3's centre-to-join and edge-to-split zones), with a
  drop preview drawn while dragging;
- animate the other panes sliding to their new places when one is dropped,
  added or closed;
- drag a divider to resize two panes;
- reorder tabs and list items by dragging, on a mouse and on touch.

## Proposed improvement

Each item is part of the engine protocol, so it needs the protocol version
bump, `Dom.roc`, `runtime.mjs`, the contract tests and design.md's Appendix B.
Items 1 and 2 are the minimum for dragging; 6 is for animation.

1. **Pointer payloads.** For `pointerdown`, `pointermove`, `pointerup` and
   `pointercancel`: `pointerId`, `pointerType`, `button`, `buttons`, the
   modifier keys, `clientX`/`clientY`, and the pointer's position relative to
   the element whose handler runs, with that element's width and height. The
   relative position makes drop zones pure arithmetic in Roc, without a
   measuring round trip. A fixed field order, as text or binary, like the
   existing payloads.
2. **A `:capture` handler policy** (`pointerdown:capture`) that calls
   `setPointerCapture(event.pointerId)` while the event is dispatched. It
   cannot be a later request: capture throws once the pointer is no longer
   active. Elements that start a drag also need `touch-action: none`, which an
   app can already set in its CSS.
3. **Coalesced `pointermove`.** At most one `pointermove` turn per animation
   frame per handler, keeping the latest event, so a drag doesn't flood the
   ingress queue with a Wasm turn per mouse event.
4. **A `:stop` handler policy** (`stopPropagation`), already listed as a
   target in design.md. A pane's own pointer handlers and the layout's drag
   handlers otherwise both run for one event.
5. **Modifiers on `keydown`/`keyup`.** Today the payload is `event.key` only.
   Shift-to-swap while dragging and Escape-to-cancel need the modifiers (see
   also the [draft on key events that reach the document](https://github.com/thebrandonlucas/roc-issues/tree/master/roc-signals/RS-004-document-key-events)).
6. **Animated DOM updates.** A request such as `ViewTransition(Str)` that makes
   the runtime apply the next command batch inside
   `document.startViewTransition`, or directly where the browser lacks it. Apps
   can already set `view-transition-name` through a style attribute.
7. **Spec steps** `pointer-down`, `pointer-move` and `pointer-up` (with an
   element-relative position), in both the native runner and Chrome, so drag
   behaviour can be specified like everything else. Pointer input is excluded
   from the spec language today.
8. **Non-bubbling events.** `pointerenter`/`pointerleave` and
   `mouseenter`/`mouseleave` never reach the root's bubbling listener. Either
   document `pointerover`/`pointerout` as the way, or map them as the runtime
   already does for focus and blur.

Optional, for text dragged in from outside the page: HTML drag and drop
payloads (`dataTransfer.types` on `dragenter`/`dragover`, the text on `drop`)
and a `dragover` prevent decided from an attribute already rendered, since the
engine cannot decide during the event. Files are covered since 0.4.0: a
`drop:files` handler receives them and makes the runtime prevent `dragover` on
its element.

The [draft on layout measurement](https://github.com/thebrandonlucas/roc-issues/tree/master/roc-signals/RS-005-layout-measurement) asks for element measurement and pointer coordinates for other reasons
(popups, scroll position, swipes). Item 1 covers its pointer coordinates; a
`Measure(ref)` request would still serve FLIP-style animation where view
transitions don't fit.

## Current workaround

None that keeps the interaction. [liton](https://github.com/thebrandonlucas/liton)
moves panes with ← and → buttons and resizes columns with narrower and wider
buttons (`ui/Liton.roc`). Replace them with dragging once the platform
delivers pointer positions and capture.
