# Let `Dec.from_str` and JSON decoding accept more than 18 fraction digits

> **Rechecked 2026-11-12:** on nightly-2026-11-12-ce942d6, `Json.parse` into a `Dec` field and `Dec.from_str` still reject `0.0007735999999999999` (checked with `roc test` and no platform). `repro.sh` no longer gets that far: its basic-cli 0.22.2 platform fails to compile on that nightly.

This is a design question, not a compiler bug: Roc treats a decimal with more
than 18 fraction digits as not fitting in `Dec`, everywhere. The compiler
rejects such a literal, `Dec.from_str` returns `Err(BadNumStr)`, and
`Json.parse` fails the whole document with `InvalidJson("Invalid JSON")`.

That last case hurts in practice. Numbers printed from a float often have 19
or more fraction digits: [Claude Code](https://claude.com/claude-code) (a
coding agent CLI) writes `total_cost_usd` values like `0.0007735999999999999`
in its `--output-format json`. A record decoder with a `Dec` field for that
output succeeds on some runs and fails on others, and the error names neither
the field nor the reason.

## Proposed improvement

Either or both:

- When parsing text (`Dec.from_str`, JSON decoding into `Dec`), round a
  decimal with more than 18 fraction digits to 18 instead of rejecting it,
  e.g. `0.0007735999999999999` to `0.000773600000000000`.
- Make the JSON error say which field failed and why (too many fraction
  digits for `Dec`), instead of `InvalidJson("Invalid JSON")`.

## Current workaround

Decode the field as `F64` (or `Str`) and convert it afterwards.

## Zulip post (#ideas)

> **Rounding extra fraction digits when parsing `Dec`**
>
> `Dec` holds 18 fraction digits, and anything longer is rejected: as a
> literal ("does not fit in the inferred type"), by `Dec.from_str`
> (`Err(BadNumStr)`), and by JSON decoding, which fails the whole document
> with `InvalidJson("Invalid JSON")`:
>
> ```roc
> Main := [].{}
>
> # 18 fraction digits: decodes.
> expect {
> 	parsed : Try({ c : Dec }, _)
> 	parsed = Json.parse("{\"c\":0.011101999999999999}")
> 	parsed.is_ok()
> }
>
> # 19 fraction digits: Err(InvalidJson("Invalid JSON")).
> expect {
> 	parsed : Try({ c : Dec }, _)
> 	parsed = Json.parse("{\"c\":0.0007735999999999999}")
> 	parsed.is_ok()
> }
>
> # Err(BadNumStr).
> expect Dec.from_str("0.0007735999999999999").is_ok()
> ```
>
> For literals the error makes sense: the author can fix the source. For
> parsed input it's harder, because float-formatted numbers routinely have
> 17 significant digits, so a JSON field like `0.0007735999999999999` makes
> an otherwise valid document undecodable, and the error doesn't say which
> field or why. Would it make sense for `Dec.from_str` and JSON decoding to
> round to 18 fraction digits, or at least for the JSON error to name the
> field? Today's workaround is decoding as `F64` and converting.
>
> (Checked on `nightly-2026-11-09-9e85de7`.)

## Reproduction

From this directory in
[roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/roc/IMPROVEMENT-007-dec-excess-fraction-digits),
`nix develop . --command bash repro.sh` runs `main.roc` on the nightly it was
found with (`nightly-2026-09-19-d025939`, pinned by `flake.nix`), with
basic-cli 0.22.2 for printing:

```text
18 places: Ok({ c: 0.011101999999999999 })
19 places: Err(InvalidJson("Invalid JSON"))
Dec.from_str: Err(BadNumStr)
```

The `expect`s in the Zulip post need no platform; run them with
`roc test Main.roc`. On `nightly-2026-11-09-9e85de7`, 1 passes and 2 fail.

## Related

- [roc-lang/roc#10550](https://github.com/roc-lang/roc/issues/10550)
  (closed): another `Dec.from_str` `Err(BadNumStr)` case, exponential
  notation such as `"2e5"`.
- [roc-lang/roc#12098](https://github.com/roc-lang/roc/issues/12098)
  (closed): Dec JSON exponent arithmetic now saturates instead of
  overflowing, another edge case of decoding JSON numbers into `Dec`.
