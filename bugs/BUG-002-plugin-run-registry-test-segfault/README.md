# BUG-002: `roc test` aborts in LIR lowering through the plugin union registry path

Found with Roc `release-fast-c9147c28`.

## Description

`roc test` crashes the compiler while compiling `plugin-tests.roc`. The crash
needs **both** of these `expect` blocks in the same file — each one passes on
its own:

1. Wrapping a registry definition in the `Plugin` tag union
   (`Plugin.Registry(...)`), then dispatching on the union via
   `Plugin.definition`:

   ```roc
   plugin = PluginApi.Plugin.Registry({ definition, select_config })
   PluginApi.definition(plugin)
   ```

2. Planning through a registry whose `Definition` lists **two
   implementations with distinct renderer closures**:

   ```roc
   PluginApi.plan_registry([registry_definition], config_text, args, LINUX, X64)
   ```

Depending on the exact file contents, the failure presents as either a
SIGSEGV (observed fault addresses `0x333100000079`, `0x91`, `0x48`, `0xc5`)
or a SIGABRT from a guarded-list invariant in LIR lowering:

```text
thread <id> panic: guarded list invalidated: LirStore.cf_switch_branches: span start=588 len=70 exceeds current_len=474
```

`roc check` and `roc build` on the same file succeed; only `roc test`
crashes. The crash is not cache-dependent.

## Reproduction

From this directory (with the repo's dev shell active):

```sh
./repro.sh
```

or manually:

```sh
roc test plugin-tests.roc   # crashes the compiler
roc check plugin-tests.roc  # succeeds
roc build plugin-tests.roc  # succeeds
```

## Layout

- `plugin-tests.roc` — minimal test file (the two `expect` blocks above plus
  the fixtures they need)
- `package.roc`, `Plugin.roc`, `parser/` — the `kai` support package defining
  the `Plugin` union and `plan_registry`

## Notes

- The original context was `xkai-bin/plugin-tests.roc` calling the standard
  planner through the transitional plugin union:
  `PluginApi.run(StdPlugin.plugin, config_text, ["shell"], os, arch)`.
- Workaround used downstream: call `PluginApi.plan_registry` directly instead
  of dispatching through the `Plugin` union.
