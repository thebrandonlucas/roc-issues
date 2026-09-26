# BUG-011: `roc fmt` deletes a multiline-string line that has an invalid escape

Found with Roc `nightly-2026-09-23-c7852fd`. Still reproduces on
`nightly-2026-09-26-d6267b4`, the newest nightly on 2026-09-26, which this
repro's shell pins. No platform or package is needed.

## Description

`Invalid.roc` has a `\\` multiline string whose first line ends in a lone
backslash, which is not a valid escape:

```roc
Invalid := [].{
	x =
		\\first \
		\\second
}
```

`roc check Invalid.roc` correctly rejects it. `roc fmt Invalid.roc` instead
reports success and silently deletes the whole `\\first \` line. The result is
a different module, which `roc check` now accepts.

## Expected behavior

`roc fmt` either leaves the file unchanged or refuses to format it and reports
the invalid escape, as `roc check` does:

```text
── ✗ invalid escape sequence ────────────────────────────────── Invalid.roc:3:11

This escape sequence is not recognized.

\\first \
\\second
```

## Actual behavior

```text
$ roc fmt Invalid.roc
Successfully formatted 1 files
$ echo $?
0
$ cat Invalid.roc
Invalid := [].{
	x =
		\\second
}
$ roc check Invalid.roc
No errors found in 13ms for Invalid.roc
```

## Reproduction

### Shell with the exact compiler

From this directory, enter a shell with Roc `nightly-2026-09-26-d6267b4`,
pinned by this repro's `flake.nix` and `flake.lock` (Linux):

```sh
nix develop .
roc version
# Roc compiler version nightly-2026-09-26-d6267b4
```

The root `nix develop` shell selects a different compiler; use this per-repro
shell.

Inside that shell, reproduce manually on a copy (`roc fmt` edits in place):

```sh
cp Invalid.roc /tmp/Invalid.roc
roc check /tmp/Invalid.roc   # exit 1, invalid escape sequence
roc fmt /tmp/Invalid.roc     # exit 0
cat /tmp/Invalid.roc         # the \\first line is gone
```

### Automated harness

From this directory:

```sh
nix develop . --command bash repro.sh
```

The harness copies the sources to a temporary directory with a fresh cache. It
checks that `roc fmt` leaves `Valid.roc` (an escaped `\\` instead of `\`)
unchanged and that `roc check` rejects `Invalid.roc`. It then reports success
only when `roc fmt Invalid.roc` exits 0, deletes the `\\first` line, and the
result no longer has the escape error.

## Observations

- **Any invalid escape, anywhere on the line:** `\\first \q` is deleted the
  same way, and so is `\\first\` without the space.
- **Every such line goes:** with three lines `\\a \`, `\\b \`, `\\c`, only
  `\\c` remains. A single line `\\only \` becomes an empty `\\` line. When the
  last line is the invalid one (`\\first`, `\\second \`), only `\\first`
  remains.
- **Valid escapes are kept:** `\\first \\` formats unchanged, and
  `roc fmt --check` accepts it.
- **Single-quoted strings behave differently:** `x = "first \"` (an unclosed
  string) is rewritten to `x = "first \""`, a string that closes, again with
  exit 0.
- **Impact:** a formatter run on save, or `roc fmt` in CI, turns a typo into a
  silent change of the program's string data instead of an error.
- **Upstream status:** no existing issue or PR found on 2026-09-26.
