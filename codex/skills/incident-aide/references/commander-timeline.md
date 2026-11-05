# Incident commander standard, phase by phase

The standard that `check` and the drafts follow. It is generic: it covers system
outages, incidents that start from a customer report, and security incidents, and it
leaves type-specific procedures (technical mitigation, evidence handling, legal
notification) to their own runbooks.

## Contents

- Principles and priorities
- How the phases relate
- Phases 0–6: goal, actions, target state, checkpoints
- Always-on checkpoints
- Trade-offs
- Templates
- Sources

## Principles and priorities

The standard adopts three principles that most of the source models share:

1. One person decides. Who the commander is right now is always known, and each
   responder takes direction from one person (ICS unity of command). When several
   organizations respond together and no single one can decide alone, use a joint
   command like ICS Unified Command: representatives manage by jointly approved
   objectives.
2. The person who decides is not the person who does the work. The commander
   delegates; only operators change the system.
3. The state is readable from outside. There is one place where the incident is
   discussed and one record that shows the current state.

Priorities, in order (Google SRE book): stop the impact, restore service, preserve
evidence for finding the cause.

Re-check (used throughout): confirming a decisive result again by another person using
another method. If only one of the two can change, record that. If the re-check cannot
happen now, give it an owner and a due time.

## How the phases relate

Phases are listed in order for explanation; in practice they overlap. Each phase's
target state is where that phase aims to get, not a gate for starting the next one.
If impact is ongoing and a known mitigation exists (for example, rolling back the most
recent change), apply it without waiting for mobilization or analysis to finish.

## Phase 0: Prepare (before any incident)

Goal: the commander does not have to invent the process during the incident.

- Declaration criteria. Example from the SRE book: declare if a second team is needed,
  the impact is visible to customers, or an hour of focused work has not solved it.
- Severity levels defined by what changes at each level: who is paged, whether outside
  communication is required, update interval, who may declare the end.
- Roles and backups: commander, deputy, scribe, communications.
- Retention policy for records and evidence: what is kept, where, for how long, and
  when temporary stores may be deleted.
- Templates for the first post, status update, correction, handoff, and close.
- Shape of termination conditions: which signal, within what range, for how long.
- Practice the process, and rotate roles in practice.

## Phase 1: Detect and intake

Goal: the report is split into observed facts and the reporter's interpretation, and
the declare decision is made.

Actions:
- Separate the observed fact ("received an email") from the interpretation ("it is
  fraud"). Add details such as whose name it used, sender, subject, or count only once
  they are confirmed.
- If an instruction from above carries an assumption, treat it as one theory and keep
  at least one alternative.
- Look for an obvious cause first: a recent release, config change, traffic spike,
  provider outage, or an internal operation that was redone.
- Declare when in doubt. Over-declaring is cheap; declaring late is expensive.
  Downgrading or withdrawing carries no blame.
- Request the likely decisive check right away, even before mobilizing.
- Keeping two theories is about not locking onto one view. It never delays a known
  mitigation.

Target state: declared, or handed back to normal operations.

Checkpoints:
- Facts and interpretation are written separately, and the facts contain nothing
  unconfirmed.
- At least two theories exist.
- The incident's name and title do not presuppose one theory.

## Phase 2: Declare and mobilize

Goal: anyone who reads the first post knows where to talk, who commands, what they are
asked to do, how severe the incident is, and what must not be written there.

Actions:
- One place for discussion and one record, linked to each other.
- The commander announces themselves, the deputy, and the scribe; names a
  communications owner when inside or outside communication is likely. If one person
  holds several roles, say so.
- State a provisional severity and revise it as you learn.
- Span of control: about five people per supervisor is the ICS guideline; the right
  number varies with the incident and the task. When the commander cannot keep up,
  split roles and add a layer.
- The first post contains: what is happening with the theories and confidence;
  severity and whether outside communication is needed (or when that will be decided);
  requests per role (who, what, what the result is for, when you will come back);
  the policy for the first reply to affected people, worded so it stays true under
  every theory; rules for secrets and personal data, and where they are kept instead.
- Make each request time-boxed ("A, please do B; I'll come back in N minutes") and
  get an acknowledgement. Do not hold mitigation while waiting for acknowledgements.

Target state: the people asked have acknowledged.

Checkpoints:
- Commander, deputy, and scribe are named; a communications owner is named or
  explicitly not needed yet.
- Current severity and the outside-communication decision (or its due time) are stated.
- Every request has an owner, a purpose, and a time to come back; each is acknowledged.
- Personal data is not being scattered across direct messages or the shared channel.

## Phase 3: Analyze

Goal: the decisive check is named, has top priority, and is done reliably.

Actions:
- For each theory, name the check that decides between them and state what changes
  with each result.
- Delegate investigation to operators and trust them within their role.
- Free the owner of the decisive check from other requests. Do not stack requests on one
  person.
- Re-check decisive results (see the definition above). Negative results ("not found",
  "not in the list", "no related change") look the same when the search itself was
  wrong, so do not skip the re-check.
- Prescribe low-error methods: copy and paste exact values, exact-match search,
  compare counts.
- Resolve conflicting answers as soon as they appear.
- Periodically reconsider whether to continue the current approach or switch.

Target state: the direction of the response is decided.

Checkpoints:
- The decisive check is named with what changes on each result.
- The decisive result has been re-checked, or the re-check has an owner and a due time.
- No single responder holds the decisive check plus several other requests.
- No two answers contradict each other unresolved.

## Phase 4: Mitigate and decide

Goal: the impact is stopped, and irreversible actions rest on confirmed facts.

Actions:
- Stop the impact before finding the cause. Do reversible work first: rollback,
  feature off, rate limit, drafting the notice, preparing the send.
- For irreversible actions (publishing, sending, deleting data, revoking credentials,
  contacting outside parties), write the condition for running them.
- Before an irreversible action, check whether its deciding fact has been re-checked.
  If not, write what you wait for and until when; at that time, decide with what is
  known.
- Hold absolute wording ("unrelated to us", "no impact") until the decisive check is
  done.
- Decide by asking "Are there any strong objections?" and be ready to change the plan
  when new information arrives.
- Scope heavy requests to other teams, including how far to go today.
- Brief leadership at milestones; make heavy decisions, including calling things off,
  with them.
- Security incidents: check that containment does not destroy evidence; follow the
  evidence-handling runbook. If there is no runbook, or it does not cover the step, say
  so, list what the step would destroy and how it could be captured first, and let the
  commander decide whether to wait.

When the theory flips (correction):
- Post the correction immediately; do not wait for the next status update.
- Include: what is now known; why the earlier view was wrong, as a process issue; the
  requests withdrawn; what to stop, naming whose work; new requests; the understanding
  to confirm, written as statements that can be judged true or false.
- Stop each affected person individually (the commander names them when posting),
  including anyone asked while off duty, and confirm that each one has stopped.
- Do not blame the person whose result was wrong; fix the process.

Target state: the impact has stopped.

Checkpoints:
- Reversible work was considered before irreversible actions.
- Each irreversible action has a run condition and a wait limit.
- After a flip, every withdrawn task has an identified owner who was told to stop, and
  each of them has confirmed they stopped.
- Security incidents: each containment step that may destroy evidence was checked
  against the evidence-handling runbook, or the gap was raised to the commander before
  the step ran.

## Phase 5: Monitor and resolve

Goal: the termination condition is confirmed against its pre-written statement.

Actions:
- Do not close as soon as symptoms stop; watch for a set period.
- Record each temporary workaround and the condition for removing it.
- Judge the end against the written termination condition, not by feel.
- Review the final reply to affected people before it is sent, including leadership's
  policy on apologies.

Target state: the termination condition is met.

Checkpoints:
- A monitoring period is set.
- The termination condition is written down, and the end is judged against measured
  values over the whole monitoring period.
- Workarounds are recorded with removal conditions.

## Phase 6: Close and hand off to review

Goal: the response is closed, remaining work has owners and due dates, and the record
is with whoever runs the review.

Actions:
- Post the close: result; what was learned or built; follow-ups with owners; cleanup
  with due dates (removing workarounds; deleting temporary copies such as a restricted
  store of personal data, only after confirming the retention policy for records and
  evidence is met); where the record is.
- Add the conclusion to the top of the record; keep the in-flight record below it.
- Name the review owner and date. The review is blameless and lists the sequence of
  events and process fixes with owners and due dates.

Checkpoints:
- Every follow-up has an owner; every cleanup item has a due date.
- Deletions are limited to temporary copies, after the retention policy is confirmed.
- A review owner and date exist.

## Always-on checkpoints

- A status update has gone out within the agreed interval and at each milestone.
- The latest update states confidence in words, the current severity, contrary
  evidence or "none", and the next update time.
- Severity is reviewed at milestones, and paging, outside communication, and the update
  interval follow it.
- Outside communication is owned by the communications owner and kept separate from
  internal updates.
- The commander is not doing hands-on work without having said so.
- Requests older than their come-back time have an acknowledgement or a follow-up.
- No personal data or secret values appear in the shared channel.
- Long incidents: people are rotated, and handoffs are spoken and confirmed by both sides.
- If the commander or anyone seems overwhelmed or cannot keep up, more help is
  requested and roles are split.

## Trade-offs

Do not turn these into verdicts; state the condition.

| Question | One view | Other view | Condition used here |
|---|---|---|---|
| Should the commander investigate? | The commander does not fix; delegate all repair (PagerDuty, SRE book) | In a small incident, the commander's own digging can be what finds the answer | Delegate by default. If one person must combine roles, say so, and give the re-check of the decisive result to someone else |
| Wait for a re-check, or act? | A wrong decision is better than no decision (PagerDuty) | Re-check a decisive negative result before acting on it | Do reversible work without waiting. For irreversible actions, set a deadline for the re-check; at the deadline, decide with what is known |
| Stop the impact, or keep evidence? | Stop the impact, restore, then keep evidence (SRE book) | In security incidents, evidence shapes later steps (NIST SP 800-61) | Stop the impact first, but run anything that may destroy evidence only through the evidence runbook. If there is no runbook, or it does not cover the step, list what would be lost and how to capture it first, and let the commander decide whether to wait |
| How early to declare? | Declare when in doubt; over-declaring is cheap | Declaring pulls people away from their own work | Declare early; size who is paged by severity, and move severity up or down as you learn |
| How detailed are updates? | Short and factual (PagerDuty) | Include contrary evidence | Keep the body short; always add one line of contrary evidence, or "none" |

## Templates

Wherever a template names a person (`<person>`, `<owner>`), the draft uses a role label
(for example, "database operator" or "responder 2"); the human replaces it with a name
or mention when posting.

First post:
```
[Incident] <neutral title>
Commander: <person> / Deputy: <person> / Scribe: <person> / Comms: <person or "not yet">
Severity: <level> (provisional) / Outside communication: <needed / not needed / decide by <time>>
What we know (observed): ...
Theories: A (<confidence>), B (<confidence>)
Contrary evidence: <fact or "none">
Requests:
- <person>: <task> — used for <purpose> — back at <time>
First reply to affected people: <wording that holds under every theory>
Rules: no personal data or secrets here; put them in <restricted place>; post results only
Record: <link>
Next update: <time>
```

Status update:
```
Status as of <time>
Working view: <view> (<confirmed / likely / unconfirmed>)
Severity: <level> (<changed because ...>)
Known: ...
Checking: <what> — <person> — by <time>
Contrary evidence: <fact or "none">
Now / next: ...
Stopped or withdrawn: ...
Next update: <time>
```

Correction:
```
[Correction] <new view> (<confirmed / likely / unconfirmed>)
Severity: <level> (<unchanged / changed because ...>)
Now known: ...
Why the earlier view was off (process): ...
Contrary evidence: <fact or "none">
Withdrawn: <request> (<person>)
Stop: <person> — <task> — please reply once stopped
New requests: ...
Please confirm: <statement> / <statement>
Next update: <time>
```

Handoff:
```
Handing command from <person> to <person> at <time>
Working view and confidence: ...
Severity: ...
Contrary evidence: <fact or "none">
Checks in flight: ...
Decisions waiting: ...
Stopped: ...
Next update: <time>
Confirmed by both: <yes / not yet>
```

Close:
```
[Closed] <title> at <time>
Result: ... (<confirmed / likely>)
Severity (final): <level>
Learned / built: ...
Follow-ups: <item> — <owner> — <due>
Cleanup: <item> — <due> (temporary copies only, after the retention policy is confirmed)
Review: <owner> on <date>
Record: <link>
```

## Sources

- FEMA, ICS Review Document: unity of command (each individual reports to one person),
  span of control (one supervisor to five subordinates is optimal; a guideline that
  often differs in practice), Unified Command, transfer of command.
- Google SRE book, Managing Incidents: roles (command, operations, communication,
  planning), the three declaration criteria, explicit handoff, priorities (stop the
  bleeding, restore service, preserve evidence), and the practices Trust, Introspect,
  Consider alternatives, Practice, Change it around.
- PagerDuty Incident Response: Different Roles (the commander is not a resolver),
  During an Incident (announce commander, deputy, scribe; look for an obvious cause),
  Incident Commander training ("Are there any strong objections?", time-boxed tasks
  with acknowledgement, short factual status updates, a wrong decision is better than
  no decision).
- NIST SP 800-61 Rev. 3 (April 2025): incident response recommendations organized
  around CSF 2.0, including containment, and collecting incident data while preserving
  its integrity and provenance.
