---
name: install-workflows
description: Install the user's agentic coding workflow docs (from the private GitHub repo John649/agenticodingworkflows) into the current project — copies docs/, merges the generic workflow guidance into AGENTS.md/CLAUDE.md without clobbering existing project content. Use when the user says "install my workflows", "add my coding workflow docs", or "/install-workflows".
---

# Install agentic coding workflows

Install the user's reusable coding-workflow guidance from `John649/agenticodingworkflows`
(private GitHub repo, fetch with `gh api`) into the current project.

## Source repo layout

- `CLAUDE.md` — thin pointer that imports `@AGENTS.md` (the repo copy references Ro Sync; adapt, don't copy verbatim).
- `AGENTS.md` — mix of **generic workflow guidance** (reusable) and **project-specific content for "zombieswithoutmap"** (do NOT install).
- `ARCHITECTURE.md` — entirely project-specific to the source repo. Never copy it; at most note the target project could have its own.
- `docs/README.md`, `docs/CODE_STYLE.md`, `docs/ROBLOX_ARCHITECTURE.md`, `docs/CODE_REVIEW_CHECKLIST.md` — generic references, copy verbatim.

## Steps

1. **Fetch fresh copies** (never use a cached/remembered version):
   ```bash
   gh api repos/John649/agenticodingworkflows/contents/AGENTS.md --jq '.content' | base64 -d > <scratchpad>/AGENTS.md
   gh api repos/John649/agenticodingworkflows/contents/docs/<file> --jq '.content' | base64 -d > <scratchpad>/docs/<file>
   ```
   Fetch all four docs files. If `gh` is unauthenticated or the repo is unreachable, stop and tell the user.

2. **Copy `docs/`** into the project root as `docs/` (create it; if files already exist there, overwrite only the four workflow files, leave everything else). If the project already uses `docs/` for something conflicting, use `docs/agent/` instead and fix the relative links in `docs/README.md`.
   - Roblox project → copy all four files. Non-Roblox project → skip `ROBLOX_ARCHITECTURE.md` and drop its mention from `README.md` and the AGENTS.md reference list.

3. **Extract only the generic sections from the fetched AGENTS.md**:
   - Keep: "Required engineering references" + the precedence list, "Think before coding", "Simplicity first", "Surgical changes", "Engineering quality", "Verification".
   - Skip: "Project overview", "Runtime architecture", everything between `<!-- ro-sync:codex-context:start -->` and its end marker, and any other content clearly about the source repo (zombieswithoutmap, Ro Sync, rosync commands, its place IDs).
   - Adapt the kept text where it names source-repo tooling: "Editing conventions" and "Verification" mention `.stylua.toml` / `rosync lint` / Ro Sync — rewrite those bullets to the target project's actual formatter/linter/test story (check what the project has), or generalize ("run the project's narrowest applicable lint/format check").
   - Fix the docs paths if you installed to `docs/agent/`.

4. **Merge into the target project** — never clobber:
   - **No AGENTS.md exists**: create it with a short header + the extracted sections.
   - **AGENTS.md exists**: append the extracted sections under a `## Engineering workflow` heading (or merge into an equivalent existing section). Do not duplicate sections that are already present from a previous install — update them in place instead.
   - **CLAUDE.md**: if none exists, create a minimal one that imports `@AGENTS.md` and points at the docs. If one exists and doesn't import AGENTS.md, add the `@AGENTS.md` import line and a one-line pointer to the docs; leave the rest untouched.

5. **Report**: list files created/updated, note anything skipped as project-specific, and remind the user the source of truth is the GitHub repo (re-run this skill to refresh).

## Rules

- Never overwrite existing project-specific instructions in CLAUDE.md/AGENTS.md.
- Never install the Ro Sync generated block or source-repo place IDs/paths.
- Re-running the skill must be idempotent: refresh the docs files and previously-installed sections, not append duplicates.
