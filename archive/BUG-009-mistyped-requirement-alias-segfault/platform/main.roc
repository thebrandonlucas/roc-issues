platform ""
	requires {
		main : P
	}
	exposes [P]
	packages {}
	provides { "roc_main": main_for_host }

import P

main_for_host : Str
main_for_host = P.name(main)
