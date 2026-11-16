Parse := {}

expect {
	parsed : Try(Try(Str, Str), _)
	parsed = Json.parse("{\"Ok\":\"x\"}")
	parsed == Ok(Ok("x"))
}
