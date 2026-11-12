# A derived `parser_for` does not exist when used before its type's declaration

Found with Roc `nightly-2026-11-07-ad3a5d2` (pinned by this directory's
`flake.nix`). No platform is needed.

## Description

`Later.roc` declares, inside one type module, a nominal `Message` whose custom
`parser_for` calls the derived parser of a sibling nominal `Fields`
(`Fields := { message : Str }.{ parser_for : _ }`), declared after it.
`roc check` on a package exporting it (`package [Later] {}`) reports:

```text
── ✗ does not exist ───────────────────────────────── Later.roc:4:19

Fields.parser_for does not exist.

parse_fields = Fields.parser_for(encoding)
               ^^^^^^^^^^^^^^^^^

Fields is in scope, but it has no associated parser_for.
```

`Earlier.roc` is the same code with `Fields` declared first; it checks and its
test passes. Moving `Fields` to the module's top level, after the type, fails
the same way.

## Expected behavior

Declaration order does not matter: `Later.roc` checks like `Earlier.roc`.

## Reproduction

```sh
nix develop . --command bash repro.sh
```

## Observations

- Found writing a JSON value parser that falls back to an object's fields.
  Workaround there: declare the fields type first.
