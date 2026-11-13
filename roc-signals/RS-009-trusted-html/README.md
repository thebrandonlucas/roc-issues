# Let an app show HTML it trusts

An app cannot put a fragment of HTML it already has into the page. Text
rendered from Markdown ahead of time (a post, an article, a README) is HTML
with headings, lists, code blocks, tables and links; to show it, an app must
parse it in Roc and rebuild every node with `Engine.element` and
`Engine.text`, or hand it to a custom element.

**roc-signals:** `0.5.0` · **Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64)

### What it takes today

A custom element, defined by a script on the page, that sets its
`innerHTML` from an attribute:

```roc
markup : Signal(ctx, Str) -> Elem(ctx)
markup = |html| Engine.element("trusted-html", [Engine.attr_s("data-html", html)], [])
```

```js
customElements.define('trusted-html', class extends HTMLElement {
  static observedAttributes = ['data-html'];
  attributeChangedCallback(name, previous, html) {
    this.innerHTML = html || '';
  }
});
```

The whole text travels as an attribute value, specs cannot see any of it,
and each app writes the same element again.

### Proposed

An element whose children are an HTML string the app vouches for, for
example `Html.trusted(tag, attrs, html : Signal(ctx, Str))`. The runtime sets
the element's `innerHTML` when the value changes and the engine never looks
inside it; the name says the app answers for what the HTML contains.

- Events from inside it bubble to handlers on the element as usual, so a
  click on a link inside can be heard with `click:prevent`; the event
  payload would need the link's `href` for an app to navigate in place.
- For specs, the native runner's DOM model could parse the HTML into nodes
  (the subset a Markdown renderer emits), or keep it as one node whose text
  content is the HTML's text, so `expect-text` and `(text ...)` locators can
  see into it.

Elm has packages that set `innerHTML` through a property; React has
`dangerouslySetInnerHTML`.

## Related

- The non-goal in `design.md` on server-side rendering is about the engine
  producing HTML; this is the reverse, the engine accepting HTML it does not
  interpret.
