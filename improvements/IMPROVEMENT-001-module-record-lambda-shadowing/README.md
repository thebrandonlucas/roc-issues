# IMPROVEMENT-001: Exempt lambda parameters from module-field shadowing warnings

This is an ergonomics idea, not a compiler bug. Roc permits lexical shadowing,
but a lambda parameter that shares a name with a field in the same module-style
record produces a `DUPLICATE DEFINITION` warning:

```roc
Shadow := [].{
    x = 0
    f = |x| x
}
```

`Shadow.f(7)` evaluates to `7`: the parameter shadows the field correctly.
However, `roc check Shadow.roc` reports one warning and exits with status 2.
That behavior was unchanged through `nightly-2026-08-31-86e69b4` and matches
Roc's general policy for shadowing constants.

The proposed improvement is to omit this warning for lambda parameters, whose
local scope makes the intent unambiguous. Until then, use a more specific
parameter name.
