# Let basic-cli read a file without following symlinks and set its mode

> **Rechecked 2026-11-12:** partly addressed in basic-cli `0.28.0`: `Path.set_permissions!` sets `OwnerOnly` or `PublicRead` on an existing file, but it follows symlinks and cannot set other modes (no execute bits). There is still no read that refuses a symlink. [Kai](https://github.com/thebrandonlucas/kai) (a CLI for Nix and Guix written in Roc) still runs `cp -R -P` in [`cli/Snapshot.roc`](https://github.com/thebrandonlucas/kai/blob/master/cli/Snapshot.roc).

This is a platform capability gap, not a compiler bug. basic-cli cannot open a
file with `O_NOFOLLOW` or set a file's permission bits. `Path.read_bytes!` and
`Path.copy!` follow a final-component symlink, so copying a tree by checking
each entry with `Path.type!` and then reading it has a race: a file replaced by
a symlink between the two calls leaks the link target's bytes into the copy.

Found with a basic-cli source build of PR #499. basic-cli `main` (checked
2026-09-26, after `0.23.0-rc1`) adds `Path.copy_dir_with!` with
`symlinks: Preserve`, which covers copying a whole directory, but still has no
no-follow read of a single file and no way to set a mode.

## Proposed improvement

Add, for example:

- `Path.read_bytes_no_follow! : Path => Try(List(U8), ...)`, which opens with
  `O_NOFOLLOW` and fails on a symlink;
- `Path.set_mode! : Path, U32 => Try({}, ...)` (Unix permission bits).

## Current workaround

Run GNU `cp -R -P --parents` (which opens with `O_NOFOLLOW` and checks the
inode it inspected) and `chmod` as child processes, in batches.

Used by: the project snapshot of [Kai](https://github.com/thebrandonlucas/kai) (a CLI for Nix and Guix written in Roc), [`cli/Snapshot.roc`](https://github.com/thebrandonlucas/kai/blob/master/cli/Snapshot.roc).
