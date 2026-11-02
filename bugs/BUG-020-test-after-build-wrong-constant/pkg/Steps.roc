import Conllu

Steps :: [].{
	size : Str -> U64
	size = |text| text.count_utf8_bytes()
}

first_sentence = |text| match Conllu.parse(text) {
	Ok([s, ..]) => s
	_ => { line: 0, comments: [], rows: [] }
}

sentence = first_sentence("# sent_id = 1\n1\ta\ta\tc\t_\t_\t0\tx\t_\tt_1\n2\tb\tb\tc\t_\t_\t1\tx\t_\tt_2\n3\tc\tc\tc\t_\t_\t1\tx\t_\tt_3\n\n")

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
