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
- **Roc only, or a link.** This repo, and everything posted from it, is read
  by people who know Roc and nothing of the projects these bugs were found
  in. Name another project (Kai, Lyceum Study, Archeion, Claude Code, ...)
  only with a link to it and a few words on what it is, on its first mention
  in each file, e.g. "[Kai](https://github.com/thebrandonlucas/kai) (a CLI
  for Nix and Guix written in Roc)", and link any file of it you cite.
  Better still, describe the code without the project when the name adds
  nothing. Applies to READMEs, notes and issues alike; never cite a private
  repository.
- **Facts only.** No guesses about the cause in the compiler. Observations
  (what changes the result) are welcome.
- **Smallest dependencies.** Drop basic-cli when the bug doesn't need it; when
  it does, use the current release, not the one the draft pinned.
- **The disclosure line is always the last line,** exactly as in the
  template, with the nightly filled in.
- Keep the title free of "Bug:" or "[BUG-XXX]" prefixes and of the repo's
  numbering.

## Drafts stand on their own

A draft's README and ISSUE.md are pasted, or read, outside this repo, so they
must make sense to someone who has never seen it:

- **Titles** (the README's and the issue's): no `BUG-XXX:` or
  `IMPROVEMENT-XXX:`; just what is wrong, starting with a capital. The
  numbers live only in directory names and the README index.
- **No filing status.** Never write "not filed upstream", "ready to file",
  "searched upstream on ... found nothing" or the like: a draft in `bugs/` is
  unfiled by definition, and a filed one is archived. Upstream issues that
  are related go under a `## Related` heading, with a link and a clause on
  how they relate.
- **Dated notes** (`> **Rechecked YYYY-MM-DD:** ...` on line 3) say only
  what was checked and what happened, on which nightly.
- **Anything of this repo's** (the harness, the pinned shell, another
  draft) says where it lives: "From this bug's directory in
  [roc-issues](https://github.com/thebrandonlucas/roc-issues/tree/master/bugs/<dir>)",
  "A reproduction script, with the compiler it was found on pinned by Nix:
  [roc-issues](<link>)". Never refer to another draft by its number.

## Improvements

Feature ideas (`improvements/`) go to the Roc Zulip (#ideas, or #contributing
for basic-cli) before any issue, as Roc's CONTRIBUTING asks. Use the same
structure where it fits: what you want, the current workaround, and why.

## Posting

- Never post without the user's explicit go for that specific issue or
  comment. Show the final `ISSUE.md` first.
- Post with `gh issue create -R roc-lang/roc --title "<title>" --body-file
  <body>` (the body is `ISSUE.md` without its first line).
- Afterwards, archive the draft (see "Archiving") with a note linking the
  issue, and commit.

## Archiving

Don't delete drafts. Move one that no longer reproduces, is fixed upstream or
is no longer needed to `archive/` with `git mv`, add a dated
`> **Archived YYYY-MM-DD:** <why>` line under its title, and move its index
entry to the README's "Archived" section.

## Rechecking on the newest nightly

Before posting anything, and whenever asked to "recheck", run

```sh
scripts/recheck.sh            # or: scripts/recheck.sh nightly-YYYY-MM-DD-<hash>
```

It pins the newest nightly in `nightly.json` (so `nix develop .#latest` gives
anyone that exact compiler), runs each `bugs/*/ISSUE.md`'s code as written
(`bugs/*/recheck` holds the command and what output means "still
reproduces"), prints a table, and names the new nightly in the issues that
still reproduce. Then:

1. For each `NOT FOUND`, read `recheck.last-output`, confirm by hand (it may
   be fixed, or the compiler's wording changed), find the nightly that fixed
   it if you can, and archive it (see "Archiving") or fix its `recheck`.
2. If an issue's Observed output changed (line numbers, wording), update it.
3. Refresh line 3 of each kept draft's README (the dated recheck note).
4. Commit and push, and report the table.

A new bug added to `bugs/` needs a `recheck` file:

```
command: roc check Main.roc
reproduced-if: <extended regex over the output and a final exit=N line>
```
