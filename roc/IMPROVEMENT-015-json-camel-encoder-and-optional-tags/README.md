# Json: a camelCase encoder to match `parser_camel`, and a hint for optional-field tags

Two gaps in the builtin `Json` codec:

1. `Json.parser_camel()` reads camelCase keys into snake_case record fields,
   but there is no encoder that does the reverse: `Json.to_str` writes field
   names as they are. A record sent to a camelCase API needs camelCase field
   names in Roc.
2. A record field that may be absent parses as `Try(a, [Missing])` (and one
   that may be `null` as `Try(a, [Null])`); any other tag name, such as
   `Try(a, [Absent])`, has no `parser_for`, and the error does not say which
   tags are accepted.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### Repro

`Camel.roc`:

```roc
Camel := {}

expect {
	parsed : Try({ agent_id : Str }, _)
	parsed = Json.parser_camel()("{\"agentId\":\"a1\"}")
	dbg parsed
	dbg Json.to_str({ agent_id: "a1" })
	Bool.True
}
```

`Absent.roc`:

```roc
Absent := {}

expect {
	parsed : Try({ name : Str, title : Try(Str, [Absent]) }, _)
	parsed = Json.parse("{\"name\":\"x\"}")
	parsed.is_ok()
}
```

### Command

```
roc test Camel.roc
roc test Absent.roc
```

### Observed

```
All (1) tests passed in 93.8 ms.
[dbg] Ok({ agent_id: "a1" })
[dbg] "{\"agent_id\":\"a1\"}"
```

```
── ✗ missing method ──────────────────────────────────────────── Absent.roc:5:11

A where clause requires the parser_for method here, but the type being used
doesn't have that method.

parsed = Json.parse("{\"name\":\"x\"}")
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The value's type, which does not have a method named parser_for, is:

    { name: Str, title: Try(Str, [Absent]) }
```

### Proposed

1. A camelCase encoder, `Json.to_str_camel` or an encoder counterpart to
   `parser_camel`, writing `{"agentId":"a1"}` for `{ agent_id: "a1" }`.
2. When a record field's `Try` error row has no `parser_for`, a hint naming
   the forms that work: `Try(a, [Missing])` for an absent field, `Try(a, [Null])`
   for `null`, `Try(Try(a, [Null]), [Missing])` for both.

### Notes

- With `[Missing]` in place of `[Absent]`, `Absent.roc` parses to
  `Ok({ name: "x", title: Err(Missing) })`.
