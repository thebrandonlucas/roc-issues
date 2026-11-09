Conllu :: [].{
	Row : { id : Str, form : Str, lemma : Str, upos : Str, xpos : Str, feats : Str, head : Str, deprel : Str, deps : Str, misc : Str }

	Sentence : { line : U64, comments : List(Str), rows : List(Row) }

	parse : Str -> Try(List(Sentence), { line : U64, message : Str })
	parse = |text| {
		var $out = []
		for block in blocks(text) {
			var $comments = []
			var $rows = []
			var $n = block.line
			for line in block.lines {
				if line.starts_with("#") {
					$comments = $comments.append(line)
				} else {
					match line.split_on("\t") {
						[id, form, lemma, upos, xpos, feats, head, deprel, deps, misc] => {
							$rows = $rows.append({ id, form, lemma, upos, xpos, feats, head, deprel, deps, misc })
						}
						columns => return Err({ line: $n, message: "expected 10 tab-separated columns, found ${columns.len().to_str()}" })
					}
				}
				$n = $n + 1
			}
			$out = $out.append({ line: block.line, comments: $comments, rows: $rows })
		}
		Ok($out)
	}

	blocks : Str -> List({ line : U64, lines : List(Str) })
	blocks = |text| {
		var $out = []
		var $current = []
		var $start = 1
		var $n = 1
		for line in text.replace_each("\r\n", "\n").split_on("\n") {
			if line.trim() == "" {
				if !$current.is_empty() {
					$out = $out.append({ line: $start, lines: $current })
					$current = []
				}
			} else {
				if $current.is_empty() {
					$start = $n
				}
				$current = $current.append(line)
			}
			$n = $n + 1
		}
		if ($current.is_empty()) $out else $out.append({ line: $start, lines: $current })
	}
}
