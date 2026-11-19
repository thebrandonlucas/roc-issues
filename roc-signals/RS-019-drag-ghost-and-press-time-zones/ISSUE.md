# Let a drag show what it carries under the pointer, and find its target in the layout it started from

**roc-signals:** `0.6.0` (unchanged in `0.7.0-rc1`) · **Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

A pointer drag gets zones and fractions (`on_pointer_capture`,
`on_pointer_paced`, `Prop.pointer_zone`), which keep the drop target pure
Roc and testable natively. Two things a drag with a live preview needs are
still out of reach:

1. **Nothing can follow the pointer.** No pixel position reaches Roc, by
   design (lukewilliamboswell/roc-signals#211), so an app cannot move a
   ghost of the dragged card or tab with the pointer, and the platform does
   not do it either.
2. **The target is hit-tested in the layout as it is now.** Each event runs
   `elementFromPoint` against the current page. When the app previews the
   drop by rearranging the zones (a pane moved into a split, a card opening
   a gap in a list), the next move is hit-tested against the preview: the
   pointer is now over the zone the preview put there, the target changes,
   the preview reverts, and the target flips back. Near a boundary this
   repeats on every move.

### What it takes today

```roc
# A pane is a zone; the board previews the drop from `drag.target`, which
# is computed from the zone under the pointer, which the preview moves.
Engine.element(
	"section",
	[
		Html.zone_s(pane.map(|p| p.id)),
		Html.on_pointer_move_paced(model.set_value(|state, pointer| Drag.retarget(state, pointer.at))),
	],
	[...],
)
```

For (1), a port whose host listens to `pointermove` itself and sets a
`transform` on the ghost element. For (2), either the same port, hit-testing
against element boxes it took at the press, or a transparent overlay of
zones drawn from the layout as it was before the drag, kept above the
preview for the whole drag.

### Proposed

Both keep pixels out of Roc, so the native runner needs no layout:

1. A follow property, for example `Prop.follow_pointer : Prop(Bool)` (or an
   option on `on_pointer_capture`): while the pointer that pressed it is
   captured, the runtime translates the element by the pointer's offset
   from the press with a `transform`, at the frame, and clears it at up or
   cancel. The native runner can ignore it, as it ignores view transitions.
2. A press-time hit test: an option on `on_pointer_capture` (for example
   `{ zones: AtPress }`) under which every move and the release of that
   pointer are hit-tested against the zone boxes measured at the press,
   rather than against the current layout. `at` keeps its meaning, the
   nearest zone and fractions of its box, only in the layout the drag began
   in.

## Related

- lukewilliamboswell/roc-signals#211, which added zones and fractions and
  declines pixels in Roc and a drag ghost.
