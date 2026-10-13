#!/usr/bin/env bash
# Usage: ./install.sh <project-dir> <package | package:skill>...
# Copies skills into <project>/.agents/skills (Codex) and links .claude/skills to it (Claude Code).
# A package with hooks also gets them merged into .claude/settings.json and .codex/hooks.json.
# Re-running updates the installed copies; it is safe to run twice.
set -euo pipefail
[ $# -ge 2 ] || { sed -n 2,5p "$0" >&2; exit 1; }
repo=$(cd "$(dirname "$0")" && pwd)
project=$(cd "$1" && pwd)
shift

# Merge upstream hook groups into a settings file, keeping everything already there.
# $1 target json, $2 upstream hooks json, $3 command prefix that replaces the plugin-cache path.
merge_hooks() {
  local cur='{}'
  [ ! -f "$1" ] || cur=$(cat "$1")
  # shortcut: assumes every upstream command names a hooks/<file>.js (true for ponytail), revisit for other hook packages.
  jq --arg pre "$3" --slurpfile up "$2" '
    ($up[0].hooks | map_values(map(.hooks |= map(
      .command = $pre + (.command | capture("hooks/(?<f>[A-Za-z0-9._-]+\\.js)").f) + "\"")))) as $new
    | reduce ($new | to_entries[]) as $e (.;
        (.hooks[$e.key] // []) as $old
        | .hooks[$e.key] = $old + [$e.value[] | select(. as $g | $old | any(.[]; . == $g) | not)])
  ' <<<"$cur" > "$1.tmp"
  mv "$1.tmp" "$1"
}

install_hooks() {
  local v="$repo/vendor/$1"
  mkdir -p "$project/.agents/hooks" "$project/.codex"
  # .agents/hooks sits next to .agents/skills, where ponytail's scripts look for their SKILL.md.
  cp "$v"/hooks/*.js "$project/.agents/hooks/"
  merge_hooks "$project/.claude/settings.json" "$v/hooks/hooks.json" \
    'node "$CLAUDE_PROJECT_DIR/.agents/hooks/'
  # PLUGIN_DATA is how ponytail's scripts tell Codex apart from Claude Code.
  merge_hooks "$project/.codex/hooks.json" "$v/hooks/hooks.json" \
    'PLUGIN_DATA="$HOME/.codex/ponytail" node "$(git rev-parse --show-toplevel)/.agents/hooks/'
}

skills="$project/.agents/skills"
mkdir -p "$skills" "$project/.claude"
if [ ! -e "$project/.claude/skills" ] && [ ! -L "$project/.claude/skills" ]; then
  ln -s ../.agents/skills "$project/.claude/skills"
elif [ "$(readlink "$project/.claude/skills")" != ../.agents/skills ]; then
  echo ".claude/skills already exists; move its skills into .agents/skills and delete it first" >&2
  exit 1
fi

seen=" "
for arg in "$@"; do
  pkg=${arg%%:*}
  v="$repo/vendor/$pkg"
  [ -d "$v" ] || { echo "unknown package: $pkg (see vendor/)" >&2; exit 1; }
  if [ "$arg" = "$pkg" ]; then names=$(ls "$v/skills"); else names=${arg#*:}; fi
  for n in $names; do
    [ -d "$v/skills/$n" ] || { echo "unknown skill: $pkg:$n (see vendor/$pkg/skills/)" >&2; exit 1; }
    case $seen in *" $n "*) echo "skill $n requested twice; pick one with package:skill" >&2; exit 1 ;; esac
    seen="$seen$n "
    rm -rf "${skills:?}/$n"
    cp -R "$v/skills/$n" "$skills/$n"
    echo "installed $pkg:$n"
  done
  if [ -f "$v/hooks/hooks.json" ]; then install_hooks "$pkg"; echo "installed $pkg hooks"; fi
done
