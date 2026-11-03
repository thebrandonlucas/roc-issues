Main := [].{
	tool : Str -> Try(Str, [Failed(Str)])
	tool = |purpose| Ok(purpose)

	served : Str -> Try(Str, _)
	served = |name| Err(Failed("${name}: ${name}"))

	realise : Str -> Try(Str, _)
	realise = |name| {
		_ = Main.served(name)?
		Main.tool(name)?
		Ok(name)
	}
}
