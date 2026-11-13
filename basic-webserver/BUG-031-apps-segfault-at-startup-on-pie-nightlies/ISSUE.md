# Every 0.21.0 app segfaults at startup when built with Roc nightly-2026-11-11-7679cc5 or later

Any app on basic-webserver 0.21.0 builds without errors with `roc build` on `nightly-2026-11-11-7679cc5` or later, then dies with SIGSEGV before `init!` runs. Since that nightly, which contains roc-lang/roc#12949, `roc build` links a static-pie executable, and that PR asks static musl platforms to ship the self-relocating `rcrt1.o` in place of `crt1.o`. 0.21.0's `main.roc` lists `crt1.o` for `x64musl` and `arm64musl`. The app should start and listen, as it does when built with `nightly-2026-11-10-f7d1f19`.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### Repro

`main.roc`:

```roc
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.21.0/4viZsnWjdYsyH4Q87ESFAwM5c55Hnc15nAGW1UwzWpFU.tar.zst",
}

import pf.Server

Context : {}

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64)])
init! = || Ok({ config: Server.default_config.with_listen({ host: "127.0.0.1", port: 18979 }), context: {} })

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |_request, _context| Err(ServerErr("unused"))
```

### Command

```
roc build main.roc --output=app
./app
```

### Observed

```
$ roc build main.roc --output=app
0 errors and 0 warnings found in 801ms while successfully building:

    app
$ ./app
Segmentation fault (core dumped)
```

The exit status is 139. `file app` reports `ELF 64-bit LSB pie executable, x86-64, ... static-pie linked`; with `nightly-2026-11-10-f7d1f19` it reports `ELF 64-bit LSB executable, x86-64, ... statically linked`.

### Expected

```
Listening on <http://127.0.0.1:18979>
```

as with `nightly-2026-11-10-f7d1f19`.

### Notes

- In a local copy of the 0.21.0 platform, listing musl 1.2.6's `rcrt1.o` in place of `crt1.o` in `x64musl`'s inputs, with `libhost.a`, `libunwind.a` and `libc.a` unchanged, makes the app start and listen on `nightly-2026-11-12-ce942d6`. The bundled `libc.a` is musl 1.2.4, so the matching `rcrt1.o` is that version's.
- `readelf -r` finds no `R_X86_64_32`/`R_X86_64_32S` relocations outside debug sections in the x64musl `libhost.a`. roc-lang/roc#12949 also asks Rust hosts to be built with `-C relocation-model=pic`.
- `arm64musl` lists `crt1.o` too; I haven't run it. [roc-signals](https://github.com/lukewilliamboswell/roc-signals) (a Roc platform for browser apps) 0.5.0 lists `rcrt1.o` for `x64musl`.
- Regression: works on `nightly-2026-11-10-f7d1f19`, fails since `nightly-2026-11-11-7679cc5`.
- Related: #264, the automated bump of the nightly pin to `nightly-2026-11-12-ce942d6`, changes `.roc-version`, the examples and the generated glue, not the musl startup inputs.
- A reproduction script, with the compiler pinned by Nix: [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/basic-webserver/BUG-031-apps-segfault-at-startup-on-pie-nightlies)

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-12-ce942d6` before posting.*
