# `roc check` segfaults in lambda_solve on nested recursive effects whose inner one returns a computed tuple

> **Archived 2026-11-16:** fixed before it was filed. basic-cli 0.26.0 no longer compiles on `nightly-2026-11-14-a87808d` and later; the same program on basic-cli 0.28.1, `main-basic-cli-0.28.1.roc`, segfaults the same way on `nightly-2026-10-21-5349569` and checks with no errors on `nightly-2026-11-14-a87808d` and `nightly-2026-11-15-f25da45`.

Found with Roc `nightly-2026-10-21-5349569` (linux x86_64) and basic-cli 0.26.0, the release that compiles on it.

## Description

`main.roc` has two recursive effectful functions. The inner one,
`read_headers!`, reads lines from a `Tcp` connection it is passed and
returns `Ok((count, seen))`, where its recursive call computes
`seen or line.starts_with("x")`. The outer one, `serve!`, calls a function
that destructures that tuple with `?`, then calls itself:

```roc
read_headers! = |conn, count, seen| {
	line = conn.read_line!()?
	if line.is_empty() {
		Ok((count, seen))
	} else {
		read_headers!(conn, count + 1, seen or line.starts_with("x"))
	}
}

serve_one! = |listener, total| {
	conn = listener.accept!({ accept_timeout: NoTimeout, io_timeout: Duration.seconds(30) })?
	(count, _seen) = read_headers!(conn, 0, Bool.False)?
	Stdout.line!("${U64.to_str(count)} lines")?
	Ok(total + count)
}

serve! = |listener, total| {
	next = match serve_one!(listener, total) {
		Ok(updated) => updated
		Err(_) => total
	}
	serve!(listener, next)
}
```

`roc check main.roc` crashes:

```
Segmentation fault (SIGSEGV) in the Roc compiler.
Fault address: 0x0

Work in progress on thread ... (main), outermost first:
  post-check    lambda_solve
```

It should report no errors.

## Observations

Each of these makes the crash go away on `nightly-2026-10-21-5349569`:

- `serve!` loops with `while` instead of calling itself, or `main!` calls
  `serve_one!` once.
- The recursive call passes `seen` unchanged instead of
  `seen or line.starts_with("x")`.
- `read_headers!` returns only `count`, not a tuple.
- The same shape reads `Stdin.line!()` instead of a `Tcp` connection's
  `read_line!`.

## Reproduction

From this bug's directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/archive/BUG-038-recursive-effect-tuple-lambda-solve-segfault),
with that nightly's `roc` first on `PATH`:

```sh
bash repro.sh
```

It prints `BUG REPRODUCED` when `roc check` segfaults in lambda_solve.

## Related

- roc-lang/roc#12899, a different program that panicked in lambda_solve,
  closed 2026-11-12; whether its fix is the one that fixed this is not
  checked.
