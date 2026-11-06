# Two calls of one method on a value with an inferred type are checked as one, merging their types

In an unannotated function, calling `keep_oks` twice on the same inferred `List`, once keeping one tag's payload and once another's, gives both calls a single type. The two lambdas' result types are merged (`[Count(U64), Name(U64)]`, one payload type for both tags), and `roc check` reports a mismatch at the call site instead of accepting the code.

**Nightly:** `nightly-2026-11-03-34bd006` (linux x86_64)

### Repro

`main.roc`:

```roc
app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst" }

import cli.Stdout

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

main! = |_args| {
	args : List(Arg)
	args = [Name("a"), Count(2)]
	Stdout.line!(Str.inspect(split({ args: args })))
}
```

### Command

```
roc check main.roc
```

### Observed

```
── ✗ type mismatch ────────────────────────────────────────────── main.roc:30:27

The keep_oks method on List has an incompatible type.

Stdout.line!(Str.inspect(split({ args: args })))
                         ^^^^^^^^^^^^^^^^^^^^^

The method keep_oks has the type:

    List(Arg), (Arg -> Try(after, _err)) -> List(after)

But I need it to have the type:

    List(Arg), ([Count(U64), Name(U64)] -> [Err({}), Ok(U64), ..]) -> _ret

This use needs that because of this code in the definition it uses:

counts = command.args.keep_oks(
    |arg|
        match arg {
            Count(count) => Ok(count)
            _ => Err({})
        },
)

── 1 error and 0 warnings ───────────────────────────────────────────── main.roc
```

### Expected

No errors; running it prints `(["a"], [2])`.

### Notes

- Annotating `split : { args : List(Arg) } -> (List(Str), List(U64))` makes it compile, so the receiver's type has to be inferred.
- The function form, `List.keep_oks(command.args, ...)`, compiles.
- Annotating the two results instead reports that a type "would need two different, incompatible keep_oks methods".
- Regression: `nightly-2026-09-26-d6267b4` compiled this shape; `nightly-2026-10-21-5349569` and every nightly since fail.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-016-method-on-inferred-type-unified-across-calls

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-03-34bd006` before posting.*
