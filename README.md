# claude-skills

Personal Claude Code skills. Each skill is a folder with a `SKILL.md` (plus any scripts it needs) or a single loose `.md` file.

## Installation

Clone and copy everything into Claude Code's skills directory:

```bash
git clone https://github.com/John649/claude-skills.git
mkdir -p ~/.claude/skills
cp -r claude-skills/roblox-upload claude-skills/roblox-asset-transfer \
      claude-skills/install-workflows claude-skills/debuzz \
      claude-skills/gamepass.md claude-skills/product.md ~/.claude/skills/
```

Or install just one skill by copying only its folder (or `.md` file). New skills are picked up on the next Claude Code session — invoke with `/<name>` or just describe the task.

### Per-skill prerequisites

- **roblox-upload / gamepass / product** — a Roblox Open Cloud API key in `~/.claude/skills/roblox-upload/config.env` (the skill walks you through creating it on first run; needs the assets + developer-products + game-passes API systems). Requires `bash` and `curl`.
- **roblox-asset-transfer** — Python, plus two Studio places connected to the Roblox Studio MCP.
- **install-workflows** — `gh` CLI authenticated with access to `John649/agenticodingworkflows`.
- **debuzz** — the Antigravity CLI (`agy`) installed and signed in (run `agy` interactively once).

## Skills

| Skill | What it does |
| --- | --- |
| [roblox-upload](roblox-upload/SKILL.md) | Upload local audio/image/model files to Roblox via the Open Cloud Assets API and get back the rbxassetid; also create/list dev products and game passes for a universe. |
| [roblox-asset-transfer](roblox-asset-transfer/SKILL.md) | Transfer live instances between two open Roblox Studio places via SerializationService and a local HTTP relay. |
| [gamepass](gamepass.md) | `/gamepass` — create or edit a game pass via Open Cloud and keep the codebase's id constants in sync. |
| [product](product.md) | `/product` — create or edit a developer product via Open Cloud and keep the codebase's id constants in sync. |
| [install-workflows](install-workflows/SKILL.md) | Install the agentic coding workflow docs from `John649/agenticodingworkflows` into the current project. |
| [debuzz](debuzz/SKILL.md) | `/debuzz [colleague\|manager\|director]` — rerun a reply through the Antigravity CLI (`agy`) for a plain-English version. |

## Secrets

`roblox-upload` reads its Open Cloud API key from a `config.env` next to its scripts. That file is gitignored — never commit it; each machine creates its own (see the skill's Setup section).

## Sync note

The live copies run from `~/.claude/skills/` on each machine; this repo is the backup/distribution point. After editing a skill locally, copy it here and push.
