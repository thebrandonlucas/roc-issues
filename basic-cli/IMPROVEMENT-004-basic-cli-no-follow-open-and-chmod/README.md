# Let basic-cli read a file without following symlinks and set its mode

basic-cli cannot open a file with `O_NOFOLLOW` or set a file's permission
bits. `Path.read_bytes!` follows a final-component symlink, so code that
checks an entry with `Path.type!` and then reads it has a race: a file
replaced by a symlink between the two calls leaks the link target's bytes.
`Path.set_permissions!` sets only `OwnerOnly` or `PublicRead`, follows
symlinks, and cannot set execute bits.

**Nightly:** `nightly-2026-11-12-ce942d6` (linux x86_64), basic-cli `0.28.0`

### What it takes today

```roc
app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.28.0/2yhxoR7cZPSYbyUzPWULFw8AA6QEcdsgFNRmzu7pZbst.tar.zst" }

import pf.Path

## Copies `src` to `dst` if `src` is a regular file.
copy_file! : Path, Path => Try({}, _)
copy_file! = |src, dst|
	match Path.type!(src)? {
		IsFile => {
			# If src is replaced by a symlink here, this reads the link's target.
			bytes = Path.read_bytes!(src)?
			Path.write_bytes!(dst, bytes)
		}
		_ => Ok({})
	}

main! = |_args| copy_file!(Path.unix("a"), Path.unix("b"))
```

The safe alternative is running `cp -P` and `chmod` as child processes.
`Path.copy_dir_with!` with `symlinks: Preserve` covers copying a whole
directory, but not a single file.

### Proposed

For example:

- `Path.read_bytes_no_follow! : Path => Try(List(U8), ...)`, which opens
  with `O_NOFOLLOW` and fails on a symlink;
- `Path.set_mode! : Path, U32 => Try({}, ...)` (Unix permission bits).
