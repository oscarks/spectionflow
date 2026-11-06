# `/proposal`

## Purpose

Writes the **Proposal**: the **what and why** of a feature: problem, solution vision, business rules, acceptance criteria, risks, decisions and a **phase roadmap**. It is not an implementation spec. After you approve it, `/ai-spec <Feature> phase N` derives the executable spec of each phase (files, contracts, tests), `/implement` builds from that AI-SPEC, and `/review` checks the code against the AI-SPEC and the Proposal. The Proposal must be precise about behavior and rules, so the author of each AI-SPEC never has to ask about them.

## When to use / not use

Use it before implementing any feature, after the optional inception and analysis.

Do not use it for open-ended exploration (use `/analysis`), for file-level design (that is `/ai-spec`) or to implement code (use `/implement`). Do not use it to mark itself approved: approval is yours.

## Invocation and arguments

```
/proposal <Feature Name>
```

Examples:

```
/proposal Notification_Retry
/proposal Notification Retry
```

If the request scope is vague, the skill asks before writing. If the file already exists, it asks whether to update it or write a new version.

## Inputs read (Phase 0, mandatory)

1. Your request, clarified if vague.
2. README, `CLAUDE.md` / `AGENTS.md`, manifests and docs: stack, layout, test/lint/build commands, conventions, doc language.
3. Optional inputs:
   - `docs/inception/` (`Product_Definition.md`, `Scope_and_Milestones.md`, `sources/`): the what/why; the proposal cites it instead of re-deriving it.
   - `docs/features/<Feature>/Analysis_<Feature>.md`: its findings and verdict are inherited. Each `AQ-NN` owned by `proposal` or `spike` and still unanswered is a **stop-and-ask**. An unanswered `spike` means a recommended experiment never ran: the skill does not proceed on that untested assumption unless you answer inline or waive it. The resolution is recorded in Design Decisions; any divergence from the analysis verdict is stated there.
   - Related proposals and decision records, so they are not contradicted.
4. The real code the feature touches (models, services, handlers, UI, tests), with real file paths.
5. **Boundary of every measurement**: when a scan, benchmark or spike backs a claim, the proposal states what universe was swept and what was excluded and why.

## Outputs written

`docs/features/<Feature>/Proposal_<Feature>.md`. The section list is in [artifacts](../artifacts.md#proposal).

## What the skill does, step by step

1. Phase 0 exploration (above). The findings are summarized in "Current State" to prevent duplicate implementations.
2. Writes the header, then sections 1 to 15 plus an optional Glossary. Sections: Problem and Motivation, Solution Overview, Current State, Proposed Architecture, Business Rules, Security and Access Model, Performance and Scalability, Impact Analysis, Risks and Mitigations, Observability, Design Decisions, Expected Benefits, Acceptance Criteria, Implementation Plan, Open Questions. A section is omitted only if it genuinely does not apply, and then one line says so.
3. Breaks the work into **phases** that can be specified, implemented and reviewed one at a time. Each phase is independently deployable and can be verified on its own. The Implementation Plan is a **roadmap only**: one table with phase, name, goal, scope summary, acceptance criteria covered, dependencies and size (S / M / L). No paths, signatures or test files appear there; that is the job of the per-phase AI-SPEC.
4. Runs its self-check, then reports the path, the number of phases and the open questions you must answer, and suggests: review and approve the Proposal, then `/ai-spec <Feature> phase 1` to produce the phase spec, then `/implement` and `/review` for that phase (repeat per phase).

## Rules and guardrails

- Explore before writing; reference real paths; never invent paths, APIs or facts.
- Use the project's actual schema and code syntax, not descriptions.
- **No placeholder text**: never "TBD", "similar to X", "etc.", "as needed". Spell it out, mark it OUT OF SCOPE with a justification, or raise it as an `AQ-NN`.
- Every business rule `RN-NN` is **testable** and states the violation behavior. Every `RN-NN` is covered by at least one acceptance criterion; every criterion traces to at least one scenario `SC-NN`.
- A criterion about a test suite names its **baseline** ("no new failure relative to the baseline recorded at the start of the feature"), never "the suite is green". Baseline numbers are recorded in the Proposal.
- Benefits state how success is observed with a real measure, or honestly say it is not objectively measurable in this delivery. No invented numbers.
- IDs are stable: `SC`, `P`, `RN`, `CA`, `AQ`, `D`, `R`, `B` are never renamed or reused; new items take the next number.
- `Status` changes are made by editing the Status line; `Approved` is set only when you approve in the conversation. The skill never writes a proposal as already approved.
- It must not contradict existing decision records or approved proposals.

## Human checkpoints

- Clarifying vague scope up front.
- Answering `operator`-owned open questions before approval.
- Answering unresolved `proposal`/`spike` questions inherited from an analysis.
- Approving the Proposal (the gate for `/ai-spec`, and therefore for `/implement`).

## Common mistakes

- Skipping Phase 0 and writing from assumptions.
- Phases that are too large to review, or that leave the system half-working.
- Business rules that are not testable ("the system should be fast").
- Acceptance criteria not tied to a phase, or business rules with no covering criterion.
- File-level detail in the Implementation Plan: it is a roadmap, the detail belongs in the AI-SPEC.
- A roadmap where an acceptance criterion belongs to no phase, or to two.
- "The test suite is green" as a criterion instead of "no new failure relative to the baseline".
- Setting `Status: Approved` without your approval.

## Worked example

```
/proposal Notification_Retry
```

Excerpt of `docs/features/Notification_Retry/Proposal_Notification_Retry.md`:

```markdown
# Proposal: Notification_Retry - Reliable webhook retries

**Date**: 2026-11-06
**Status**: Draft
**Affected areas**: delivery service, jobs worker, deliveries table
**Prerequisites**: Delivery_Log (Pending)
**External dependencies**: None new
**Estimated complexity**: Medium

## 1. Problem and Motivation
Failed deliveries are dropped in `src/delivery/sender.ts:31`.
- SC-01: the customer endpoint returns 503 for two minutes; the event is lost.
- SC-02: the endpoint stays down for a day; support cannot tell what was lost.

## 5. Business Rules
RN-01: A delivery that fails with a network error or a 5xx response is retried.
       Violation: the delivery is marked `failed` with no retry scheduled.
RN-02: At most 8 attempts are made per delivery.
       Violation: a 9th attempt is created.

## 13. Acceptance Criteria
- CA-F1-01: a delivery answered with 503 is rescheduled (covers RN-01, SC-01).
- CA-F1-02: after the 8th failure the delivery is `failed` and no job remains (RN-02).
- CA-FINAL-01: no new test failure relative to the baseline (212 passing, 0 failing) recorded at the start.

## 14. Implementation Plan
| Phase | Name | Goal | Scope summary | Acceptance criteria covered | Depends on | Size |
|---|---|---|---|---|---|---|
| 1 | Retry scheduling | Failed deliveries are re-enqueued | `attempts` tracking and a retry job | CA-F1-01 | None | M |
| 2 | Backoff and limit | Retries slow down and stop | Exponential schedule, cap of 8 attempts | CA-F1-02, CA-FINAL-01 | 1 | S |

## 15. Open Questions
- AQ-01: Should 4xx responses other than 408/429 be retried? Owner: operator. Status: open.
```
