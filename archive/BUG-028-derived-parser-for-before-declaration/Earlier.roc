Earlier := [].{
	Fields := { message : Str }.{
		parser_for : _
	}

	Message := [Text(Str)].{
		parser_for = |encoding| {
			parse_fields = Fields.parser_for(encoding)
			|state| {
				parsed = parse_fields(state)?
				Ok({ value: Text(parsed.value.message), rest: parsed.rest })
			}
		}
	}
}

expect {
	decoded : Try(Earlier.Message, _)
	decoded = Json.parse("{\"message\":\"x\"}")
	decoded.is_ok()
}
