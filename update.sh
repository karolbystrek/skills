#!/usr/bin/env bash
# Re-fetch every upstream in sources.txt into vendor/<name>/. Review `git diff` before committing.
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

grep -vE '^[[:space:]]*(#|$)' sources.txt | while read -r name repo paths; do
  src="$tmp/$name" out="vendor/$name"
  git clone -q --depth 1 "$repo" "$src"
  rm -rf "$out"
  mkdir -p "$out/skills"
  for p in $paths; do
    case $p in
      hooks=*)
        h=${p#hooks=}
        mkdir -p "$out/hooks"
        cp "$src/$(dirname "$h")"/*.js "$out/hooks/"
        cp "$src/$h" "$out/hooks/hooks.json"
        ;;
      *)
        # Flatten category folders: skills/<category>/<skill>/SKILL.md -> skills/<skill>/
        find "$src/$p" -name SKILL.md | while read -r s; do
          d=$(dirname "$s") n=$(basename "$(dirname "$s")")
          [ ! -e "$out/skills/$n" ] || { echo "$name: two skills named $n" >&2; exit 1; }
          cp -R "$d" "$out/skills/$n"
        done
        ;;
    esac
  done
  cp "$src/LICENSE" "$out/"
  echo "$repo $(git -C "$src" rev-parse HEAD)" > "$out/UPSTREAM"
  echo "$name: $(ls "$out/skills" | wc -l | tr -d ' ') skills"
done
