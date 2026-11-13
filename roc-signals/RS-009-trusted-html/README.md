# Let an app show HTML it trusts

> **Checked 2026-11-12:** missing in roc-signals `0.5.0`: no element takes its children from an HTML string.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Found on roc-signals
`0.5.0` with Roc `nightly-2026-11-11-7679cc5`.

An app cannot put a fragment of HTML it already has into the page. The text
of a blog post, an article or a README is typically rendered from Markdown
ahead of time, by a static site generator or a server, into HTML with
headings, lists, code blocks, tables, footnotes and links. An app that shows
that text has two ways to draw it today: parse the HTML (or the Markdown) in
Roc and rebuild every node with `Engine.element` and `Engine.text`, or hand
it to a custom element. Elm, where the same need comes up, has packages that
set `innerHTML` through a property; React has `dangerouslySetInnerHTML`.

## Proposed improvement

An element whose children are an HTML string the app vouches for, for
example `Html.trusted(tag, attrs, html : Signal(ctx, Str))`. The runtime sets
the element's `innerHTML` when the value changes and the engine never looks
inside it; the name says the app answers for what the HTML contains.

- Events from inside it bubble to handlers on the element as usual, so a
  click on a link inside can be heard with `click:prevent` and its `href`
  (the event payload would need the target's `href`, or a `closest("a")`
  lookup, for an app to navigate in place).
- For specs: the native runner's DOM model could parse the HTML into nodes
  (the subset a Markdown renderer emits), or keep it as one opaque node whose
  text content is the HTML's text, so `expect-text` and `(text ...)` locators
  can see into it.

## Current workaround

A custom element, as the docs suggest for third-party widgets. The app draws
it with the HTML in an attribute:

```roc
markup : Str, Signal(ctx, Str) -> Elem(ctx)
	where [ctx.store : () -> Engine.Reach(ctx, _)]
markup = |cls, html| Engine.element("blu-markup", Parts.classes(cls).concat([Engine.attr_s("data-html", html), Engine.on("change", BluStore.go_to({}))]), [])
```

and a script on the page defines it, sets `innerHTML` when the attribute
changes, and turns a click on a link inside into a `change` event whose value
is the link's path, so the app can navigate without a page load:

```js
customElements.define('blu-markup', class extends HTMLElement {
  static observedAttributes = ['data-html'];
  constructor() {
    super();
    this.value = '';
    this.addEventListener('click', (event) => {
      const link = event.target.closest('a[href]');
      if (!link || link.origin !== location.origin || link.hash) return;
      event.preventDefault();
      this.value = link.pathname + link.search;
      this.dispatchEvent(new Event('change', { bubbles: true }));
    });
  }
  attributeChangedCallback(name, previous, html) {
    this.innerHTML = html || '';
  }
});
```

It works, but every page's whole text travels as an attribute value, the
specs cannot see any of it (a spec can't check that a post's text or its
links are there), and each app writes the same element again.

Used by [blu.cx](https://github.com/thebrandonlucas/blu) (a personal site and
blog, whose pages are Markdown rendered to HTML when the site is built).

## Related

- The non-goal in `design.md` on server-side rendering is about the engine
  producing HTML; this is the reverse, the engine accepting HTML it does not
  interpret.
