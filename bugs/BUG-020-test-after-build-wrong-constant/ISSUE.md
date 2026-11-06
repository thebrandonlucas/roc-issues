# `roc test` fails an expect because rows parsed into a top-level constant hold garbage strings

A top-level constant is computed by parsing a few lines of text into a record with a list of rows. An `expect` over it fails: the list has the right number of rows, but every row's string fields are the single byte `0xFF`. The comment line in the input is parsed correctly. This happens on every run, with or without a cache.

**Nightly:** `nightly-2026-11-03-34bd006` (linux x86_64)

### Repro

`pkg/main.roc`:

```roc
package [Steps] {}
```

`pkg/Steps.roc`:

```roc
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
```

<details>
<summary><code>pkg/Conllu.roc</code> (53 lines: the parser)</summary>

```roc
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
```

</details>

### Command

```
roc test pkg/main.roc
```

### Observed

```
── ✗ fail ─────────────────────────────────────────────────── pkg/Steps.roc:15:1

expect sentence.rows.map(|r| r.id) == ["1", "2", "3"]
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    0 passed
    1 failed
    0 compiler errors
```

Adding `dbg sentence.rows.map(|r| r.id)` prints three strings that are each the byte `0xFF`; `dbg sentence.comments` prints `["# sent_id = 1"]`.

### Expected

The test passes, as on `nightly-2026-10-21-5349569`.

### Notes

- Without the comment line (`# sent_id = 1\n`) at the start of the text, the test passes.
- `--no-cache` makes no difference.
- Regression: passes on `nightly-2026-10-21-5349569`; fails on `nightly-2026-10-25-72704da` and every nightly since (`2026-10-22` to `2026-10-24` not tested). On `nightly-2026-10-21-5349569` the same test already failed when run after `roc build` of an app that imports the package.
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/BUG-020-test-after-build-wrong-constant

---
*Drafted with Claude (Claude Code) and checked by me on `nightly-2026-11-03-34bd006` before posting.*
