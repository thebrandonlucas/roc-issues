#!/usr/bin/env bash
# Rechecks every ready bug (<project>/BUG-*/ISSUE.md, outside archive/) on the newest Roc nightly:
#
#   1. pins the nightly in nightly.json (its download for each platform, by
#      hash), so `nix develop .#latest` gives everyone exactly that compiler;
#   2. builds it, then for each bug with a `recheck` file extracts the code
#      from ISSUE.md into a fresh directory with an empty cache and runs the
#      file's command; `reproduced-if` (an extended regex over the output and a
#      final `exit=N` line) says whether the bug is still there;
#   3. prints a table, and in each ISSUE.md that still reproduces replaces the
#      nightly it names with the new one.
#
#   scripts/recheck.sh [nightly-tag]     (default: roc-lang/nightlies' latest)
#
# Needs nix with flakes. It changes only nightly.json and ISSUE.md files;
# reviewing, archiving fixed bugs and committing are left to you (AGENTS.md).
set -euo pipefail
cd "$(dirname "$0")/.."

tag=${1:-$(curl -fsSL https://api.github.com/repos/roc-lang/nightlies/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')}
[ -n "$tag" ] || { echo "could not find the latest nightly"; exit 1; }
date=$(echo "$tag" | sed -E 's/^nightly-([0-9]{4}-[0-9]{2}-[0-9]{2})-.*/\1/')
hash=$(echo "$tag" | sed -E 's/^nightly-[0-9-]{10}-//')
echo "nightly: $tag"

# 1. Pin it.
asset() { echo "https://github.com/roc-lang/nightlies/releases/download/$tag/roc_nightly-$1-$date-$hash.tar.gz"; }
prefetch() { nix store prefetch-file --json --hash-type sha256 "$1" | sed -n 's/.*"hash": *"\([^"]*\)".*/\1/p'; }
{
  echo "{"
  echo "  \"tag\": \"$tag\","
  echo "  \"assets\": {"
  first=1
  for pair in x86_64-linux:linux_x86_64 aarch64-linux:linux_arm64 aarch64-darwin:macos_apple_silicon x86_64-darwin:macos_x86_64; do
    system=${pair%%:*} name=${pair#*:}
    url=$(asset "$name")
    [ $first = 1 ] || echo ","
    first=0
    printf '    "%s": { "url": "%s", "hash": "%s" }' "$system" "$url" "$(prefetch "$url")"
  done
  echo
  echo "  }"
  echo "}"
} > nightly.json.new
mv nightly.json.new nightly.json
git add nightly.json   # flakes only see files git tracks

# 2. Build it and run each issue's code with it.
roc=$(nix build --no-link --print-out-paths .#latest)/bin/roc
echo "compiler: $("$roc" version)"
echo

printf '%-9s %-12s %s\n' bug result "exit, command"
still=()
for dir in */BUG-*/; do
  case "$dir" in archive/*) continue;; esac
  [ -f "$dir/recheck" ] && [ -f "$dir/ISSUE.md" ] || continue
  bug=$(basename "$dir" | cut -d- -f1-2)
  command=$(sed -n 's/^command: //p' "$dir/recheck")
  pattern=$(sed -n 's/^reproduced-if: //p' "$dir/recheck")
  work=$(mktemp -d)
  # Extract the files ISSUE.md shows: `path`: (or "`a` and `b` (the same
  # content):", or a <summary><code>path</code>) followed by a ```roc block.
  awk -v dir="$work" '
    /^`[^`]+`( and `[^`]+`)?( \(the same content\))?:$/ {
      n = 0; line = $0
      while (match(line, /`[^`]+`/)) { paths[++n] = substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) }
      want = 1; next
    }
    /<summary><code>[^<]+<\/code>/ { match($0, /<code>[^<]+<\/code>/); n = 1; paths[1] = substr($0, RSTART + 6, RLENGTH - 13); want = 1; next }
    want && /^```roc$/ { inblock = 1; next }
    inblock && /^```$/ { inblock = 0; want = 0; for (i = 1; i <= n; i++) close(dir "/" paths[i]); next }
    inblock { for (i = 1; i <= n; i++) { f = dir "/" paths[i]; sub(/\/[^\/]*$/, "", f); system("mkdir -p \"" f "\""); print > (dir "/" paths[i]) } }
  ' "$dir/ISSUE.md"
  # Platforms with targets get empty host archives (the issues say so).
  for t in x64musl arm64musl; do [ -d "$work/platform" ] && mkdir -p "$work/platform/targets/$t" && printf '!<arch>\n' > "$work/platform/targets/$t/libhost.a"; done
  set +e
  out=$(cd "$work" && HOME="$work" XDG_CACHE_HOME="$work/.cache" timeout 300 "$roc" ${command#roc } 2>&1)
  code=$?
  set -e
  if printf '%s\nexit=%s\n' "$out" "$code" | grep -Eq -- "$pattern"; then
    result=reproduces
    still+=("$dir")
  else
    result="NOT FOUND"
    printf '%s\n' "$out" | tail -15 > "$dir/recheck.last-output"
  fi
  printf '%-9s %-12s %s, %s\n' "$bug" "$result" "$code" "$command"
  rm -rf "$work"
done

# 3. Name the new nightly in the bugs that still reproduce: their ISSUE.md and
#    README, in place (drafts carry no dated recheck notes).
for dir in "${still[@]}"; do
  for f in "$dir/ISSUE.md" "$dir/README.md"; do
    [ -f "$f" ] || continue; sed -E -i "s/nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-f]{7}([\`)]?) before posting/$tag\1 before posting/; s/^\*\*Nightly:\*\* \`nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-f]{7}\`/**Nightly:** \`$tag\`/; s/through \`nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-f]{7}\`/through \`$tag\`/g; s/to \`nightly-2026-1[01]-[0-9]{2}-[0-9a-f]{7}\`\./to \`$tag\`./g" "$f"
  done
done
echo
echo "${#still[@]} still reproduce on $tag; their ISSUE.md and README now name it. For any NOT FOUND,"
echo "<project>/<dir>/recheck.last-output has the end of what the compiler printed."
