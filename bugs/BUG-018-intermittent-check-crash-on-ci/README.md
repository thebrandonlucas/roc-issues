# BUG-018: intermittent SIGSEGV/SIGABRT in `roc check` on CI runners

Found with Roc `nightly-2026-10-21-5349569`, which this repro's shell pins.
Observed on CI only, not reproduced locally. The programs are the roots of
[Kai](https://github.com/thebrandonlucas/kai) at commit `3fd862f`.

## Description

Kai's CI runs `zig build`, which starts about 30 `roc check` processes in
parallel, one for each Kaifile and package root. On GitHub-hosted
`ubuntu-24.04` runners (4 vCPU, 16 GB), several runs on 2026-10-24 had
`roc check` crash, each time on different, unrelated files. Reruns of the
same commit passed.

One crash was a SIGABRT (`roc check plugins/std/main.roc`); the others were
SIGSEGV (exit 139). One run crashed on 5 files at once:

- `examples/agenix/Kaifile.roc`
- `devtool/fixtures/overlays/Kaifile.roc`
- `plugins/std/main.roc`
- `examples/plugins/deploy/main.roc`
- `examples/path-source/Kaifile.roc`

## Expected behavior

Every `roc check` succeeds, as it does on reruns of the same commit.

## Actual behavior

Some `roc check` processes crash, with a report such as:

```text
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x7fffe0250000

Work in progress on thread 3877 (main), outermost first:
  post-check    lir_gen

Reproduce with:
  .../roc-nightly-2026-10-21-5349569/bin/roc check examples/agenix/Kaifile.roc

Stack trace:
Cannot print stack trace: stack tracing is disabled
```

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-10-21-5349569`,
pinned by this repro's `flake.nix` (Linux), which also provides Zig 0.16 for
Kai's platform host:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-10-21-5349569
```

Inside that shell, from a checkout of Kai at
`3fd862f28fc86e0ac0daca6a48bbf6d6f71960d3`, build the platform host and run
the checks in parallel, as CI does:

```sh
(cd platform && zig build --release)
for root in $(git ls-files '*Kaifile.roc' 'plugins/*/main.roc' \
    'examples/plugins/*/main.roc' cli/main.roc | grep -v /fuzz/); do
  roc check "$root" &
done
wait
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh       # 10 rounds
nix develop . --command bash repro.sh 50    # 50 rounds
```

This is a best-effort harness. It fetches Kai's source tree at the pinned
commit into a temporary directory, builds its platform host, then runs
`roc check` on every root in parallel for the given number of rounds, each
round with an empty Roc cache. It needs network access for Kai's source, the
host's link inputs and basic-cli. It reports success only when a `roc check`
process dies by signal or prints the compiler's crash report; otherwise it
reports that the bug was not reproduced in that many rounds.

## Observations

- **CI only:** not reproduced on an 8-core x86_64 Linux host, by 20 sequential
  runs, 20 runs each with `--jobs 4` and `--jobs 2`, 18 parallel runs
  (6 files, 3 rounds) with an empty `XDG_CACHE_HOME`, and runs with stack
  limits down to 1 MiB with 1 or 2 workers.
- **Not memory exhaustion:** each check uses about 0.5 GB of resident memory,
  well within the runners' 16 GB for the processes that run at once.
- **Not file-specific:** each failing run crashed on different files, and
  reruns of the same commit passed; the crash report names the `lir_gen`
  phase after checking.
- **Harness:** on the 8-core host above, the harness runs end to end (27
  roots, 3 rounds, every check succeeding) and reports that the bug was not
  reproduced; that is the expected result there.

## Upstream status

Not reported upstream yet.
