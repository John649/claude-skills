# claude-skills

Personal Claude Code skills. Install by copying a skill's folder (or loose `.md` file) into `~/.claude/skills/`.

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
