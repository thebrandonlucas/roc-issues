platform ""
	requires {
		main : Str
	}
	exposes []
	packages {}
	provides { "roc_main": main_for_host }

main_for_host : {} -> Str
main_for_host = |{}| main
