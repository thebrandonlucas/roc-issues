app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0-rc4/FvCh4vdqm3nBY6DWEfZ8RuGCVfjuMY43HA8KSNk9qVDn.tar.zst",
    kai: "./package.roc",
    custom0: "./custom0/main.roc",
    custom1: "./custom1/main.roc",
}

import pf.Stdout
import custom0.Plugin as Custom0
import custom1.Plugin as Custom1

registry = [
    Custom0.plugin,
    Custom1.plugin,
]

main! = |_args| {
    Stdout.line!("plugins: ${U64.to_str(registry.len())}")?
    Ok({})
}
