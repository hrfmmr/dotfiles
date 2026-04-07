---
name: ms
description: Create, update, or refactor Codex skills, including `SKILL.md` plus `scripts/`, `references/`, and `assets/` when justified. Use when defining a new skill, tightening triggers or metadata, restructuring skill resources, or validating a skill change before shipping it.
---

# ms

## Overview

Create or revise Codex skills with the smallest defensible diff.
Keep the implementation self-contained inside the skill directory, avoid external registries, and preserve a lean operational surface.

## Hard Constraints

- Minimal diff: change only what is required to satisfy the request.
- No auxiliary docs: do not add `README`, `INSTALL`, or `CHANGELOG` style files.
- Frontmatter:
  - Default to `name` and `description` only.
  - When updating a system skill, preserve any already-allowed keys such as `metadata`, `license`, or `allowed-tools`.
  - Keep `name` hyphenated, within 64 characters, and identical to the folder name.
  - Treat `description` as the trigger surface. Include "when to use" cues, avoid square brackets, and stay within 1024 characters.
- `SKILL.md` body:
  - Write in the imperative.
  - Stay within 500 lines; move detail into `references/` when necessary.
  - Keep trigger language out of the body; put it in frontmatter `description`.
- Always run `quick_validate.py` before finishing.
  - Recommended without a global install:
    - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <path/to/skill>`
  - Note: the `skill-creator` scripts require PyYAML (`import yaml`).

## Workflow Decision Tree

- If the target skill already exists, use the Update Workflow.
- If no relevant skill exists, use the Create Workflow.
- If the name, location, or trigger surface is unclear, ask 1-3 focused questions before proceeding.

## Create Workflow

1. De-duplicate. Search for an existing skill that already covers the intent; prefer extending a near match over creating a redundant skill.
2. Discover and define. Collect 2-3 concrete user prompts and derive:
   - a one-line problem statement
   - success criteria that make completion testable
3. Plan reusable assets. Decide whether `scripts/`, `references/`, or `assets/` are actually needed and create only the minimum set.
4. Initialize the scaffold:
   - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/init_skill.py <skill-name> --path ~/.codex/skills`
   - Add `--resources scripts,references,assets` only when those directories are justified.
   - Add `--interface key=value` only when immediate UI metadata is required; repeat as needed.
5. Write `SKILL.md`:
   - Put concrete triggers in frontmatter `description`, including file types, tools, tasks, or key phrases when useful.
   - Center the body on procedures, decision logic, and routes into `references/`.
6. Validate:
   - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/<skill-name>`
7. Iterate with the user. Tighten triggers, remove overlap, and promote reusable logic into `scripts/` when repetition becomes real.

## Update Workflow (In Place)

1. Locate the target skill under `~/.codex/skills`, or under `~/.codex/skills/.system` for system skills.
2. Read the current `SKILL.md` and any skill-local resources, then isolate the minimum necessary change.
3. Edit in place:
   - Update frontmatter `description` if the trigger surface changes.
   - Adjust workflow steps, tasks, and references with a minimal diff; avoid formatting-only churn.
   - Add or remove resource directories only when they create actual reuse.
4. Validate with:
   - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <path/to/skill>`
5. Summarize the delta and the next step.

## Trigger Examples

- "Create a skill that manages an OpenAPI spec and generates SDKs."
- "Refactor this skill's `SKILL.md` and add a schema under `references/`."
- "Keep `SKILL.md` under 500 lines and move the detail into `references/`."
