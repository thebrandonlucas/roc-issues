app [main] { pf: platform "./platform/main.roc" }

Tree := [Many(List(Tree)), Leaf(Str), One({ value : Tree })]

example : Tree
example = Many([Leaf("abc")])

main = "hi"
