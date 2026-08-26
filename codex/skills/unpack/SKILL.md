---
name: unpack
description: >
  Structure information about a topic into an ID-anchored nested bullet outline,
  with prose placed at the pivot between beats, so a reader builds understanding
  one topic at a time instead of absorbing everything at once.
  Use when the user says "unpack", asks to structure, organize, or break down a topic,
  wants a design plan, report, investigation, runbook, or discussion log reorganized
  so it can be read top-down, wants stable ID anchors so an agent and a human can
  point at the same node, or when an explanation is too dense and understanding
  does not accumulate.
  Works from scratch (topic plus sources) or by restructuring an existing document.
  Medium-agnostic, emitting text that other skills place into review comments, notes, or files.
---
# unpack

## Overview

Turn material about a topic into a structure a reader can climb.
Emit text only. Let the caller decide where it lands.

Optimize for accumulation, not for lookup. A reference layout (background, overview, key points, details) serves someone who already understands the subject. A reader meeting it for the first time needs one thread that keeps its tension.

Write the output in the language of the source material.

## Outcome line

Before drafting a topic, write one sentence naming what the reader can do once it lands:

```
After this topic the reader can <verb> <object>.
```

Write it into the output, not just into your reasoning. It is the anchor for two decisions that are otherwise undecidable without a reader in the room: which frame to use, and which claims to expand.

When a human is available, confirm the outcome line with a single question before drafting. When none is, derive it from the material and state it explicitly so it can be challenged rather than silently assumed.

## Frames

Deliver a topic as **beats**. Pick the frame from the verb in the outcome line. Choose one frame per topic; a set may mix frames.

| Frame | Beats | Outcome-line verb |
|---|---|---|
| **decision** | problem → judgment | decide, choose, justify |
| **mechanism** | behavior → cause | predict, explain, diagnose |
| **inquiry** | question → observation → interpretation | judge how sure, weigh evidence |
| **procedure** | preconditions → steps → pitfalls | perform, operate, recover |
| **debate** | positions → disagreement → open questions | state what is contested and why |

Use `debate` when nothing is settled yet: a discussion log of conflicting positions has no judgment to report, no cause to explain, and no observation to interpret. Forcing it into `decision` fabricates a conclusion nobody reached; forcing it into `inquiry` promotes advocacy to evidence.

The same material yields different frames for different readers — a connection-pool document is `mechanism` for a user and `decision` for a reviewer. That is why the frame follows the outcome line and not the document's genre.

State the chosen frame once at the top of the output, so the reader knows the shape before the first topic.

## Set shape

Before the rules apply, decide what shape the whole set has. Declare it at the top of the output.

| Shape | When | Consequence |
|---|---|---|
| **chained** (default) | each topic's final beat creates the next topic's opening question | every chaining rule below applies |
| **parallel** | the topics are settled facts with no causal order between them, such as a comparison of configuration options | the chaining rules are suspended for the set |

Rules scoped to shape — everything else applies to both:

| Rule | chained | parallel |
|---|---|---|
| Close by naming what is left unresolved | required | **suspended**: close with the settled conclusion itself |
| Next topic discharges that point | required | not applicable |
| Make the chain visible | required | not applicable; the set is stated as parallel instead |
| Chain test | run | skip, but run the **Parallel-honesty test** |
| First-sentence test | first sentences read as one argument | first sentences read as a list of distinct settled facts |

Do not choose `parallel` to avoid work. Finding the tension between topics is the labor this method
exists to force; declaring `parallel` skips it. The Parallel-honesty test exists because the
declaration is otherwise unfalsifiable self-assessment.

## Output shape

Alternate prose and outline within each topic. Prose carries transitions and the weight of the turn; the outline carries the content.

```
opening prose        what the previous topic handed over
  beat 1 (outline)   the frame's first beat
pivot prose          announce the turn to the next beat
  beat 2 (outline)   the frame's second beat
```

In a **chained** set, close every topic by naming **what it leaves unresolved** — a constraint, an obligation, or a question that the topic's final beat just created. Never close with "does that make sense?", which cannot be answered honestly, and never with a self-contained summary, which ends the thread. In a **parallel** set this requirement is suspended: close with the settled conclusion itself, because there is no next topic obliged to discharge anything.

The next topic must then **discharge that specific open point** in its first claim. A closing consequence that no later topic discharges is decoration; an opening that only name-checks the previous topic ("given that we need encryption, now let us look at deployment") satisfies the letter and drops the tension. The test is whether topic N+1 could stand alone without topic N. If it could, the chain is not real.

The first topic is the exception: its opening prose states how to read the whole set, then creates the tension the rest resolves.

Make the prose carry at least one thing the outline cannot — usually what was given up, or why the turn is uncomfortable. If the prose only restates the bullets, delete the prose.

## Structural rules

- **R1 Depth.** Give IDs at most three levels: `a.)`, `a-1.)`, `a-1-1.)`. Leave deeper content unlabeled. Wanting a fourth level means the topic should be split.
- **R2 Freeze.** Never renumber a published ID. Append (`a-1-1a.)`) instead. Non-contiguous but stable beats contiguous but drifting; a renumber invalidates every reference already made in conversation. Before assigning IDs to a revision, read the previously published output to learn which IDs are already spoken for; if it cannot be recovered, say so and start a new namespace rather than silently reusing one.
- **R2a Namespace per read.** When a set spans linked reads, prefix every ID with the read (`A-a.)`, `B-a.)`). Reusing `a.)` in each read breaks the promise that an ID points at one node.
- **R3 Siblings are peers.** Never flatten a chain of reasoning into sibling bullets. Items joined by therefore, however, or as a result belong in a parent-child relation or in a connective node.
- **R4 Connective nodes carry content.** Write `a-2.) Because: <the actual reason>`. A node that exists only to hold children is an indentation tax; collapse it.
- **R5 Claim lines stand alone.** Write each claim line as a complete conclusion. Nested detail answers "why may I believe this" and must be skippable. If a claim is unintelligible without its children, the reader must read everything and volume becomes cost.
- **R6 Beats are levels, not facets.** Keep each beat as its own parent node. Flattening beats into sibling facets erases the boundary a reader most needs: whether they are still taking in the world, or already being told what it means.
- **R7 Slots are not a form.** Treat only the chosen frame's beats as mandatory. Add sub-slots (options, alternatives, counter-examples) only when they genuinely exist; inventing "option B is obviously wrong" is padding.

## Expansion test

Expand a claim if and only if it supplies one of three things for the topic's **outcome line**: a premise the outcome depends on, a comparison value that sets its magnitude, or a failure condition that bounds it. Otherwise leave it as one line.

Name which of the three it supplies; that naming is the check. A claim that supplies none of them is background, however interesting.

Prefer magnitude and consequence over mechanism. A thin bullet fails not because it is short but because "so what" cannot be derived from it.

- weak: "the cache expires periodically"
- strong: "the cache expires every 60s, so an upstream outage is served stale for at most a minute"

## Epistemic labeling

Label any claim a reader may reasonably doubt with how it is known. Choose a ladder that fits the material and state it once at the top. An example ladder, for claims about tool or vendor behavior:

```
[documented]  stated explicitly in official documentation
[sample]      readable from an official example or payload
[inferred]    derived from documented behavior; the conclusion itself is not stated
[measured]    observed or reproduced directly
[unverified]  not yet checked; scheduled for a named checkpoint
```

Other material needs other ladders: primary / secondary / hearsay for literature; code-verified / comment-claimed / assumed for a codebase walkthrough. What is invariant is that a ladder exists and every doubtable claim sits on it.

- Put the explanation first. Let a citation support one specific sentence, placed after it.
- Never let a citation replace an explanation.
- **Source-deletion test**: remove every citation. If the passage no longer explains, rewrite it.
- Treat the tier as more important than the source, because it tells the reader where to aim doubt. Labeling an inference as documented fact is worse than citing nothing.

## Topic budget

Keep five to eight topics per read. Density per topic rises under this method, so total volume does not shrink and an unbudgeted set reproduces the problem.

The cap bounds one read, not the material. When more distinct topics exist, split into **linked reads** rather than merging. Never merge topics that carry different outcome lines or different frames: a single topic holding two conclusions destroys the per-topic "understood / want to ask" decision, which is the change that made this method work in the first place.

Five is a ceiling on splitting, not a floor to reach. When the material holds fewer than five genuinely distinct topics, stop at that number and say so. Manufacturing topics to fill a budget is the same failure as manufacturing options to fill a slot (R7).

Some material is genuinely **parallel** (see Set shape): settled facts with no causal order between them. Do not invent dependencies to satisfy the chain. Fabricating a dependency is worse than admitting there is none — but declaring `parallel` without earning it is worse still, which is what the Parallel-honesty test checks.

In a chained set, make the chain visible: when the final beat of topic N creates topic N+1's opening question, say so in N's closing consequence and again in N+1's opening prose. A chain that is only implicit reads as unrelated topics. This does not apply to a parallel set, where reading as unrelated topics is the correct and declared shape.

## Workflow

1. Collect the material: conversation, document, repository, or all three.
2. Do not inherit the source document's section order. It is usually reference-shaped and will reproduce the disease.
3. Derive topics by **tension**, not by dependency. Dependency order answers "what references what"; comprehension order answers "what question does this raise that the next one answers". They are different orders.
4. Write each topic's outcome line in one sentence. Confirm it with the human when one is available.
5. Choose a frame per topic from that line's verb, and name the frame in the output.
6. Order topics so zoom level moves monotonically. Do not oscillate between product level, system level, and detail level.
7. Place the opening tension first: the single fact that makes the rest necessary.
8. Draft each topic as prose, outline, prose, outline.
9. Apply the expansion test per claim, then attach epistemic labels.
10. Run the checks below.

## Checks

Run all of these before delivering.

- **First-sentence test.** Read only the first sentence of each topic, in order. In a chained set it should read as one argument; if it reads as unrelated headlines, the thread was never woven. In a parallel set it should read as a list of distinct settled facts; if one sentence depends on another, the set is not parallel.
- **Skip test.** Read only claim lines, ignoring nested detail. The argument must still stand (R5).
- **Source-deletion test.** See Epistemic labeling.
- **Boundary test.** Look for content from a later beat sitting inside an earlier one: an interpretation inside the observation, a decision inside the problem. Move it; deciding inside the description hides the choice.
- **Depth test.** Any ID at four levels means split the topic (R1).
- **Chain test.** For each adjacent pair, check that topic N names an unresolved point and topic N+1's first claim discharges *that* point. Ask whether N+1 could stand alone without N; if it could, the link is decorative. **Read boundaries are adjacent pairs too**: the last topic of read N and the first topic of read N+1 are checked exactly like any pair inside a read. Skip this test only for a set declared parallel, and only after the Parallel-honesty test passes.
- **Parallel-honesty test.** Run this whenever a set is declared parallel. For each topic, check whether it supplies a premise, a comparison value, or a failure condition for any *other* topic's outcome line — the same three categories the Expansion test uses. If even one does, the topics are causally related, the declaration is void, and the set reverts to `chained`. A parallel declaration is otherwise unfalsifiable, and the shortcut it enables is exactly the one this method exists to prevent.
- **Outcome test.** Check that every topic states an outcome line, and that every expanded claim supplies a premise, a comparison value, or a failure condition for it.
- **Frame test.** Look for a beat that exists only because the frame demanded it. Empty slots mean the wrong frame was chosen (R7).

## Report imprecision

Expansion exposes the author's own vagueness: a claim that cannot be written at the required depth was never fully understood. Treat that as a finding and surface it rather than smoothing it over. Thin bullets hide imprecision, which is the main reason to expand them even when the reader would have accepted the short version.

## References

- `references/example.md` — one topic worked end to end in the `decision` frame, with epistemic labels applied.
