# A condition on a local closure's result is warned about as known at compile time

> **Archived 2026-11-12:** fixed in `nightly-2026-09-28-9927ba8` before it was filed; `nightly-2026-09-27-a3ce7f1` is the last nightly that warns.

Found with Roc `nightly-2026-09-26-d6267b4`. No platform is needed.

## Description

A local closure that calls a top-level function with a captured argument,
and an `if` on its result:

```roc
kind : Doc -> Str
kind = |doc| {
	get = |key| field(doc, key)
	given = get("type")
	if given.is_empty() { "post" } else { given }
}
```

`roc check main.roc` warns:

```
── ● unconditional condition ─────────────────────────────────── Lookup.roc:15:6

This if condition is known at compile time, so this conditional will always
make the same choice.

if given.is_empty() { "post" } else { given }
   ^^^^^^^^^^^^^^^^
```

The condition depends on `doc`, and both `expect`s in `Lookup.roc` (one for
each branch) pass, so only the warning is wrong. Calling
`field(doc, "type")` directly gives no warning.

It matters to a build that treats warnings as failures: a static site
generator whose site program is Roc refused to build with three such
warnings.

## Files

`main.roc` (the package) and `Lookup.roc`, in this directory. `repro.sh`
runs `roc check` with the `roc` on `PATH`.
