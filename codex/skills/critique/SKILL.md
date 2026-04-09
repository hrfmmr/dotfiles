---
name: critique
description: "Multi-agent constructive review of non-code artifacts (plans, snapshots, designs, ADRs). Dynamically determines review lanes from artifact content, fans out parallel sub-agent reviews, and returns unified severity-ranked findings for iterative refinement. Use when user says '$critique', 'critique this', 'multi-agent review', 'plan review', or wants structured feedback on a working artifact before implementation."
---

# Critique

## Intent

Run parallel multi-perspective reviews against a working artifact and return unified, severity-ranked findings for iterative refinement. Unlike `$review` (merge gate with approve/reject), critique is constructive: it surfaces blind spots and design risks to improve the artifact, not to block it.

## Invocation

| pattern | behavior |
|---------|----------|
| `$critique` | Review the current working artifact in context (inferred from conversation) |
| `$critique <path>` | Review the artifact at the given file path |
| `$critique --lanes "infra,scripts,security"` | Override auto-detected lanes with explicit list |

## Execution Flow

### 1. Resolve Target Artifact

Determine what to review:
- If a file path is given, read it.
- If invoked within a desk-live session, use the task note's Plan/Snapshot section.
- If neither, scan conversation context for the most recent substantial artifact (plan, design doc, snapshot).
- Fail with a clear message if no reviewable artifact is found.

### 2. Determine Review Lanes

Read the artifact and automatically derive 2-4 review lanes based on its content. Each lane is a distinct expert perspective.

Lane derivation rules:
- Identify the major technical domains in the artifact (e.g., infrastructure, application code, deployment, security, data model).
- Assign one lane per domain. Aim for 3 lanes; use 2 for simple artifacts, 4 for complex ones.
- Each lane gets a short name (e.g., `terraform-infra`, `deploy-scripts`, `e2e-integration`) and a one-line scope description.
- If the user provided `--lanes`, use those instead of auto-detection.

Present the lanes to the user before launching:
```
Critique lanes:
1. terraform-infra — AWS resource design, provider config, state management
2. deploy-scripts — Shell script correctness, safety, portability
3. e2e-integration — Cross-step dependencies, verification gaps, workflow
Proceeding with review...
```

### 3. Fan Out Lane Reviews

Launch one Agent per lane in parallel. Each agent receives:
- The full artifact text
- Its lane name and scope description
- The review prompt (see Lane Review Prompt below)

Agents are research-only: they must not modify files.

### 4. Aggregate Findings

After all lanes complete:
1. Normalize findings into the required schema.
2. Deduplicate materially identical findings across lanes. Keep the highest severity.
3. Sort by severity: `HIGH > MEDIUM > LOW`.
4. Produce a unified summary.

### 5. Return Output

Return the findings to the caller context. Do not write to files or post comments. The caller (desk-live, user, etc.) decides how to persist.

## Lane Review Prompt

Each lane agent receives this prompt template:

```
Review-only task (do NOT write code or edit files).

You are reviewing as a {lane_name} expert. Scope: {lane_scope}.

Read the artifact below and identify issues from your lane's perspective.
Challenge assumptions, question design choices, surface edge cases and failure modes.
Be constructive: explain WHY something is a problem and WHAT would improve it.

For each finding, provide:
- severity: HIGH (must fix before proceeding), MEDIUM (should fix, risk if ignored), LOW (nice to have)
- subject: short label (e.g., "S3 sync --delete ordering")
- issue: what is wrong or risky
- recommendation: specific actionable improvement

Artifact:
---
{artifact_content}
---

Return structured findings. It is valid to return zero findings if your perspective is clean.
```

## Output Contract

```yaml
lanes:
  - name: "terraform-infra"
    findings: [...]
    summary: "1-3 lines"
unified_findings:
  - severity: HIGH|MEDIUM|LOW
    lane: "source lane"
    subject: "short label"
    issue: "what is wrong"
    recommendation: "what to do"
summary: "1-5 line cross-lane synthesis"
stats:
  high: N
  medium: N
  low: N
```

Output rules:
- No `decision` field (this is not a gate).
- Findings are for human consumption and iterative refinement.
- Caller owns persistence (Turn-N, bd comment, etc.).

## Iterative Loop

Critique supports review-fix-review cycles:
1. First `$critique` produces findings.
2. Caller fixes the artifact based on findings.
3. Second `$critique` re-reviews. Agents see the updated artifact and should acknowledge resolved issues.
4. Repeat until findings stabilize.

On re-review, prefix the lane prompt with:
```
Previous review found these HIGH findings: {list}
Check whether they have been addressed. Flag any that remain unresolved.
Also look for new issues introduced by the fixes.
```

## Guardrails

- Agents must not modify files, apply patches, or post comments.
- Only the orchestrator aggregates and returns findings.
- If a lane agent fails, retry once. If still failing, continue without that lane and note the gap in the summary.
- Do not fabricate findings. If a lane has nothing to report, return zero findings.
- Keep lane count between 2 and 4. More lanes produce diminishing returns and waste context.

## Relationship to Other Skills

| Skill | Purpose | Difference |
|-------|---------|------------|
| `$review` | Code/PR merge gate | Formal approve/reject, code-focused fixed lanes, PR inline comments |
| `$critique` | Artifact refinement | Constructive, dynamic lanes, no gate decision, non-code artifacts |
| `$grill-me` | Requirements clarification | Interactive Q&A before artifact exists; critique reviews after artifact is written |
| `$creative-problem-solver` | Option generation | Generates alternatives; critique evaluates a chosen approach |
