# A second `roc check` crashes when the cache has an app's canonicalization entries but not its module entries

> **Archived 2026-11-13:** no longer applies: on `nightly-2026-11-12-ce942d6` the cache has no `compat-*/mod` directory, so the state this needs can't arise; both checks pass. Never filed.

Found with Roc `nightly-2026-10-21-5349569`, which this directory's `flake.nix`
pins, where it still reproduces (`roc check` exits 139).

## Description

An app with a top-level value of a recursive nominal tag union is checked
once. When the cache then still holds that check's canonicalization entries
(`can/`) but not its module entries (`mod/`), a second `roc check` of the same
app segfaults instead of rebuilding what is missing.

## Reproduce

From this directory (`App.roc` and `platform/main.roc` are the whole app):

```sh
nix develop . --command bash repro.sh
```

`repro.sh` checks the app with an empty cache, removes the module entries,
checks again, and reports `BUG REPRODUCED` only if that second check crashes.
