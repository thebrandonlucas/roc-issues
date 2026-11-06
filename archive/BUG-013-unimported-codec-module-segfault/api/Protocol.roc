# kai's one question to a compiled Kaifile and its answer, as S-expressions.
import Layout
import Plan
import Sexpr

Protocol := [].{
	Version : { major : U64, minor : U64 }

	current : Version
	current = { major: 1, minor: 0 }

	## `argv` is kai's argv without argv[0].
	Request := {
		protocol : Version,
		argv : List(Str),
		style : [Color, Plain],
		host : { system : Str },
		layout : Layout,
		lock : [Absent, Present(Str)],
		resume : [
			Fresh,
			Resume(
				{
					command : Str,
					backend : Str,
					phase : U64,
					observed : List({ path : Str, contents : [Missing, Text(Str)] }),
				},
			),
		],
	}.{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	## Every response names its protocol and platform release (`platform` on
	## the wire), so kai can refuse before decoding `body`.
	Response := { protocol : Version, platform_ : Str, body : Body }.{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	## `Candidates` holds one option per backend implementing `command`, in
	## preference order; exactly one when answering a `Resume`.
	Body := [
		Help(Str),
		Usage(Str),
		Describe(Manifest),
		Candidates(
			{
				command : Str,
				plugin : Str,
				choice : [Auto, Only(Str)],

				## `OwnsLock` lets the chosen plan publish the lock.
				lock : [ReadsLock, OwnsLock],
				options : List(Candidate),
			},
		),
		Refused(Str),
	].{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	## `backend` is "" for an implementation that needs none.
	Candidate : {
		backend : Str,
		plugin : Str,
		probes : List(
			{ program : Str, flag : [DoubleDashVersion, DashV, VersionWord] },
		),
		outcome : [Unfit(Str), Planned(Plan), Failed(Str)],
	}

	## Placeholder until the Kaifile's validated description is designed.
	Manifest := {
		plugins : List({ name : Str, version : Str }),
		commands : List(Str),
		backends : List(Str),
	}.{
		is_eq : _

		encoder_for : _

		parser_for : _
	}

	## Refuses another major or a newer minor before decoding the rest.
	decode_response :
		Str ->
			Try(
				Response,
				[InvalidSexpr(Str), MissingRequiredField(Str), Incompatible(Version)],
			)
	decode_response = |text| {
		header : { protocol : Version }
		header = Sexpr.parse(text)?
		version = header.protocol
		if version.major != current.major or version.minor > current.minor {
			return Err(Incompatible(version))
		}
		Sexpr.parse(text)
	}
}
