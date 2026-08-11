app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0-rc4/FvCh4vdqm3nBY6DWEfZ8RuGCVfjuMY43HA8KSNk9qVDn.tar.zst",
    kai: "./package.roc",
    parser: "./parser/main.roc",
}

import parser.Body
import kai.Plugin as PluginApi

Fixtures := [].{
    empty_renderer : PluginApi.Renderer
    empty_renderer = |_|
        Ok(PluginApi.RenderResult.{ outputs: [], requested_packages: [] })

    backend : Str, PluginApi.DeterminateSystemKind, [NoDriver, Program(Str)], Str, List(PluginApi.Package) -> PluginApi.Backend
    backend = |name, kind, driver, package_source, required_packages|
        PluginApi.Backend.{
            determinate_system: PluginApi.DeterminateSystem.{
                default_package_source: package_source,
                driver,
                kind,
            },
            fallback: NoFallback,
            name,
            required_packages,
        }

    nix = Fixtures.backend("nix", Nix, Program("nix"), "nixpkgs", [])

    guix = Fixtures.backend("guix", Guix, Program("guix"), "guix", [])

    command : PluginApi.Command
    command = PluginApi.Command.{
        argument_policy: AllowArguments,
        body: Body.object([]),
        config_block: OptionalConfigBlock("example-config"),
        default_backend: nix.name,
        name: "example",
    }

    implementation : Str, PluginApi.Renderer -> PluginApi.Implementation
    implementation = |backend_name, renderer|
        PluginApi.Implementation.{
            actions: [],
            backend: backend_name,
            command: command.name,
            renderer,
        }

    definition : PluginApi.Definition
    definition = PluginApi.Definition.{
        backends: [nix, guix],
        commands: [command],
        implementations: [
            Fixtures.implementation(nix.name, Fixtures.empty_renderer),
            Fixtures.implementation(guix.name, |_| Ok(PluginApi.RenderResult.{ outputs: [], requested_packages: [] })),
        ],
        name: "minimal",
    }

    select_missing : PluginApi.ConfigSelector
    select_missing = |_, _, _, _, _| Ok(Missing)

    registry_command : PluginApi.Command
    registry_command = PluginApi.Command.{
        argument_policy: NoArguments,
        body: Body.object([Body.required("value", String)]),
        config_block: RequiredConfigBlock("fixture"),
        default_backend: nix.name,
        name: "registry-command",
    }

    registry_renderer : PluginApi.Renderer
    registry_renderer = |_| Ok(PluginApi.RenderResult.{ outputs: [], requested_packages: [] })

    registry_definition : Str, PluginApi.Command, PluginApi.Renderer -> PluginApi.RegistryDefinition
    registry_definition = |name, selected_command, renderer| {
        make_implementation = |backend_name| PluginApi.Implementation.{
            actions: [],
            backend: backend_name,
            command: selected_command.name,
            renderer,
        }
        {
            definition: PluginApi.Definition.{
                backends: [nix, guix],
                commands: [selected_command],
                implementations: [make_implementation(nix.name), make_implementation(guix.name)],
                name,
            },
            select_config: Fixtures.select_missing,
        }
    }

    plan_registry : List(PluginApi.RegistryDefinition), Str, List(Str) -> Try(PluginApi.Plan, PluginApi.Error)
    plan_registry = |registry, config, args| PluginApi.plan_registry(registry, config, args, LINUX, X64)
}

main! = |_| Ok({})

expect {
    plugin = PluginApi.Plugin.Registry({ definition: Fixtures.definition, select_config: Fixtures.select_missing })
    definition = PluginApi.definition(plugin)
    definition.name == "minimal"
}

expect {
    first = Fixtures.registry_definition("first", Fixtures.registry_command, Fixtures.registry_renderer)
    second = Fixtures.registry_definition("second", Fixtures.registry_command, Fixtures.registry_renderer)
    match Fixtures.plan_registry(
        [first, second],
        "",
        [Fixtures.registry_command.name],
    ) {
        Ok(plan) => plan.plugin == "first" and plan.backend == Fixtures.nix
        _ => Bool.False
    }
}
