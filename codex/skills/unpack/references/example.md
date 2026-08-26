# Worked example — one topic, `decision` frame

Frame: `decision` (one of five; see `SKILL.md` `## Frames`).
Outcome line: *After this topic the reader can decide where duplicate deliveries are absorbed.*
Source material: a design discussion about consuming a payment provider's webhooks.
This is the second topic in its set. Topic 1 settled scope and closed by leaving one point
open: **we accept every delivery the provider sends, so something downstream must absorb them.**

Epistemic ladder in use: `[documented] [sample] [inferred] [measured] [unverified]`.

---

## Opening prose

> Topic 1 left us accepting every delivery the provider sends, with the absorbing left
> undecided. That is what we settle here — and the reason it is not trivial is **one fact**:
> the same webhook does not arrive exactly once.

Note what this does. It discharges the exact point topic 1 left open ("something must absorb
duplicates") rather than merely name-checking it, and it does so in the first claim. If this
topic could stand without topic 1, the link would be decorative.

## Beat 1 — problem (facts only, no judgment)

```
- b-1.) Problem
    - b-1-1.) The provider redelivers until it receives a 2xx
        - Retries follow an exponential schedule and continue for up to 3 days
            - [documented] provider webhook reference, "Retry schedule"
            - A handler that is slow but eventually succeeds still receives duplicates,
              because the retry was already in flight when the first attempt completed
            - [unverified] whether a 2xx sent after the client timeout stops the schedule;
              measure this before relying on it
        - Scale: a 30-minute handler outage yields 4-6 deliveries of the same event

    - b-1-2.) Deliveries are not ordered
        - [inferred] Ordering cannot hold given the retry schedule above
            - [documented] retries are scheduled independently per event
            - A retried event therefore lands after events created later
            - So out-of-order arrival is not an error path; it follows from the spec
        - [measured] Reproduced in staging: a refund landed before its charge
```

Four rules are visible here.

- **R6**: `b-1.) Problem` is a level of its own, not a facet sitting beside the judgment.
- **R5**: `b-1-1.)` and `b-1-2.)` read as complete conclusions. Everything under them is skippable.
- **R1**: IDs stop at three levels; detail beneath is unlabeled.
- Epistemic labeling: the ordering claim is *derived* from the documented retry schedule
  rather than asserted by citation. Delete every citation and the passage still explains.

An earlier draft of `b-1-1.)` said only "the provider retries". The expansion test rejected it:
the retry window is a **comparison value** for the outcome line — three days makes duplicate
absorption the central problem, one minute makes it a footnote — so it must be on the page.
The `[unverified]` sub-claim earns its place as a **failure condition**: if a late 2xx does not
stop the schedule, the chosen design has a hole.

## Pivot prose

> A design choice appears here. The obvious move is to reject duplicates at the edge, and
> it is the cheapest. **We are not going to do that.** A duplicate is not noise — it is the
> provider telling us it is unsure we received the first one, and discarding that signal
> removes the only evidence we have that a delivery was ever lost.

The prose carries what the outline cannot: why the cheap option is uncomfortable to give up.
If prose only restates the bullets that follow, delete the prose.

## Beat 2 — judgment

```
- b-2.) Judgment
    - b-2-1.) Options
        - x: drop duplicates at the edge by event id
            - Cheapest; one lookup per request
            - Gives up: any record that a redelivery happened, so lost deliveries stay invisible
        - y: make every handler idempotent
            - No shared state needed
            - Gives up: nothing directly, but the burden repeats in each new handler
        - z: write to a ledger with a conditional insert keyed by event id
            - Costs a store and a write path
            - Gains: duplicates are recorded rather than discarded, and ordering can be
              settled later against the stored timestamps

    - b-2-2.) Adopt the conditional-insert ledger (option z), because it is the only
              option that preserves the redelivery signal instead of discarding it
        - Cost: every handler now depends on the store being available
        - **Leaves open: the conditional insert needs a key, and we have not defined what
          makes two deliveries "the same event"** → topic c.) must discharge this
```

- **R4**: the reason rides on the claim line itself rather than hanging below it.
- **R5**: the claim names the adopted thing, so a reader who skips `b-2-1.) Options` still
  knows what was chosen. An earlier draft read only `Adopt z`, which forced a descent.
- **R7**: three options are listed because three genuinely existed.
- The closing names an unresolved obligation rather than summarizing, so topic c.) has a
  specific point to discharge (chain test).

---

## What the checks caught

- **Boundary test** moved "we will keep redeliveries" out of `b-1.)`, where an earlier draft
  had smuggled the decision into the problem statement.
- **Chain test** rewrote the opening prose: an earlier draft planted a fresh tension instead
  of discharging topic 1's open point, which reads as an independent topic no matter how the
  sentence is phrased.
- **Expansion test** rejected the original one-line "the provider retries", because the retry
  window changes the conclusion: three days makes this central, one minute makes it ignorable.
- Writing `b-1-2.)` at depth exposed that "deliveries are not ordered" had been asserted with
  no source. Deriving it from the documented retry schedule produced both a citation and a
  better explanation — and downgraded one sub-claim to `[unverified]`.

---

## Same shape, `debate` frame (compressed)

The closing rule is frame-neutral: name what the topic's **final beat** leaves unresolved.
For `debate` that is an open question, not a judgment — nothing has been decided.

```
- c-1.) Positions
    - c-1-1.) Platform wants one shared store; each team wants its own
- c-2.) Disagreement
    - c-2-1.) The two sides are not arguing about the same cost
        - Platform is pricing operational surface; teams are pricing coupling
- c-3.) Open questions
    - c-3-1.) Nobody has measured how often teams actually need independent schema changes
        - **Leaves open: without that number the disagreement cannot close** → topic d.)
```

Note what is absent: no option was adopted, and none was invented in order to close the
topic. Forcing this material into `decision` would have produced a conclusion nobody reached.
