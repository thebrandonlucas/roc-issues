# Let an app read the wall-clock time

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`.

An app cannot learn what time it is. `Engine.Boot` carries the URL, the
declared local-storage values, connectivity, visibility and storage
availability; `Timer` and `Interval` answer `Fired`; `Self` answers `Now`,
which carries no value; no other request returns a time. design.md lists
"sampled time, if an app needs wall-clock values rather than timer ticks"
among its target effects.

A spaced-repetition review screen needs it twice: to schedule a card (its due
time is the review time plus an interval, in milliseconds since the epoch) and
to decide which cards are due now, which changes while the page stays open.

## Proposed improvement

- The time at mount in `Boot` (milliseconds since the epoch), and
- a request that answers with the current time (for example `Clock` answering
  `Time(I64)`), or a timestamp on `Fired`, so an `Interval` keeps a clock.

For specs: a setup form such as `(initial-time N)` and a step such as
`(set-time N)`, so specs stay deterministic in both runners.

## Current workaround

The page already needs a custom element as a storage bridge (see the
asynchronous storage draft in this folder), so that element adds `Date.now()`
to every answer it sends back. The app takes its clock from those answers:

- a rating first issues a storage read and is scheduled when the answer
  arrives, at the answer's time;
- an `Interval(15000)` issues a cheap storage read so "due now" and the
  intervals shown follow the clock.

Specs supply the time inside the faked storage answers. Remove the workaround
once the platform offers the time.
