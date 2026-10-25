platform ""
	requires {
		main : Str
	}
	exposes []
	packages {}
	provides { "roc_main": main_for_host }
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["libhost.a", app] },
		arm64musl: { inputs: ["libhost.a", app] },
	}

main_for_host : Str
main_for_host = main
