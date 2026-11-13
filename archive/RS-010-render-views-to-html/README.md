# Render an app's page to HTML when a site is built

> **Archived 2026-11-13:** not filed: [lukewilliamboswell/roc-signals#247](https://github.com/lukewilliamboswell/roc-signals/issues/247) (the build paints a page's first frame, and the engine adopts it at mount) covers it.

> **Checked 2026-11-12:** missing in roc-signals `0.5.0`: the only render output is the command stream the browser runtime applies.

This is a platform capability gap in [roc-signals](https://github.com/lukewilliamboswell/roc-signals)
(a Roc platform for browser apps), not a compiler bug. Found on roc-signals
`0.5.0` with Roc `nightly-2026-11-11-7679cc5`.

A site whose pages are documents (a blog, documentation, a portfolio) needs
each page as HTML before any script runs: for readers without JavaScript, for
link previews, which read `<title>` and `<meta>` and never run scripts, and
for search engines. A roc-signals app draws nothing until its module has
loaded and, for a page drawn from data, until that data has arrived. So such
a site keeps a second program that writes the same pages as static HTML, and
the app draws over them. Every page's markup is then written twice, once as
strings for the static pages and once as `Engine.element` trees, and the two
must be kept the same by hand.

`design.md` lists server-side rendering as a non-goal, and says any future
server path "must keep the command stream as the only render output". This
proposal stays inside that: the HTML is made from the command stream, ahead
of time, not by a server.

## Proposed improvement

A way to run an app's `Program` at a given URL, with given answers to its
requests, and print the document it draws as HTML: for example a mode of the
native spec runner (which already mounts the `Program`, answers its requests
from staged values, and decodes its command stream into a DOM model in
`Dom.roc`), such as

```
spec-runner --render /posts/blog/hello/ --answer /data/site.json=site.json > page.html
```

writing the root's children as HTML, plus the title the app asked for. A
static site generator then calls it once per page. The app mounts over that
HTML in the browser as it would over an empty root (replacing it, which is
what such a site does today); adopting the existing nodes instead of
replacing them is a separate step the non-goal already describes.

## Current workaround

Two programs. [blu.cx](https://github.com/thebrandonlucas/blu) (a personal
site and blog) writes every page as HTML with a static site generator whose
site program is also Roc, puts it in `#static`, and mounts the app in `#app`
beside it. The app downloads the site's data, draws the page it is at, and
then draws an element whose script removes `#static`:

```js
customElements.define('blu-ready', class extends HTMLElement {
  connectedCallback() {
    const page = document.getElementById('static');
    if (page) page.remove();
  }
});
```

The two programs share the page logic through a Roc package, but each page's
markup is written in both, and a check in Chrome compares the text of the two
versions of every page to catch drift.

## Related

- The "Server-side rendering, hydration and SEO" non-goal in `design.md`.
