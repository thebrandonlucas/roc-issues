# Let `Html.icon_button` take extra attributes

**roc-signals:** `0.6.0` · **Nightly:** `nightly-2026-11-15-f25da45` (linux x86_64)

`Html.icon_button : Str, Signal(ctx, Str), Str, Handler(ctx) -> Elem(ctx)`
takes a glyph, an accessible name, a class and a handler, and no attribute
list, unlike `Html.button` and `Html.text_input`. An icon-only button
usually wants a `title`, so a pointer user can see what it does, and
sometimes `disabled`, `aria-pressed` or a ref, and none of these can be
added.

### What it takes today

Writing the button out again, as `icon_button` does inside:

```roc
Engine.element(
	"button",
	[
		Engine.attr_s("aria-label", name),
		Engine.attr_s("title", name),
		Engine.attr("type", "button"),
		Engine.class("icon"),
		Engine.on_click(handler),
	],
	[Engine.text("✕")],
)
```

### Proposed

An attribute list on `icon_button`, appended as `button` does, for example
`icon_button : Str, Signal(ctx, Str), List(Attr(ctx)), Handler(ctx) -> Elem(ctx)`
with the class passed as one of the attributes; or an `icon_button_with`
beside it.
