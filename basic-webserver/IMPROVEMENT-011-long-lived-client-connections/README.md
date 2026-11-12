# Let a server keep a client connection open across requests and replace it when it drops

This is a platform capability gap in [basic-webserver](https://github.com/roc-lang/basic-webserver),
not a compiler bug. Checked on basic-webserver `0.21.0` with Roc
`nightly-2026-11-07-ad3a5d2`.

A server that talks to another service over a long-lived connection, such as
a WebSocket API, can only open a connection while handling a request and must
close it before answering. `Tcp.Connection` is safe to retain in the
application's context, but the context is immutable: a connection opened in
`init!` cannot be replaced once the other side restarts or drops it, and there
is no other host-owned slot an app can swap a value into (`Server.Readiness`
holds only a fixed state). There is also no background work, so nothing reads
what the other service pushes between requests.

A daemon that fronts an agent service uses it to:

- hold one WebSocket to the service and send every request over it, instead of
  a handshake and a fresh session on the service for each sync. Opening one
  per request multiplies with every client tab and poll, and once kept the
  other service near full CPU until it was rate-limited;
- receive what the service pushes (timeline events, file-diff and status
  updates) as it happens, rather than polling for it;
- reconnect after the service restarts, without restarting the server.

## Proposed improvement

Any one of these would do, from least to most platform work:

- **A replaceable host-owned cell** (for example `Shared.new(value)`,
  `Shared.get!`, `Shared.replace!(cell, old, new)` with compare-and-swap),
  safe to retain in context like `Sqlite.Db`, so a handler can swap in a new
  connection when the old one fails.
- **A host-owned client connection pool** for TCP (or WebSocket) streams keyed
  by host and port, which reopens a dropped connection on next use, like
  `Sqlite.Db`'s pool.
- **Background tasks**: a handler registered in `init!` that the host runs on
  its own, for example to read a retained stream and store what arrives,
  bounded like Roc handlers are today.

A WebSocket client in the platform would make the reconnect and framing
simpler still, but apps can already frame WebSocket messages on `Tcp`.

## Current workaround

[liton](https://github.com/thebrandonlucas/liton) opens one connection per
request that needs the service, shares it across every call due in that
request, and asks the service at most every 3 seconds per session, answering
other polls from what it stored (`daemon/main.roc`). Remove the per-request
connection once a connection can live across requests.
