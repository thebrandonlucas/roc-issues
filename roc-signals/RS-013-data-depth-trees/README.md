# Let a view draw a tree whose depth comes from data

> **Rechecked 2026-11-12:** still the case in roc-signals `0.5.0`: the repro below fails `roc check` with the same error on `nightly-2026-11-11-7679cc5` (the release's compiler) and `nightly-2026-11-12-ce942d6`.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Checked on roc-signals
`0.5.0` with Roc `nightly-2026-11-11-7679cc5`.

`Engine.each(rows, key, template)` hands its template a `RowRef(ctx, item)`
and wants an `Elem(Row(ctx, item))` back, so each `each` adds a `Row` to the
context's type. A view of a tree, whose rows hold rows of the same type, has
to call its row template from inside itself one `Row` deeper. Roc rejects
that as polymorphic recursion, so a view can draw a tree only to a depth
written out in its code:

```roc
app [main] { pf: platform "https://github.com/lukewilliamboswell/roc-signals/releases/download/0.5.0/2SYUPo9uKFPJDvTyXiwsLEqHvmq7UMgaY4hdgMiSsSEF.tar.zst" }

import pf.Engine exposing [Elem, Row, RowRef]

## A node of an outline, whose children are nodes.
Node := [Node({ key : Str, label : Str, children : List(Node) })].{
	is_eq : _
}

key : Node -> Str
key = |Node(n)| n.key

label : Node -> Str
label = |Node(n)| n.label

children : Node -> List(Node)
children = |Node(n)| n.children

## A node and, below it, its children, drawn by this same template.
node_view : RowRef(ctx, Node) -> Elem(Row(ctx, Node))
node_view = |row|
	Engine.element(
		"li",
		[],
		[
			Engine.text_s(row.field(label)),
			Engine.element("ul", [], [Engine.each(row.field(children), key, |child| node_view(child))]),
		],
	)

outline : List(Node)
outline = [Node({ key: "a", label: "A", children: [Node({ key: "b", label: "B", children: [] })] })]

main : Engine.Program
main = Engine.program(|| Engine.element("ul", [], [Engine.each(Engine.const(outline), key, node_view)]))
```

```
$ roc check main.roc
── ✗ polymorphic recursion ────────────────────────────────────── main.roc:27:76

This use passes changing types to a recursion.

Engine.element("ul", [], [Engine.each(row.field(children), key, |child| node_view(child))]),
                                                                        ^^^^^^^^^

Hint: A function that reaches itself again, directly or through other
functions, must pass each of its type variables through unchanged, or use types
with no type variables. An argument that wraps a type variable, like f([x])
inside f : a -> U64 would use the function at a different type at every level
of the recursion.

── 1 error and 0 warnings ───────────────────────────────────────────── main.roc
```

The compiler is right to refuse it: the app is compiled one specialization
per type, and this one would need one per depth.

The guide's
[Conditionals and Lists](https://lukewilliamboswell.github.io/roc-signals/docs/dynamic-structure/)
page says "a branch may contain the same function again: recursive UI, such
as a tree, needs no special support". That holds for `when` and `switch`,
which keep the context, so a tree whose shape is in the code can recurse.
It does not hold for a tree whose depth is known only from data: a file
tree, nested comments, an outline, or a parsed document such as Markdown,
whose lists and block quotes nest and whose emphasis can sit inside a link
inside a list item.

## Proposed improvement

A tree combinator that does the recursion in the engine, at one context type
for every depth, for example

```roc
Engine.tree : Signal(ctx, List(node)), (node -> Str), (node -> List(node)), (RowRef(ctx, node), Elem(Node(ctx, node)) -> Elem(Node(ctx, node))) -> Elem(ctx)
```

where `Node(ctx, node)` is the context of a node at any depth, and the
template is given the node and an element holding its children,
already drawn by the same template, to place where it likes. Keyed
reconciliation would work per level as it does for `each`.

Short of that, the guide could say that a tree from data is limited to a
depth fixed in the code, and suggest the workaround below.

## Current workaround

Either write the template out to a fixed depth, one function per level, or
render the tree to HTML text in Roc and show it through a custom element, as
the guide's "Third-party widgets" section describes: the app writes
`Engine.element("kai-html", [Engine.attr_s("html", html)], [])` and the page
defines `<kai-html>` to set its `innerHTML` when the attribute changes.
The second way loses keyed updates (the whole tree is replaced on every
change) and the native spec runner, which runs no JavaScript, cannot see
inside the element. It is how
[kai.blu.cx](https://github.com/thebrandonlucas/kai.blu.cx) (Kai's website,
a roc-signals app) shows its Markdown.
