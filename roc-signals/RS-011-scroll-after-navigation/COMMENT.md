# Comment on lukewilliamboswell/roc-signals#204

Another use for the scroll request, from a site whose pages are documents
([blu.cx](https://github.com/thebrandonlucas/blu), a personal site and blog,
on roc-signals `0.5.0`): moving between pages.

When a link asks for `Push(url)` and the app draws the new page, the window
stays scrolled where the old page was, so a reader who clicks "Older" at the
bottom of a long post lands at the bottom of the next one. A browser loading
a page starts it at the top, or at the element its `#fragment` names. An app
that navigates in place needs to do the same, and today it can't scroll.

What it needs, in terms of the proposal above:

- **To the top after a move:** `ScrollTo(ref)` on an element at the top of
  the page (or a plain `ScrollTop`), issued with the `Push`.
- **To a fragment:** scrolling to the element with a given `id`, since the
  elements a link's `#fragment` names are usually rows of an `each` (a
  journal's entries, a post's headings), and row templates can't declare a
  ref. For example `ScrollToId(id)`.

Going back and forward already works: the browser restores the position
itself, because the engine redraws the earlier page in the same turn as the
`Popstate` result.

The workaround today is `Focus` on a hidden, focusable element at the top of
the page, which the browser scrolls into view:

```roc
Engine.element("span", [Engine.class("top"), Engine.attr("tabindex", "-1"), Engine.ref("top")], []),
Engine.on_post(BluStore.cells.nav.signal(), |url| [Push(url), Focus("top")], Engine.ignore({})),
```

```css
.top { position: absolute; top: 0; left: 0; width: 1px; height: 1px; overflow: hidden; outline: none; }
```

and links with a fragment are left to the browser, which loads the page
(as static HTML the app then draws over), so they don't navigate in place.
