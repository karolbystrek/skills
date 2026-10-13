# skills

The skills and hooks I use with Claude Code and Codex, installed per project so cloud sessions get them too.

| Package | Upstream |
|---|---|
| `mattpocock` | https://github.com/mattpocock/skills |
| `ponytail` (skills + hooks) | https://github.com/dietrichgebert/ponytail |
| `emilkowalski` | https://github.com/emilkowalski/skills |

## Install into a project

```bash
./install.sh ~/Projects/my-app ponytail mattpocock:tdd emilkowalski:animate
```

`package` installs all its skills, `package:skill` installs one. Commit the result in the project. Re-run to update.

After installing hooks, open `/hooks` in Codex once to trust them.

## Update to the newest upstream

```bash
./update.sh
```

Review `git diff` before committing, then re-run `install.sh` in each project.
