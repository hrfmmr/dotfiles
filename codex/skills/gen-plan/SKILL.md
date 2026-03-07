---
name: gen-plan
description: Create or update one plan from an explicit Markdown path, a GitHub issue, or `$PLAN_DIR/{sanitized-branch-name}.md`. For GitHub issues, use `.plans/gh-number.md` and mirror the latest plan back with `gh issue comment`. Use only when plan generation or revision is requested. Confirm before first-time file creation.
---

# Gen-Plan

## Contract

- Handle exactly one plan file per run.
- Resolve the target in this order:
  1. If the user gives a Markdown file path, use that path as the `target plan file`.
  2. If the user gives a GitHub issue number or URL, use that issue as the source and `.plans/gh-<number>.md` as the `target plan file`.
  3. Otherwise use `$PLAN_DIR/<git-branch-name>.md` as the `target plan file`.
- When using an explicit Markdown path or GitHub issue, do not require `$PLAN_DIR`.
- Accept an explicit path only if it is clearly a `.md` file path. If not, stop and confirm.
- Accept a GitHub issue only if the number or URL is unambiguous. If not, stop and confirm.
- In fallback mode only:
  - Name the file `<git-branch-name>.md`; never create `plan.md` or `PLAN.md`.
  - Get the branch with `git rev-parse --abbrev-ref HEAD` and replace `/` with `--`.
  - Stop and confirm if `HEAD` is detached.
  - Stop and confirm if `$PLAN_DIR` is unset or does not exist.
- For a GitHub issue source:
  - Read the issue with `gh issue view <number> --json number,title,body,url`.
  - Treat the issue body as draft plan Markdown.
  - Create `.plans` if needed.
  - If `.plans/gh-<number>.md` already exists, update that local plan and use the issue body only as upstream context unless the user explicitly asks to reseed from the issue.
- If the `target plan file` does not exist, enter clarification flow, then create it.
- If the `target plan file` exists, update that same file in place.
- When loading the source plan, replace `<INCLUDE CONTENTS OF PLAN FILE>` with the source contents verbatim.
- If a GitHub issue target has no local plan yet, seed the first plan from the issue body and save it to `.plans/gh-<number>.md`.
- After updating a GitHub issue plan, post the saved file with `gh issue comment <number> --body-file .plans/gh-<number>.md`.
- Ask questions only when needed to unblock a decision.

## Clarification Flow

- Investigate first. Ask only the questions required to proceed.
- Use a `GRILL ME: HUMAN INPUT REQUIRED` block with numbered questions.
- Do not ask a repo or issue-number question if `gh` can already resolve them from the provided issue URL.
- After answers arrive, continue asking only if a real ambiguity remains; otherwise create or update the `target plan file`.

## Source Preparation

- For an explicit Markdown path, read that file as the source plan.
- For a GitHub issue:
  - Fetch the issue body first.
  - If no local plan exists yet, use the issue body as the source plan.
  - If a local plan already exists, use the local plan as the source plan unless the user explicitly requests reseeding from the issue.
  - Save the generated or updated result to `.plans/gh-<number>.md` before any comment sync step.
- In fallback mode, read `$PLAN_DIR/<git-branch-name>.md` as the source plan.

## Plan Update

Use the prompt template below as internal guidance when creating or revising the `target plan file`.

Output rules:
- Write only the answer to the prompt into the plan file. Never include the prompt itself.
- Write normal Markdown. Do not prefix lines with `>`.
- Insert the source plan verbatim, without quoting, indentation, or code fences.
- Every proposed change must include at least one plan-level pseudocode diff.
- Keep pseudocode diffs at the planning level; do not turn them into implementation code.
- For a GitHub issue workflow, the comment body must exactly match the saved `.plans/gh-<number>.md` contents.
- If GitHub write operations are disallowed, stop after presenting the exact post command. Do not silently skip the write step.

### Prompt Template

Review the entire plan carefully and propose the strongest revision you can, including architecture improvements, new features, and behavior changes that make the project more robust, reliable, performant, useful, and compelling.

For each proposed change, explain in detail why it improves the project, provide a git-diff-style change against the original Markdown plan below, and include at least one plan-level pseudocode diff:

<INCLUDE CONTENTS OF PLAN FILE>
