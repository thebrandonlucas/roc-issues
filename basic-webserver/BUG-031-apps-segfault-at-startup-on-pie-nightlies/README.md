# Every basic-webserver 0.21.0 app segfaults at startup when built with Roc nightly-2026-11-11-7679cc5 or later

> **Rechecked 2026-11-13:** still reproduces on `nightly-2026-11-12-ce942d6` (`repro.sh` prints BUG REPRODUCED); `nightly-2026-11-10-f7d1f19` runs the app.

Found with Roc `nightly-2026-11-11-7679cc5` and
[basic-webserver](https://github.com/roc-lang/basic-webserver) `0.21.0`;
this directory's `flake.nix` pins `nightly-2026-11-12-ce942d6`, the newest
nightly it was checked on. This is a platform issue: it goes to
roc-lang/basic-webserver.

## Description

`main.roc` is the smallest basic-webserver 0.21.0 app: `init!` only returns
a listen address. `roc build main.roc --output=app` succeeds, and `./app`
then dies with SIGSEGV (exit status 139) before printing anything.

Since `nightly-2026-11-11-7679cc5`, which contains
[roc-lang/roc#12949](https://github.com/roc-lang/roc/pull/12949), `roc build`
links native executables as PIE: the binary is a `static-pie` ELF, where
`nightly-2026-11-10-f7d1f19` produced an ordinary static one. That PR's notes
for platform authors ask static musl platforms to replace `crt1.o` with the
self-relocating `rcrt1.o`, and Rust hosts to be built with
`-C relocation-model=pic`. basic-webserver 0.21.0's `main.roc` lists
`crt1.o` as the first input of both `x64musl` and `arm64musl`.

## Expected behavior

The app starts and prints `Listening on <http://127.0.0.1:18979>`, as it
does when built with `nightly-2026-11-10-f7d1f19`.

## Actual behavior

```text
$ roc build main.roc --output=app
0 errors and 0 warnings found in 801ms while successfully building:

    app
$ ./app
Segmentation fault (core dumped)
$ echo $?
139
```

## Reproduction

```sh
nix develop . --command bash repro.sh
```

The harness builds `main.roc` in a temporary `HOME` (it downloads the
platform), runs the app for at most 10 seconds, and accepts only a SIGSEGV
before `Listening on` as the bug. It leaves nothing behind. To see the app
start on the last good nightly:

```sh
nix develop .#last-good --command bash repro.sh   # prints BUG NOT REPRODUCED
```

## Shell with the exact compiler

This directory pins Roc `nightly-2026-11-12-ce942d6` from
[roc-overlay](https://github.com/roc-lang/roc-overlay) revision
`67491987eb6ef2423d9a6e5901f6a8e439d8566c`:

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-11-12-ce942d6
```

`nix develop .#last-good` gives `nightly-2026-11-10-f7d1f19`, the last
nightly that runs the app.

## Observations

- Regression: runs on `nightly-2026-11-10-f7d1f19`; segfaults on
  `nightly-2026-11-11-7679cc5` and `nightly-2026-11-12-ce942d6` (linux
  x86_64).
- In a local copy of the 0.21.0 platform, replacing `crt1.o` with musl
  1.2.6's `rcrt1.o` in `x64musl`'s inputs, with `libhost.a`,
  `libunwind.a` and `libc.a` unchanged, makes the app start and listen on
  `nightly-2026-11-12-ce942d6`. The bundled `libc.a` is musl 1.2.4.
- `readelf -r` finds no `R_X86_64_32`/`R_X86_64_32S` relocations outside
  debug sections in the x64musl `libhost.a` or `libc.a`.
- `arm64musl` also lists `crt1.o`; it was not run.
- [roc-signals](https://github.com/lukewilliamboswell/roc-signals) (a Roc
  platform for browser apps) `0.5.0` lists `rcrt1.o` for its `x64musl`
  target.

## Related

- [roc-lang/basic-webserver#264](https://github.com/roc-lang/basic-webserver/pull/264),
  the automated bump of basic-webserver's nightly pin to
  `nightly-2026-11-12-ce942d6`, changes `.roc-version`, the examples and
  the generated glue, not the musl startup inputs.
