app [main!] { cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst" }

main! = |_args| {
	_ = List.map_try([""], label)?
	Ok({})
}

label = |line| {
	unit : { label : Str }
	unit = Json.parse(line)?
	Ok(unit.label)
}
