# Imports Lib without using it. Building this app writes Lib's object pack.
app [main!] { pf: platform "./.basic-cli/main.roc" }

import Lib

main! = |_args| Ok({})
