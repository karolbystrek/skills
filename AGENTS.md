# Agent guide

My personal agent skills, optimised for Claude and ChatGPT/Codex. One repo, three install routes, one set of skills.

## Requirements

- Contains only my own skills. No vendored third-party skills, no install/update scripts, no build tooling, no `package.json`; just files.
- Installable three ways from the same `skills/` folder:
  - `npx skills add karolbystrek/skills` (one skill: `--skill <name>`), same layout as https://www.skills.sh/vercel-labs/agent-skills
  - Claude Code plugin: `/plugin marketplace add karolbystrek/skills`, then `/plugin install karolbystrek@karolbystrek`
  - Codex/ChatGPT plugin: `codex plugin marketplace add karolbystrek/skills`
- One plugin for the whole repo (`karolbystrek`). Split into several plugins only if the collection outgrows this.
- Use the newest manifest formats so they need no near-term migration: portable Agent Plugins 1.0.0 for Codex/ChatGPT; Claude Code's own format (it does not read the portable one).
- Skills only. Hooks, commands and MCP are out of scope until needed.

## Layout

```
skills/<skill-name>/SKILL.md      # skills; the only place skills live
skills/<skill-name>/references/   # optional, one level deep
skills/<skill-name>/scripts/      # optional
skills/<skill-name>/assets/       # optional
GLOBAL.md                         # global agent instructions; not a skill, not installed by any route, symlinked by hand (below)
plugin.json                       # Agent Plugins 1.0.0 manifest (Codex/ChatGPT); skills/ is discovered, no skills field
.agents/plugins/marketplace.json  # Codex marketplace, one entry, source.path "./"
.claude-plugin/plugin.json        # Claude Code manifest
.claude-plugin/marketplace.json   # Claude Code marketplace, one entry, source "./"
```

Keep `name`, `description`, author and repo URL identical across the four manifests; change them together. Claude manifests omit `version` so every commit is an update; `plugin.json` needs one, bump it on release.

## Global instructions

`GLOBAL.md` holds the instructions every run should follow, in any repository. None of the install routes carry it, so on each machine symlink it from the global files of both tools:

```
ln -s <repo>/GLOBAL.md ~/.claude/CLAUDE.md
ln -s <repo>/GLOBAL.md ~/.codex/AGENTS.md
```

Write it from the agent's point of view, agent-neutral like skills.

## Skill template

`skills/<kebab-name>/SKILL.md`:

```markdown
---
name: <kebab-name>
description: <what it does, and when to use it: concrete trigger phrases and situations>
---

# <Title>

<Short, imperative instructions. Link to references/ for detail.>
```

- Folder name equals frontmatter `name`; lowercase letters, digits, hyphens.
- Frontmatter is `name` and `description` only, so it stays portable across Claude, Codex and skills.sh.
- Keep the body short (under ~500 lines). Move detail into `references/<topic>.md`, linked directly from `SKILL.md`, never nested.
- Agent-neutral wording: no hard-coded Claude-only or Codex-only tool names, paths or slash commands. If behaviour must differ, say "if the agent supports X".
- Skills are instructions agents run with shell access; keep scripts minimal and readable.

## Checks after changes

- All JSON files parse.
- Every `skills/*/` has `SKILL.md` whose `name` equals the folder name.
