# Issue Creation Guidelines

Guidance on when and how to create bd issues for maximum effectiveness.

## Contents

- [When to Ask First vs Create Directly](#when-to-ask)
- [Issue Quality](#quality)
- [Validation Frontiers](#validation-frontiers)
- [Making Issues Resumable](#resumable)
- [Design vs Acceptance Criteria](#design-vs-acceptance)

## When to Ask First vs Create Directly {#when-to-ask}

### Ask the user before creating when:
- Knowledge work with fuzzy boundaries
- Task scope is unclear
- Multiple valid approaches exist
- User's intent needs clarification

### Create directly when:
- Clear bug discovered during implementation
- Obvious follow-up work identified
- Technical debt with clear scope
- Dependency or blocker found

**Why ask first for knowledge work?** Task boundaries in strategic/research work are often unclear until discussed, whereas technical implementation tasks are usually well-defined. Discussion helps structure the work properly before creating issues, preventing poorly-scoped issues that need immediate revision.

## Issue Quality {#quality}

Use clear, specific titles and include sufficient context in descriptions to resume work later.

### Field Usage

**Use --design flag for:**
- Implementation approach decisions
- Architecture notes
- Trade-offs considered

**Use --acceptance flag for:**
- Definition of done
- Testing requirements
- Success metrics

## Validation Frontiers {#validation-frontiers}

When completion still depends on proof in a different environment, create that
proof as its own issue instead of silently assuming it will happen later.

### Create explicit follow-up issues for:
- Real-credential smoke tests
- External service delivery checks
- CI or scheduled-job validation runs
- Human/manual review cycles
- Any gap where mocked tests passed but production-like execution has not run

### Why this matters

Code-complete is not the same as task-complete. If acceptance says "verify in
the target system", "confirm in CI", or "run with real secrets", then the
remaining work is not implementation only. It is a separate validation frontier
that should stay visible in bd.

### Pattern

Create one issue per validation frontier and keep the parent open until those
issues close.

```bash
bd create "Run local smoke test with real credentials" --parent epic-1 \
  --acceptance "A local run succeeds against the target system and records the proof."

bd create "Validate end-to-end automation path in CI" --parent epic-1 \
  --acceptance "One CI run proves the end-to-end workflow or captures a concrete failure."
```

### Closure test

Before closing, ask:

1. Did we only prove this with mocks or dry runs?
2. Does acceptance still require a real environment, credential, or manual step?
3. If yes, is there an open bd issue tracking that remaining proof?

If question 1 or 2 is yes and question 3 is no, create the missing issue before
closing anything.

## Making Issues Resumable (Complex Technical Work) {#resumable}

For complex technical features spanning multiple sessions, enhance notes field with implementation details.

### Optional but valuable for technical work:
- Working API query code (tested, with response structure)
- Sample API responses showing actual data
- Desired output format examples (show, don't describe)
- Research context (why this approach, what was discovered)

### Example pattern:

```markdown
bd update issue-9 --notes "IMPLEMENTATION GUIDE:
WORKING CODE: service.about().get(fields='importFormats')
Returns: dict with 49 entries like {'text/markdown': [...]}
OUTPUT FORMAT: # Drive Import Formats (markdown with categorized list)
CONTEXT: text/markdown support added July 2024, not in static docs"
```

**When to add:** Multi-session technical features with APIs or specific formats. Skip for simple tasks.

**For detailed patterns and examples, read:** [RESUMABILITY.md](RESUMABILITY.md)

## Design vs Acceptance Criteria (Critical Distinction) {#design-vs-acceptance}

Common mistake: Putting implementation details in acceptance criteria. Here's the difference:

### DESIGN field (HOW to build it):
- "Use two-phase batchUpdate approach: insert text first, then apply formatting"
- "Parse with regex to find * and _ markers"
- "Use JWT tokens with 1-hour expiry"
- Trade-offs: "Chose batchUpdate over streaming API for atomicity"

### ACCEPTANCE CRITERIA (WHAT SUCCESS LOOKS LIKE):
- "Bold and italic markdown formatting renders correctly in the Doc"
- "Solution accepts markdown input and creates Doc with specified title"
- "Returns doc_id and webViewLink to caller"
- "User tokens persist across sessions and refresh automatically"

### Why this matters:
- Design can change during implementation (e.g., use library instead of regex)
- Acceptance criteria should remain stable across sessions
- Criteria should be **outcome-focused** ("what must be true?") not **step-focused** ("do these steps")
- Each criterion should be **verifiable** - you can definitively say yes/no

### The pitfall

Writing criteria like "- [ ] Use batchUpdate approach" locks you into one implementation.

Better: "- [ ] Formatting is applied atomically (all at once or not at all)" - allows flexible implementation.

### Test yourself

If you rewrote the solution using a different approach, would the acceptance criteria still apply? If not, they're design notes, not criteria.

### Example of correct structure

✅ **Design field:**
```
Two-phase Docs API approach:
1. Parse markdown to positions
2. Create doc + insert text in one call
3. Apply formatting in second call
Rationale: Atomic operations, easier to debug formatting separately
```

✅ **Acceptance criteria:**
```
- [ ] Markdown formatting renders in Doc (bold, italic, headings)
- [ ] Lists preserve order and nesting
- [ ] Links are clickable
- [ ] Large documents (>50KB) process without timeout
```

❌ **Wrong (design masquerading as criteria):**
```
- [ ] Use two-phase batchUpdate approach
- [ ] Apply formatting in second batchUpdate call
```

## Quick Reference

**Creating good issues:**

1. **Title**: Clear, specific, action-oriented
2. **Description**: Problem statement, context, why it matters
3. **Design**: Approach, architecture, trade-offs (can change)
4. **Acceptance**: Outcomes, success criteria (should be stable)
5. **Notes**: Implementation details, session handoffs (evolves over time)

**Common mistakes:**

- Vague titles: "Fix bug" → "Fix: auth token expires before refresh"
- Implementation in acceptance: "Use JWT" → "Auth tokens persist across sessions"
- Missing context: "Update database" → "Update database: add user_last_login for session analytics"
