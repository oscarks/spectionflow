# `/ai-spec`

## Purpose

Writes the **AI-SPEC** of one phase: the executable technical specification an AI agent can implement **without guessing and without asking**. The Proposal says what and why; the AI-SPEC says how, for exactly one phase: files, data model, contracts, rules as boolean expressions, state machines with guards, error table, tests with ids, and a traceability table.

If an implementer would have to ask a question, the spec has failed.

## When to use / not use

Use it once per phase, after the Proposal is approved and before `/implement`.

Do not use it before the Proposal is `Approved` (the skill stops), to add scope the Proposal does not carry (it reports the gap instead), or to implement anything.

## Invocation and arguments

```
/ai-spec <Feature> [phase N]
```

Without `phase N`, the skill specs the next phase that has no AI-SPEC yet (Phase 1 when the Proposal has a single phase).

```
/ai-spec Notification_Retry phase 1
/ai-spec Notification_Retry
```

If an AI-SPEC already exists at the target path, the skill asks whether to update or replace it.

## Inputs read (Phase 0, mandatory before writing)

- `docs/features/<Feature>/Proposal_<Feature>.md`: must exist and be `Approved` (or later), otherwise the skill stops and tells you to run `/proposal` and approve it. It reads the chosen option, decisions `D-NN`, rules `RN-NN`, criteria, risks and the roadmap entry for the phase.
- Optional upstream context: `Analysis_<Feature>.md`, `docs/inception/`, architecture decision records (checked to be still current).
- The AI-SPECs of previous phases and the code they produced, so this phase builds on what is real.
- README, `CLAUDE.md` / `AGENTS.md`, manifests: stack, layout, test framework, commands.
- The existing code the phase touches. Every cited path is verified: files to modify exist; files to create have an existing parent directory. For each kind of artifact it specifies, it finds one existing example and references it.
- Existing tests that read what the phase will change.

## Outputs written

`docs/features/<Feature>/AI-SPEC_<Feature>_Phase_<N>.md` (single-phase features use `Phase_1`). Status is written as `Draft`. The section list is in [artifacts](../artifacts.md#ai-spec).

## What the skill does, step by step

1. **Preconditions** and **exploration** (above). Decisions taken during exploration, such as how an ambiguity in the Proposal was resolved, are stated in the spec's Description or Scope.
2. **Pass 1, skeleton.** One small write right after exploration: the header, all 15 section headings in order, the ids already allocated (RN, CA, T) with one line each, and the line `> SKELETON - body pending`. If the session dies, the expensive exploration is not lost.
3. **Pass 2, body.** Writes the sections and removes the skeleton line in the same write as the last section. A document that still carries the line is incomplete.
4. **Self-check** (section 15): a deliberate search for collisions between what the spec prescribes and the tests (see below).
5. **Finish**: re-reads the Status (`Draft`), summarizes path, scope, number of RN / CA / tests, any gap found in the Proposal, and asks you to review. Next step: `/implement <Feature> phase N` once you approve.

## The 15 sections

Exact headings, in this order. A section that does not apply stays, with one line saying why.

| # | Section | What it holds |
|---|---|---|
| 1 | Description | What the phase delivers and why; numbered capabilities. |
| 2 | Scope | In scope; Out of scope with a reason and where each item goes. |
| 3 | Current State | Verified table of what exists, with real paths; what must be modified. |
| 4 | Solution | The design, in execution order (see below). |
| 5 | Interface | Screens, commands or public API, if any. |
| 6 | Integrations | Connections to existing modules and external systems; idempotent handlers. |
| 7 | Security | Access per entry point, data isolation, data-sensitivity table. |
| 8 | Performance | Indexes, pagination limits, N+1 risks, with numbers and units. |
| 9 | Observability | Telemetry and an append-only audit trail for sensitive actions. |
| 10 | Tests | Scenarios `T-F<phase>-NN` mapped to RN and CA, plus how to run them. |
| 11 | Migration / Seed | Persisted-data changes; idempotent seeds; new configuration. |
| 12 | Dependencies | New packages with version range and justification. |
| 13 | Acceptance Criteria | `CA-F<phase>-NN` refined to pass/fail, each with a verification method. |
| 14 | Traceability | Requirement, RN, CA, test, file/area. |
| 15 | Self-check | What was searched, candidate collisions, counts. |

### Section 4, Solution

Nine parts, in this order: overview diagram; files to create/modify (real paths, `MODIFY` marked); data model in the project's real syntax with **domain invariants** as predicates (`INV-01: quantity > 0`); contracts and interfaces; **business rules**; **state machine**; flows (sequence diagrams for the main and the main error path); error table; **limits of each guarantee**.

Two parts are the core of "executable":

- **Rules as boolean expressions.** Each Proposal rule that falls in the phase becomes
  `RN-NN [BLOCK|WARN|INFO]: <description>. Holds when: <boolean expression over named fields>. Violation: <exact outcome>.`
  `BLOCK` is rejected, `WARN` is allowed but flagged, `INFO` is informative. The expression is deterministic and uses only names defined in the spec. It is the oracle the code enforces and the test asserts. It is never written as a comparison against version-control state (`git diff` against `HEAD`): that cannot be evaluated when phases land uncommitted; compare against a copy taken at the start of the phase.
- **Guarded state machine.** For every entity with a lifecycle: the states and the initial one, one transition per line as `From -> To [guard] (actor/event)`, terminal states, timed transitions. A transition that is not listed is forbidden and must be rejected.

### Section 10, Tests

Each scenario has an id `T-F<phase>-NN`, a level (`unit | integration | e2e`), the RN and CA it covers, and Given / When / Then / Assert lines with concrete assertions. Every RN has a scenario for the violating case and one for the holding case; every state transition (allowed and forbidden) and every invariant is exercised. The section ends with the exact commands to run.

### Section 15, Self-check

The target is narrow: **collision between what the spec prescribes and a test**, one the spec prescribes or a pre-existing one it promises not to break. The skill searches for tests that read each file it touches (by path, basename and, when content moves between files, by the literals that move), reads the guard tests on the touched surface in full, looks for assertions that forbid a prescribed literal, recounts every count in the spec against its table, and runs the project's tests with the new document on disk. The section records:

- a paragraph on what was searched and how, with a numbered list of at least 3 items, each citing the command, path or measurement;
- a table `| # | Candidate collision | Checked in | Verdict | What changed in the spec |` with verdict `real | self-inflicted | discarded`;
- a final line with counts taken from the table: `self-check: candidates=<N> real=<A> self-inflicted=<B> discarded=<C>`, with `N = A + B + C`.

Every `real` and `self-inflicted` finding is fixed in the spec before it finishes.

## Rules and guardrails

- **No ambiguity, no placeholders.** No "TBD", "similar to X", "etc.", "as needed". Vague words ("fast", "reasonable") are replaced by a number and unit, or a named policy value.
- **Exact names.** Real paths, entity, function and endpoint names, following the project's conventions.
- **Deterministic.** The same inputs always give the same decision.
- **Stable ids** for invariants, rules, states, criteria and tests; never renumbered. Proposal ids are used verbatim.
- **Proposal alignment.** The spec never contradicts a decision, rule or the chosen option. If it needs to change one, the skill stops and tells you.
- **Secure by default.** Access is specified for every entry point; the default is restrictive.
- **Guarantees state their limits.** An "always" or "never" comes with the condition under which it is false.
- **Never marks the spec `Approved`.** That is your call, in the conversation.

## Human checkpoints

- You approve the Proposal before the skill will run.
- The skill reports Proposal gaps instead of filling them; you decide.
- You review the `Draft` AI-SPEC and approve it before `/implement` (`/pipeline` can auto-accept it in `all` mode, see [pipeline](pipeline.md)).

## Common mistakes

- Writing the spec without exploring the code: invented paths and duplicate implementations follow.
- Rules in prose instead of an id, a severity and a boolean expression.
- A state machine drawn as a diagram only, with no guards and no "unlisted transitions are forbidden".
- Scope added that the Proposal does not carry.
- A rule with no violating-case test.
- Counts in prose that disagree with the table next to them.
- Moving content between files without searching for tests that assert the moved literals.
- Dumping the whole spec in one write with no skeleton on disk.

## Worked example

```
/ai-spec Notification_Retry phase 1
```

Excerpt of `docs/features/Notification_Retry/AI-SPEC_Notification_Retry_Phase_1.md`:

```markdown
# AI-SPEC: Notification_Retry - Phase 1: Retry scheduling

**Feature**: Notification_Retry
**Phase**: 1 of 2
**Status**: Draft
**Date**: 2026-11-06
**Proposal**: docs/features/Notification_Retry/Proposal_Notification_Retry.md
**Related**: Phase 2 (backoff and limit)

## 2. Scope
In scope: 1. re-enqueue a failed delivery. 2. `attempts` and `next_attempt_at` columns.
Out of scope: 1. exponential backoff (Phase 2). 2. dashboard (separate feature).

## 4. Solution
### Files
- `migrations/0042_add_attempts.sql` (create)
- `src/jobs/retry.ts` (create), following `src/jobs/cleanup.ts`
- `src/delivery/sender.ts` (MODIFY): enqueue on failure

### Data model
INV-01: attempts >= 0
INV-02: next_attempt_at is null or next_attempt_at > created_at

### Business rules
RN-01 [BLOCK]: a failed delivery with a retryable error is rescheduled.
  Holds when: delivery.status == 'failed' AND (error.kind == 'network' OR error.status >= 500)
  Violation: a 400 response is not retried; delivery stays 'failed', no job is created.

### State machine: Delivery
States: pending (initial), sent (terminal), retrying, failed (terminal)
pending  -> sent     [response.status < 300] (worker)
pending  -> retrying [RN-01 holds] (worker)
retrying -> sent     [response.status < 300] (retry job)
Any other transition is forbidden and rejected.

## 10. Tests
T-F1-01 [unit] covers RN-01, CA-F1-01: retry handler - reschedules on 503
  Given: a delivery whose last response was 503
  When: the worker processes the failure
  Then: the delivery is `retrying` and one job exists
  Assert: delivery.status == 'retrying'; jobs.count == 1
T-F1-02 [unit] covers RN-01, CA-F1-01: retry handler - does not retry 400
  ...
Run: `npm test -- src/jobs`

## 14. Traceability
| Requirement | RN | CA | Test | File / area |
|---|---|---|---|---|
| Failed deliveries are retried | RN-01 | CA-F1-01 | T-F1-01, T-F1-02 | `src/jobs/retry.ts` |

## 15. Self-check
Searched for tests reading `src/delivery/sender.ts`: ...
self-check: candidates=3 real=1 self-inflicted=0 discarded=2
```
