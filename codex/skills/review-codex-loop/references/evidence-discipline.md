# Evidence discipline: an empty result is not evidence of absence

**Invariant.** A query that returns nothing means "nothing is there" only after you have shown the
query *could have* returned the answer. Until then it means "I asked badly", and those two are
indistinguishable from the output alone.

This is the failure class behind the false approval this loop once reported: the query succeeded,
exited 0, printed `0`, and the agent read `0` as a fact about the world instead of a fact about the
query. There is no error to notice, no warning to heed, and the wrong answer arrives in exactly the
shape the right answer would have.

## Why it survives ordinary care

Three properties make it slip past agents that are otherwise being careful:

1. **The silent answer is the *plausible* answer.** "No new findings" is what you expect when things
   are going well, so it never triggers a second look. A crash would.
2. **Truncation preferentially hides the newest rows.** Most list APIs page oldest-first. The item
   you are actually asking about — the review you just triggered, the alert that just fired — is the
   one most likely to be off the end. The failure rate is *not* uniform; it concentrates exactly on
   the queries that matter.
3. **It gets worse silently over time.** Under 30 items the unpaginated query is correct. Past 30 it
   is structurally, permanently wrong, with no transition event. Code that was verified once stays
   "verified" long after it stopped being true.

## The gate

Before an empty or small result is allowed to become a conclusion, prove all four:

- **Surface** — is the fact even recorded on the endpoint/index I queried? (Codex approval is an
  *issue comment*, not a review object. Polling `reviews` alone finds nothing, forever.)
- **Field** — is the attribute named what I typed? (`status` vs `@http.status_code`.) A wrong field
  name is not an error in most query languages; it is a filter that matches nothing.
- **Filter** — does every term I added actually apply to the rows I want? Each added term can only
  shrink the result. A term the data does not carry (`env:production` on a service with no `env`
  tag) zeroes it out.
- **Completeness** — could the result be truncated? Paging, `first:`/`limit:` caps, time windows,
  index lag, sampling. Show the boundary was not hit — don't assume it wasn't.

**Falsify before concluding.** The cheapest proof is a control query: drop the narrowing terms, or
widen the window, and confirm the count moves. A filter that yields 0 while its unfiltered form
yields 200,000 has told you about the filter, not about the system.

## The escalation rule (the part that actually failed)

**Use the strongest available instrument at the decision point, not the most convenient one.**

Knowing about a footgun does not protect you from it. In the incident below the agent had already
been using the truncation-immune GraphQL surface correctly earlier in the same session, then reached
for a cheap unpaginated REST count *at the single moment the answer was load-bearing* — the approval
verdict. Convenience wins by default under momentum; the decision point is where it costs most.

So: when a verdict (approve / no-issues / all-clear / safe-to-proceed) depends on a query, name the
strongest signal available for that question and use it, even if a weaker one was adequate for
routine polling. Prefer, in order:

1. A field that **directly states** the property (`isResolved`) over a **proxy** you infer it from
   (a comment count on the newest review).
2. A surface with **no truncation** over one you must remember to paginate.
3. A query whose **empty case you have deliberately tested** over one you have only reasoned about.

And prefer *any* of those over "it returned 0 and 0 is what I hoped for".

## Worked examples

Three instances from one session, three different tools, one shape.

| Instrument | Wrong query | Reported | Truth |
|---|---|---|---|
| `gh api` REST list | no `--paginate` → page 1 of 30, oldest-first | **0** inline comments on the newest review | **1** |
| Datadog logs | `status:` (wrong field for HTTP status) | **0** 5xx during a live incident | **12,597** |
| Datadog logs | `service:rproxy2 env:production` (service carries no `env` tag) | **0** | **208,987** |

Provenance: the `gh` row was re-measured against `oishi-kenko/healthcare-infra` PR 1615 on
2026-09-02 while writing this file (42 inline comments total, 30 on page 1; `[.[].id]|max` reads
`3894402652` unpaginated vs `3900751086` paginated). The two Datadog rows are recorded as observed
in-session and were not independently re-run here.

Note what the middle column has in common: every wrong query returned `0` **successfully**. Not one
of them raised an error, and each `0` was consistent with a reassuring story ("no findings", "no
errors", "service is healthy").

## Recipes

- **`gh api` REST list** — always `--paginate`. It merges all pages into one array *before* `--jq`,
  so `[.[].id]|max` / `length` / `max_by` stay correct. `--slurp` is incompatible with `--jq`.
- **`gh api graphql`** — `--paginate` needs an `$endCursor:String` variable and
  `pageInfo{ hasNextPage endCursor }`, and applies `--jq` **once per page**. Aggregating jq is wrong
  here: emit one line per node and count in the shell (`| wc -l`). A bare `first:N` with no cursor
  is a cap — read `hasNextPage` and treat `true` as "incomplete", never as a count.
- **Log/metric search** — confirm the field name against a real matching document before trusting a
  filter on it, and confirm every tag you AND together exists on the target service. Run the query
  once with the narrowing terms removed as a control.
- **Any surface** — if the answer is going to gate a decision, run the control query too. One extra
  call is cheaper than a wrong all-clear.
