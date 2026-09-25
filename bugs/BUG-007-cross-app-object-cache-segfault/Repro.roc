# Calls Lib.parse. Building this app after Primer.roc reuses Primer's pack.
app [main!] { pf: platform "./.basic-cli/main.roc" }

import Lib

main! = |_args| {
	_ = Lib.parse("https://example.com") ? InvalidUrl
	Ok({})
}
