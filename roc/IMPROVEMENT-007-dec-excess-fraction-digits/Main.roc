Main := [].{}

# 18 fraction digits: decodes.
expect {
	parsed : Try({ c : Dec }, _)
	parsed = Json.parse("{\"c\":0.011101999999999999}")
	parsed.is_ok()
}

# 19 fraction digits.
expect {
	parsed : Try({ c : Dec }, _)
	parsed = Json.parse("{\"c\":0.0007735999999999999}")
	dbg parsed
	parsed.is_ok()
}

expect {
	d = Dec.from_str("0.0007735999999999999")
	dbg d
	d.is_ok()
}
