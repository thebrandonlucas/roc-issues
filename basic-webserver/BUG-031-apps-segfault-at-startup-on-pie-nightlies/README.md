# Every basic-webserver 0.21.0 app segfaults at startup when built with Roc nightly-2026-11-11-7679cc5 or later

Any basic-webserver 0.21.0 app builds without errors with `roc build`, then
dies with SIGSEGV (exit status 139) before it prints anything. It should
start and listen, as it does when built with `nightly-2026-11-10-f7d1f19`.

**Nightly:** `nightly-2026-11-13-03dce41` (linux x86_64), basic-webserver `0.21.0`

The issue to file, with the repro inline, is [`ISSUE.md`](./ISSUE.md).

### Repro

`main.roc` in this directory, the smallest 0.21.0 app: `init!` only
returns a listen address.

### Command

```
roc build main.roc --output=app
./app
```

### Observed

```
$ roc build main.roc --output=app
── ● duplicate definition ─ .../Attribute.roc:14:24
...
0 errors and 10 warnings found in 5.9s while successfully building:

    app
$ ./app
Segmentation fault (core dumped)
$ echo $?
139
```

### Expected

```
Listening on <http://127.0.0.1:18979>
```

### Notes

- 0.21.0 lists `crt1.o` for `x64musl` and `arm64musl`; replacing it with
  `rcrt1.o` in a local copy of the platform makes the app start and listen.
- The 10 warnings, duplicate definitions in the platform's `Attribute.roc`,
  `Server.roc` and `Sqlite.roc`, are new in `nightly-2026-11-13-03dce41`
  (they make `roc build` exit with status 2); the app segfaulted the same
  way before they appeared.
- Regression: works on `nightly-2026-11-10-f7d1f19`, fails since
  `nightly-2026-11-11-7679cc5`.

### Harness

From this directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/basic-webserver/BUG-031-apps-segfault-at-startup-on-pie-nightlies),
with the nightly above from the repo's root flake and the last good one
from this directory's `flake.nix`:

```sh
nix develop ../..#latest --command bash repro.sh   # BUG REPRODUCED
nix develop .#last-good --command bash repro.sh    # BUG NOT REPRODUCED
```

The script builds `main.roc` in a temporary `HOME`, runs the app for at
most 10 seconds, and accepts only a SIGSEGV before `Listening on` as the
bug.
