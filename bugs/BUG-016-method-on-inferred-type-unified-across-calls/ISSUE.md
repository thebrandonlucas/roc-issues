# Two calls of one method on a value with an inferred type are checked as one, merging their types

In an unannotated function, calling `keep_oks` twice on the same inferred `List`, once keeping one tag's payload and once another's, gives both calls a single type. The two lambdas' types are merged (`[Count(U64), Name(U64)]`, one payload type for both tags), so `split` comes out as returning `(List(Str), List(Str))` and `roc check` rejects a correct program.

**Nightly:** `nightly-2026-11-09-9e85de7` (linux x86_64)

### Repro

`Main.roc`:

```roc
Main := [].{}

Arg := [Name(Str), Count(U64)]

split = |command| {
	names = command.args.keep_oks(
		|arg|
			match arg {
				Name(name) => Ok(name)
				_ => Err({})
			},
	)
	counts = command.args.keep_oks(
		|arg|
			match arg {
				Count(count) => Ok(count)
				_ => Err({})
			},
	)
	(names, counts)
}

args : List(Arg)
args = [Name("a"), Count(2)]

parts : (List(Str), List(U64))
parts = split({ args: args })
```

### Command

```
roc check Main.roc
```

### Observed

```
── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:27:9

This expression is used in an unexpected way.

parts = split({ args: args })
        ^^^^^^^^^^^^^^^^^^^^^

It has the type:

    (List(Str), List(Str))

But the annotation says it should be:

    (List(Str), List(U64))

── ✗ type mismatch ─────────────────────────────────────────────── Main.roc:27:9

The keep_oks method on List has an incompatible type.

parts = split({ args: args })
        ^^^^^^^^^^^^^^^^^^^^^

The method keep_oks has the type:

    List(Arg), (Arg -> Try(after, _err)) -> List(after)

But I need it to have the type:

    List(Arg), ([Count(U64), Name(U64)] -> [Err({}), Ok(U64), ..]) -> List(Str)

This use needs that because of this code in the definition it uses:

counts = command.args.keep_oks(
    |arg|
        match arg {
            Count(count) => Ok(count)
            _ => Err({})
        },
)

── 2 errors and 0 warnings ──────────────────────────────────────────── Main.roc
```

### Expected

No errors: `split` returns `(List(Str), List(U64))`, here `(["a"], [2])`.

### Notes

- Annotating `split : { args : List(Arg) } -> (List(Str), List(U64))` makes it check, so the receiver's type has to be inferred.
- The function form, `List.keep_oks(command.args, ...)`, checks.
- Regression: `nightly-2026-09-26-d6267b4` compiled this shape; `nightly-2026-10-21-5349569` and every nightly since, through `nightly-2026-11-09-9e85de7`, reject it.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-016-method-on-inferred-type-unified-across-calls

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-09-9e85de7` before posting.*
