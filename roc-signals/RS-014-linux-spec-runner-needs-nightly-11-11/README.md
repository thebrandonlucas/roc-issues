# The 0.5.0 Linux spec runner segfaults when built with the nightly the release pins

This is a defect in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps). Checked on roc-signals `0.5.0`, x86-64 Linux.

roc-signals 0.5.0 pins `nightly-2026-11-10-f7d1f19` as its stable compiler
(`Blueprint.roc`'s `roc_stable_program`, `scripts/build_platform.roc`), and the
release notes say it was built and tested with `nightly-2026-11-11-7679cc5`.
A native spec runner (`--target=x64musl`) built against the released platform
bundle with `nightly-2026-11-10-f7d1f19` segfaults at startup, before reading
any spec, with any arguments or none. The same build with
`nightly-2026-11-11-7679cc5` (`--opt=dev`, as `signals.roc test` builds it) runs
every spec. The likely cause is the PIC/PIE link change in that nightly
([roc-lang/roc#12949](https://github.com/roc-lang/roc/pull/12949)): the bundle's
Linux host is built for it.

## Reproduce

With the release's own example:

```sh
curl -LO https://github.com/lukewilliamboswell/roc-signals/releases/download/0.5.0/roc-signals-examples-0.5.0.zip
# or: git archive 0.5.0 examples/status-page examples/shared | tar -x
cd examples/status-page
sed -i 's|pf: platform "../../platform/main.roc"|pf: platform "https://github.com/lukewilliamboswell/roc-signals/releases/download/0.5.0/2SYUPo9uKFPJDvTyXiwsLEqHvmq7UMgaY4hdgMiSsSEF.tar.zst"|' main.roc
roc build --target=x64musl --opt=dev main.roc --output=specs-runner   # nightly-2026-11-10-f7d1f19
./specs-runner specs/*.scm      # Segmentation fault (core dumped), exit 139
```

With `nightly-2026-11-11-7679cc5` the same steps report
`specs: 19 passed, 0 failed, 0 error`. The default (`--opt=speed`) build with
`nightly-2026-11-10-f7d1f19` segfaults the same way; with
`nightly-2026-11-11-7679cc5` it does not build at all (`spec_constr`,
[roc-lang/roc#12976](https://github.com/roc-lang/roc/issues/12976)).

## Expected

Either a runner built with the pinned stable nightly works, or the release
states the minimum compiler for native specs (and ideally the compiler refuses
to link a host built for a newer link model instead of producing a binary that
crashes).

## Current workaround

Build the spec runner with `nightly-2026-11-11-7679cc5` and `--opt=dev`. Used
by [Lyceum Study](https://github.com/lyceum-quest/study) (`Kaifile.roc`,
`scripts/signals.roc`).
