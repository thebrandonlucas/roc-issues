# Rules for agents in roc-issues

This repo holds reproductions of Roc compiler and basic-cli bugs, and the
issues filed from them. Follow these rules every time you write or post an
upstream issue or comment.

## Before writing an issue

1. Rerun the draft's `repro.sh` on the newest Roc nightly (with that nightly's
   `roc` first on `PATH`). Only file what still reproduces; archive the rest
   (see "Archiving").
2. If it is a regression, find the last nightly that worked and the first that
   fails, from the nightlies you can run.
3. Search roc-lang/roc (and roc-lang/basic-cli for platform issues), open and
   closed, for the same failure. Check each candidate's **author** before
   calling it ours: a link in a draft is often someone else's related issue.
   If an open issue is the same bug, comment there instead of filing.
4. One bug per issue.

## Issue format

Write the issue to `bugs/BUG-XXX-*/ISSUE.md`. The first line is the title as
`# <title>`; everything after it is the body, posted exactly as written. A
comment on an existing issue goes to `COMMENT.md`, first line
`# Comment on roc-lang/roc#N`.

The format follows the issues Roc's maintainers write themselves (for example
roc-lang/roc#12851):

````markdown
# <What fails, stated concretely> when <the condition>

<One paragraph: what happens, with which command, and what should happen
instead.>

**Nightly:** `nightly-YYYY-MM-DD-<hash>` (linux x86_64)

### Repro

`<path>`:

```roc
<the file, in full>
```

<every other file the same way. A non-Roc file (an empty libhost.a, say)
gets the one shell command that creates it.>

### Command

```
roc <check|build|test> <file>
```

### Observed

```
<the compiler's output, verbatim; trim unrelated lines and shorten local
paths>
```

### Expected

<One or two sentences: the diagnostic or result that should appear.>

### Notes

- <Each change that makes the bug go away, from the draft's observations.>
- Regression: works on `<last good nightly>`, fails since `<first bad
  nightly>` (if known).
- Related: roc-lang/roc#N, <one clause on how it relates> (only if checked).
- Harness: https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/<dir>

---
*Drafted with Claude (Claude Code) and checked by me on `<nightly>` before
posting.*
````

Rules for the body:

- **Paste the repro inline, in full.** Never open with "Full repro here" or
  "Agent description:"; the harness link goes last, in Notes, as an extra.
  A file longer than about 40 lines goes in a collapsed
  `<details><summary><code>path</code> (N lines: what it is)</summary>` block,
  still in full. Shrink the repro first if you can, and rerun it after.
- **Check the exact text.** Extract the code from `ISSUE.md` into a fresh
  directory and run the command on the stated nightly (and the last good one
  for a regression) before calling it ready.
- **Facts only.** No guesses about the cause in the compiler. Observations
  (what changes the result) are welcome.
- **Smallest dependencies.** Drop basic-cli when the bug doesn't need it; when
  it does, use the current release, not the one the draft pinned.
- **The disclosure line is always the last line,** exactly as in the
  template, with the nightly filled in.
- Keep the title free of "Bug:" or "[BUG-XXX]" prefixes and of the repo's
  numbering.

## Improvements

Feature ideas (`improvements/`) go to the Roc Zulip (#ideas, or #contributing
for basic-cli) before any issue, as Roc's CONTRIBUTING asks. Use the same
structure where it fits: what you want, the current workaround, and why.

## Posting

- Never post without the user's explicit go for that specific issue or
  comment. Show the final `ISSUE.md` first.
- Post with `gh issue create -R roc-lang/roc --title "<title>" --body-file
  <body>` (the body is `ISSUE.md` without its first line).
- Afterwards, record the URL in the draft README's "Upstream status" section
  and in the root README index, and commit.

## Archiving

Don't delete drafts. Move one that no longer reproduces, is fixed upstream or
is no longer needed to `archive/` with `git mv`, add a dated
`> **Archived YYYY-MM-DD:** <why>` line under its title, and move its index
entry to the README's "Archived" section.
