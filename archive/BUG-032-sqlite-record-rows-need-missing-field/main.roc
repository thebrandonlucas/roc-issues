app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.21.0/4viZsnWjdYsyH4Q87ESFAwM5c55Hnc15nAGW1UwzWpFU.tar.zst",
}

import pf.Path
import pf.Server
import pf.Sqlite

Context : { db : Sqlite.Db }

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64)])
init! = || {
	db = Sqlite.open!(Sqlite.default_config(Path.utf8("repro.db"))) ? |_| Exit(2)
	rows : List({ name : Str })
	rows = Sqlite.query_many!({ db, query: "SELECT 'a' AS name;", params: {}, limits: Sqlite.default_query_limits }) ? |_| Exit(3)
	if rows.is_empty() Err(Exit(4)) else Ok({ config: Server.default_config, context: { db } })
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |_request, _context| Err(ServerErr("unused"))
