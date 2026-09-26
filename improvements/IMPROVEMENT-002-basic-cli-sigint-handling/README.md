# IMPROVEMENT-002: Let basic-cli apps handle SIGINT (Ctrl-C)

This is a platform capability gap, not a compiler bug. basic-cli exposes no way
to install a signal handler or observe SIGINT, so a long-running app cannot
print a summary or save state when the user presses Ctrl-C: the default
disposition terminates the process immediately. Checked against basic-cli
`0.22.2` and `0.23.0-rc1` (no `Signal` module; the only related issues are
[#476](https://github.com/roc-lang/basic-cli/issues/476), about SIGPIPE, and
[#442](https://github.com/roc-lang/basic-cli/issues/442), about TTY raw mode).

Found on `nightly-2026-09-19-d025939` with basic-cli `0.22.2`.

## Proposed improvement

Add a minimal API, for example `Signal.interrupted! : () => Bool` backed by a
host-side flag set by a SIGINT handler, or a `Signal.on_interrupt!` hook, so an
app can finish or abandon its current step, report, and exit cleanly.

## Current workaround

Start the Roc app with SIGINT ignored and run its interruptible work in child
processes that restore the default disposition:

```text
env --ignore-signal=INT roc app.roc
  └─ Cmd: env --default-signal=INT <child command>
```

Ctrl-C then kills only the children. The parent observes the child's
`FailedToGetExitCode(... Other("Process was killed by signal"))` error, treats
it as a cancellation, prints its summary, and exits. Remove the workaround once
basic-cli can observe SIGINT directly.

Used by: Aristos generation loop (`scripts/generate/loop.roc`).
