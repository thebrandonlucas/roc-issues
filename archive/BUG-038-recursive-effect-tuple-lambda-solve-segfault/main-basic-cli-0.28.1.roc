app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.28.1/7brgwR8YUqfeGrkdfF1V4GPPN7DnP7ftqub9KcrTEZtr.tar.zst",
}

import pf.Duration
import pf.Stdout
import pf.Tcp

read_headers! = |conn, count, seen| {
	line = conn.read_line!()?
	if line.is_empty() {
		Ok((count, seen))
	} else {
		read_headers!(conn, count + 1, seen or line.starts_with("x"))
	}
}

serve_one! = |listener, total| {
	conn = listener.accept!({ accept_timeout: NoTimeout, io_timeout: Duration.seconds(30) })?
	(count, _seen) = read_headers!(conn, 0, Bool.False)?
	Stdout.line!("${U64.to_str(count)} lines")?
	Ok(total + count)
}

serve! = |listener, total| {
	next = match serve_one!(listener, total) {
		Ok(updated) => updated
		Err(_) => total
	}
	serve!(listener, next)
}

main! = |_args| {
	listener = Tcp.listen!("127.0.0.1", 8091, Duration.seconds(5))?
	serve!(listener, 0)
}
