# `roc build` segfaults in lir_gen on an empty cache when the platform provides a value, not a function

A platform that hands the app's `main` to the host as a value (`main_for_host : Str`) makes `roc build` segfault in the `lir_gen` stage, before linking, when the cache is empty. `roc check` passes on the same app.

**Nightly:** `nightly-2026-11-06-34f137a` (linux x86_64)

### Repro

`platform/main.roc`:

```roc
platform ""
	requires {
		main : Str
	}
	exposes []
	packages {}
	provides { "roc_main": main_for_host }
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["libhost.a", app] },
		arm64musl: { inputs: ["libhost.a", app] },
	}

main_for_host : Str
main_for_host = main
```

`App.roc`:

```roc
app [main] { pf: platform "./platform/main.roc" }

main = "hi"
```

`platform/targets/x64musl/libhost.a` is an empty archive (`printf '!<arch>\n' > platform/targets/x64musl/libhost.a`). The crash happens before linking.

### Command

With an empty cache:

```
XDG_CACHE_HOME=$(mktemp -d) roc build App.roc
```

### Observed

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x0

Work in progress on thread 1713426 (main), outermost first:
  post-check    lir_gen
```

The exit status is 139.

### Expected

The app compiles, as it does on `nightly-2026-10-21-5349569`.

### Notes

- `main : U64` with `main = 42` crashes the same way.
- A function entry point, `main_for_host : {} -> Str` with `main_for_host = |{}| main`, builds.
- Running `roc check App.roc` first with the same cache makes the following `roc build` succeed; only a build with an empty cache crashes.
- A bundled platform fetched by URL crashes the same way as the local path.
- Regression: builds on `nightly-2026-10-21-5349569`, segfaults since `nightly-2026-10-23-18478ff`.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-019-cold-build-value-entrypoint-segfault

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-06-34f137a` before posting.*
