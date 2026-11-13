negated : I64 -> I64
negated = |start| {
	n = start
	-n
}

negated_var : I64 -> I64
negated_var = |start| {
	var $n = start
	$n = -($n)
	$n
}

main! = |_| Ok({})
