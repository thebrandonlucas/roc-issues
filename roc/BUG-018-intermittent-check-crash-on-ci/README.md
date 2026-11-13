# Intermittent SIGSEGV/SIGABRT in `roc check` on CI runners

Run in parallel on about 30 roots on a GitHub-hosted `ubuntu-24.04` runner
(4 vCPU, 16 GB), `roc check` sometimes dies by SIGSEGV or SIGABRT, on
different files each time; a rerun of the same commit passes. Every check
should succeed.

**Nightly:** `nightly-2026-10-21-5349569` (linux x86_64)

### Repro

The package and app roots of
[thebrandonlucas/kai](https://github.com/thebrandonlucas/kai) at commit
`3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3`, checked in parallel on a fresh
runner, with Zig 0.16 for the platform host:

```sh
git clone https://github.com/thebrandonlucas/kai && cd kai
git checkout 3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3
(cd platform && zig build --release)
for root in $(git ls-files '*Kaifile.roc' 'plugins/*/main.roc' \
    'examples/plugins/*/main.roc' cli/main.roc | grep -v /fuzz/); do
  roc check "$root" &
done
wait
```

### Observed

Some checks crash, up to 5 in one run; one was a SIGABRT, the others
SIGSEGV (exit 139):

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7fffe0250000

Work in progress on thread 3877 (main), outermost first:
  post-check    lir_gen

Reproduce with:
  .../roc-nightly-2026-10-21-5349569/bin/roc check examples/agenix/Kaifile.roc

Stack trace:
Cannot print stack trace: stack tracing is disabled
```

### Expected

Every `roc check` succeeds, as on a rerun.

### Notes

- Not reproduced on an 8-core x86_64 Linux host: sequential runs, runs
  with `--jobs 4` and `--jobs 2`, parallel runs with an empty cache, and
  stack limits down to 1 MiB all pass. Each check uses about 0.5 GB.
- A reproduction script, with the compiler pinned by Nix (`nix develop .
  --command bash repro.sh [ROUNDS]`; it reports success only on a crash):
  [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/BUG-018-intermittent-check-crash-on-ci)
