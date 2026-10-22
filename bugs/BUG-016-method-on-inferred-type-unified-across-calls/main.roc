app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst" }

import cli.Stdout

Arg := [Name(Str), Count(U64)]

# Unannotated, so the type of `command.args` is inferred: two keep_oks calls
# on it, keeping different payload types, get one type between them.
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
