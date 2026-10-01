app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst" }
import cli.Stdout
main! = |_args| {
	a : Try({ c : Dec }, _)
	a = Json.parse("{\"c\":0.011101999999999999}")
	b : Try({ c : Dec }, _)
	b = Json.parse("{\"c\":0.0007735999999999999}")
	Stdout.line!("18 places: ${Str.inspect(a)}\n19 places: ${Str.inspect(b)}\nDec.from_str: ${Str.inspect(Dec.from_str("0.0007735999999999999"))}")
}
