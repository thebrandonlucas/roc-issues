Later := [].{
	Message := [Text(Str)].{
		parser_for = |encoding| {
			parse_fields = Fields.parser_for(encoding)
			|state| {
				parsed = parse_fields(state)?
				Ok({ value: Text(parsed.value.message), rest: parsed.rest })
			}
		}
	}

	Fields := { message : Str }.{
		parser_for : _
	}
}

expect {
	decoded : Try(Later.Message, _)
	decoded = Json.parse("{\"message\":\"x\"}")
	decoded.is_ok()
}
