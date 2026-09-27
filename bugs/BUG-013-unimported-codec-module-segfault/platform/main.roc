platform ""
	requires {
		main : Str -> Str
	}
	exposes []
	packages {}
	provides { "roc_main": main_for_host }

main_for_host : Str -> Str
main_for_host = |text| main(text)
