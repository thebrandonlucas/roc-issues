# Let an app bind Cmd on macOS and Ctrl elsewhere

**roc-signals:** `0.6.0` · **Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

`Chord.primary(chord)` is `[chord.with_ctrl(), chord.with_meta()]` on every
system, and an app cannot tell which system it runs on: `Boot` has the URL,
storage, connectivity, media queries, time, seed, languages and time zone,
but not the operating system. So a shortcut such as Cmd+B on macOS also
hears, and prevents, Ctrl+B there. In a macOS text field Ctrl+B moves the
caret back a character and Ctrl+E to the end of the line, so binding
`primary` takes those keys from the user.

### What it takes today

```roc
Engine.on_document_key(
	{ keymap: Engine.const(Engine.Keymap.prevent(Engine.Chord.plain("b").primary())) },
	handler,
)
```

To bind only one of the two, the app must learn the system from a port
whose host reads `navigator.platform`, with a keymap that changes when the
answer arrives after the first render. `Keymap.outside_text` keeps Ctrl+B
in text fields, but then Cmd+B does not work in them either.

### Proposed

Either:

- A `primary` that gives one chord, Meta on macOS (and iOS) and Ctrl
  elsewhere, as browsers' own shortcuts and Playwright's `ControlOrMeta` do,
  with the spec runners told which system to model (a setup step such as
  `(primary-modifier meta)`); or
- The system in `Boot` (for example `primary_modifier : [Ctrl, Meta]`), so
  the app picks the chord itself.
