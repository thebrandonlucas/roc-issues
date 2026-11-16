Color := [Red, Green].{
	name : Color -> Str
	name = |color|
		match color {
			Red => "red"
			Green => "green"
		}

	plain : [Red, Green]
	plain = Color.Red
}

expect Color.plain.name() == "red"
