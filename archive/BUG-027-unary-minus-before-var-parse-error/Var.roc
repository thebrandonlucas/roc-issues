negated : I64 -> I64
negated = |start| {
	var $n = start
	$n = -$n
	$n
}

main! = |_| Ok({})
