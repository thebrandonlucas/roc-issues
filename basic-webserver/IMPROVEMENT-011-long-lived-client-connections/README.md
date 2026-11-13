# Let a server keep a client connection open across requests and replace it when it drops

A basic-webserver app can open a connection to another service (a WebSocket
API, say) only while handling a request. `Tcp.Connection` can be kept in the
app's context, but the context is immutable: a connection opened in `init!`
cannot be replaced once the other side restarts or drops it, and no other
host-owned slot can hold a new one (`Server.Readiness` holds only a fixed
state). There is also no background work, so nothing reads what the other
service pushes between requests.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), basic-webserver `0.21.0`

So an app must open a connection, and often a session on the other service,
for each request that needs it; with every client polling, that load
multiplies. It cannot hear what the service pushes as it happens, and it
cannot reconnect after the service restarts without restarting itself.

### Proposed

Any one of these would do, from least to most platform work:

- **A replaceable host-owned cell** (for example `Shared.new(value)`,
  `Shared.get!`, `Shared.replace!(cell, old, new)` with compare-and-swap),
  safe to keep in context like `Sqlite.Db`, so a handler can swap in a new
  connection when the old one fails.
- **A host-owned client connection pool** for TCP (or WebSocket) streams
  keyed by host and port, which reopens a dropped connection on next use,
  like `Sqlite.Db`'s pool.
- **Background tasks**: a handler registered in `init!` that the host runs
  on its own, for example to read a kept stream and store what arrives,
  bounded as handlers are today.

A WebSocket client in the platform would make reconnecting and framing
simpler still, but apps can already frame WebSocket messages on `Tcp`.
