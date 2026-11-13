# Let a view draw a tree whose depth comes from data

**roc-signals:** `0.5.0` · **Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

`Engine.each` hands its template a `RowRef(ctx, item)` and wants an
`Elem(Row(ctx, item))`, so a template that draws its children with `each`
calls itself one `Row` deeper, and `roc check` rejects that as polymorphic
recursion. A tree whose depth comes from data (an outline, nested comments,
a parsed Markdown document) can only be drawn to a depth written out in the
code, one template per level. The
[Conditionals and Lists](https://lukewilliamboswell.github.io/roc-signals/docs/dynamic-structure/)
guide says "recursive UI, such as a tree, needs no special support", which
holds for `when` and `switch` but not for `each`.

### Repro

`main.roc`:

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

### Command

```
roc check main.roc
```

### Observed

```
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

### What would help

A combinator that does the recursion in the engine, at one context type for
every depth, for example

```roc
Engine.tree : Signal(ctx, List(node)), (node -> Str), (node -> List(node)), (RowRef(Tree(ctx, node), node), Elem(Tree(ctx, node)) -> Elem(Tree(ctx, node))) -> Elem(ctx)
```

where the template gets the node and its children, already drawn, to place
where it likes, with keyed updates per level as `each` has. Failing that,
the guide could say a tree from data is limited to a depth fixed in the
code.
