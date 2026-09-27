# What a command asks kai to do: steps kai validates as a whole, then runs.
import Sexpr

## Steps run in order and the first failure stops the plan. `next` asks kai
## to read back files and run the Kaifile again (`Resume`).
Plan := { steps : List(Step), next : Next }.{
	is_eq : _

	encoder_for : _

	parser_for : _

	## The executor vocabulary; kai checks every step before the first runs.
	Step := [
		Note(Str),
		Print(Str),
		Stage(Str),
		Confirm(Str),
		Write(List(File)),
		VerifyPath({ path : Str, argv : List(Str), stdout : Str }),

		## A local source a backend will read: no symlinks or special files.
		CheckSource(Str),
		Snapshot({ root : Str, destination : Str, exclude : List(Str) }),
		InstallRunner({ destination : Str }),
		Run({ what : Str, argv : List(Str), output : [Inherit, Artifact(Artifact)] }),
		PublishLock({ previous : [Absent, Present(Str)], contents : Str }),
	].{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	Next := [Done, Observe(List(Str))].{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	File : { path : Str, contents : Str }

	## `output` is the declared output name; the store path is the child's
	## last stdout line (`nix build --print-out-paths`, `guix build`).
	Artifact : { name : Str, label : Str, output : Str }
}
