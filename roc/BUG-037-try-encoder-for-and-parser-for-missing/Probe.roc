Probe := [].{
	Outcome(ok, err) := [Ok(ok), Err(err)].{
		encoder_for : _
	}

	mine : Outcome(Str, Str)
	mine = Ok("x")

	theirs : Try(Str, Str)
	theirs = Ok("x")
}

expect Json.to_str(Probe.mine) == "{\"Ok\":\"x\"}"
expect Json.to_str(Probe.theirs) == "{\"Ok\":\"x\"}"
