# Coverage review (Gate A)

Purpose: check that the map and topics cover the design's issue space without bias and without hidden premises, before any node is written. What is obvious to the writer is what gets dropped, so run this as a procedure, not as a feeling.

## When

1. After the first draft of the map, before writing nodes. Do not write nodes until it passes.
2. Whenever a map entry or a node is added, changed, or removed (diff mode).
3. Once more before the attainment check (final pass).

## Input

The purpose in one or two sentences including its success criteria; all sources (design document, upstream decision records, implementation steps); the map.

## Procedure

1. **Diverge from the purpose (top-down). Write this before looking at the map.** State the purpose in one sentence, apply every axis below, and write what issues would arise if the purpose were designed from a blank page. Write "not applicable (reason)" for empty axes.
2. **Build the decision inventory from the sources (bottom-up).** Do not stop at one design document. Include upstream decisions, rejected alternatives, facts, insights, the table of contents, implementation steps, and the source's own success criteria.
   - 2b. **Build the shared-object ledger.** List objects that several nodes read or write: data models and table definitions, event and API formats, configuration, state transitions. Assign each an introduction node (the first node that uses it) and decide what later nodes add.
3. **Merge and build a coverage table.** Rows: the union of 1 and 2. Columns: how the map treats each. Treatment is one of node / premise (one sentence, and where it is handled) / out of scope (with reason) / unclassified.
4. **Read the asymmetry.** An item in 1 but not 2 is a hole in the design or an obvious premise the sources never wrote down. An item in 2 but not 1 means an axis was overlooked; update the axis table.
5. **Verify candidates.** Search the sources before declaring a top-down candidate missing; it may already be handled under another section or name.
6. **Check bias** with the five types below.
7. **Look for hidden premises** with the four questions below, applied to every element of the overall picture and every term in a node. Mandatory for every element of the entry node's overall diagram.
8. **Fix.** Turn each unclassified row into a node, a stated premise, or an out-of-scope ledger entry with a reason. When dropping for budget, record what was dropped and why.
9. **Present** the coverage table, bias findings, and fixes before writing nodes. Decide classifications with native asks that carry recommendations.

## Axes (15; independent of the purpose)

| # | Axis | Question |
|---|---|---|
| 1 | Entry and trigger | What starts it, how? What are the entry options and why this one? |
| 2 | Identity and state | What counts as "the same thing"? What is remembered? |
| 3 | Concurrency, order, idempotency | What happens with simultaneity, duplicates, out-of-order events, retries? |
| 4 | Division of roles | Who does what? Who decides, writes, and causes external side effects? |
| 5 | External contracts | What was assumed about external systems' data formats, limits, availability, cost? |
| 6 | Permissions and trust boundary | What is disallowed, and how is that enforced? Where are secrets? |
| 7 | Failure and recovery | Partial failure, missing data, limit overruns: what happens? Where does a human step in? |
| 8 | Cost and limits | What drives cost or runaway? Where is it stopped? |
| 9 | Observation and evaluation | How do we know it works? How is result quality measured? |
| 10 | Verification and reproduction | How is it tried? How are anomalies reproduced? |
| 11 | Change and extension | What can be added later, and what must not be rebuilt when it is? |
| 12 | Build and operation | How is it built, placed, and updated (IaC, environments, artifacts, state storage)? |
| 13 | Technology choice | What is used and not used? How far does the option space go? |
| 14 | Users and deliverables | Who uses the output and how? Format, granularity, handling of errors? |
| 15 | Shape of data | What shape do the main stored or exchanged data have? Can it be shown as schema and example? Did the reader see it before it was used? |

## Bias types

- **Position**: where in the flow the map concentrates. Are the decisions that led to the structure (upstream) missing?
- **Hard-part bias**: are the nodes only the places that broke or caused disputes? Decisions that survived quietly must appear too.
- **Per axis**: count nodes per axis; an axis with none needs a reason.
- **Depth**: are several nodes piled on one topic while others get one line?
- **Taken for granted**: topics the writer felt were too obvious to write: things already running, the writer's home ground, elements of the entry diagram.

## Four hidden-premise questions (per element)

1. Why this one? What were the alternatives and why were they not chosen?
2. Without knowing it, which statements become unreadable?
3. Where is the answer: node, hook, or out-of-scope ledger? If nowhere, it is a hidden premise.
4. Did the reader see its shape (schema, example) before it was used? Design-specific shapes are shown in the body, never pushed to a hook or another note.

## Pass conditions

- No unclassified rows.
- Every axis has a matching item or "not applicable (reason)".
- Every element of the entry diagram has a destination.
- Every out-of-scope item has a reason.
- Every major shared object has an introduction node, and its identifiers have a shape shown by first use.
- Every teacher answer about flow, time, structure, state transitions, or comparison has a diagram right after it.

## Limits and reinforcement

The writer's review shares the writer's blind spots. Reinforce (unverified idea) by giving another agent only the purpose and the axis table and asking it to do step 1; compare its list with yours.

## Output

Coverage table (item, axis, source, treatment, bias finding) and the out-of-scope ledger, placed beside or at the end of the map. Also keep the shared-object ledger (object, source of shape, introduction node, later deltas).
