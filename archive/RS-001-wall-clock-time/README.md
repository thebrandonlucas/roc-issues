# Let an app read the wall-clock time

> **Archived 2026-11-12:** filed as [lukewilliamboswell/roc-signals#200](https://github.com/lukewilliamboswell/roc-signals/issues/200) (posted with the `0.3.0` text, whose workaround predates ports).

> **Rechecked 2026-11-12:** still missing in roc-signals `0.5.0` (`Engine.Boot` has no time; no request answers one).

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` (first found on `0.3.0` with Roc `nightly-2026-11-07-ad3a5d2`).

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

Since `0.4.0`, a port: a `Port.call` whose JavaScript, passed to
`mountRocEngineApp` in its `ports` option, answers `Date.now()`. The app asks
for the time before scheduling a rating and schedules it when the answer
arrives; an `Interval(15000)` asks again so "due now" and the intervals shown
follow the clock. Specs answer the calls with the `answer-port` step.

It costs a round trip and an awaited request each time, and every app that
needs the time writes the same port. On `0.3.0`, before ports, the same
answers came back through a custom element that added `Date.now()` to every
answer it sent. Remove the workaround once the platform offers the time.
