# Let an app animate elements to where an update puts them without holding the page's rendering

**roc-signals:** `0.6.0` (unchanged in `0.7.0-rc1`) · **Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

`ViewTransition(types)` is the only way to animate what a turn changes, and
it works as the browser's view transitions do: the batch is applied in the
`update` callback at the next rendering opportunity, the page's rendering is
held from the snapshot until then, and a marked batch that arrives while
another transition runs ends the running one at its final state. That suits
a navigation or an added row. It does not suit an update that comes on every
few pointer moves, such as a drag previewing where the dragged item will
land:

- each preview is drawn a frame or more late, and events raised in the gap
  wait behind it;
- each new preview cuts the running animation to its end, so elements jump
  instead of turning towards the new place;
- the whole page is captured and cross-faded, where only a few elements
  moved.

### What it takes today

```roc
# The preview is drawn from `drag.target`; each change of it is animated.
Engine.watch_changes(
	drag.signal().map(|d| d.target),
	|_| [Engine.command(ViewTransition(["drag-preview"]))],
	Engine.ignore({}),
)
```

To avoid the hold, an app drops `ViewTransition` and, through a port, has
its host measure the elements before the update, let it apply, and animate
each from its old box to its new one with the Web Animations API
(`element.animate` of a `transform`), cancelling a running animation and
starting from where it is shown.

### Proposed

A command beside `ViewTransition`, for example `AnimateMoves(List(Str))`
naming element refs (or a class of elements marked with a property), under
which the runtime applies the batch at once, as an unmarked one, and then
animates each named element that moved or resized from where it was shown
(mid-animation included) to its new box with a transform on the compositor,
fading in one that is new. It holds no rendering, retargets rather than
skips, and honours `prefers-reduced-motion`. No pixels reach Roc, and the
native runner can treat it as it treats `ViewTransition`: the DOM it
leaves is the same.

## Related

- lukewilliamboswell/roc-signals#215, which added `ViewTransition` and
  documents the hold and the one-transition-per-document rule.
