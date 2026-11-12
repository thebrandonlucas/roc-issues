Lookup := [].{
	Doc : { meta : List({ key : Str, value : Str }) }

	field : Doc, Str -> Str
	field = |doc, key|
		match doc.meta.find_first(|f| f.key == key) {
			Ok(f) => f.value
			Err(_) => ""
		}

	kind : Doc -> Str
	kind = |doc| {
		get = |key| field(doc, key)
		given = get("type")
		if given.is_empty() { "post" } else { given }
	}

	expect kind({ meta: [{ key: "type", value: "article" }] }) == "article"
	expect kind({ meta: [] }) == "post"
}
