# Scroll to the top, or to a fragment, after navigating in place

> **Archived 2026-11-13:** not filed: [lukewilliamboswell/roc-signals#213](https://github.com/lukewilliamboswell/roc-signals/issues/213) adds `ScrollTo` and `ScrollIntoView` requests, which an app issues after navigating in place.

> **Checked 2026-11-12:** roc-signals `0.5.0` has no scroll request; the
> workaround below works there.

A comment for [roc-signals#204](https://github.com/lukewilliamboswell/roc-signals/issues/204)
(measurement and scrolling, filed from this repository): an app that moves
between pages with `Push` needs to start the new page at its top, or at the
element its `#fragment` names, as a page load does. The comment is in
`COMMENT.md`.

Found porting [blu.cx](https://github.com/thebrandonlucas/blu) (a personal
site and blog) to roc-signals `0.5.0` with Roc `nightly-2026-11-11-7679cc5`.
