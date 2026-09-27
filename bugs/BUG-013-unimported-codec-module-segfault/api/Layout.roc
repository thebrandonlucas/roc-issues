# Caller-owned paths. Planning validates them without observing the filesystem.
import Sexpr

Layout := {
	project_root : Str,
	workspace : Str,
	generated_root : Str,
	lock_path : Str,
}.{
	is_eq : _

	encoder_for : _

	parser_for : _
}
