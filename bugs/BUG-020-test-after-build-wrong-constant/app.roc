app [main!] {
	pkg: "./pkg/main.roc",
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
}

import pf.Stdout
import pkg.Steps

main! = |_args| {
	Stdout.line!(Steps.size("ab").to_str())?
	Ok({})
}
