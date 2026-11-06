# Writing a specification an AI agent can execute

Spectionflow splits the specification in two. The **Proposal** (`docs/features/<Feature>/Proposal_<Feature>.md`) says **what and why**: problem, solution vision, business rules, acceptance criteria, risks, decisions and a phase roadmap. The **AI-SPEC** (`docs/features/<Feature>/AI-SPEC_<Feature>_Phase_<N>.md`, one per phase) says **how**, and it is the executable spec: an agent implements a phase from it without guessing or asking. The Proposal alone is not enough to implement from. This page explains what makes a specification executable and which document carries which part. See also [development.md](development.md) and [`/ai-spec`](skills/ai-spec.md).

## Why specifications fail with agents

The classic bottleneck: the human spec is ambiguous, incomplete or implicit, so the agent produces code that diverges from the intent. An executable specification is a document **structured and explicit enough that an agent can implement it, a reviewer can verify it, and tests can be derived from it**.

Properties to aim for:

1. **Unambiguous.** No "fast", "adequate", "normal", "etc.", "as needed". Say how fast, which cases, what exactly.
2. **Complete for implementation.** The agent should not have to infer implicit rules. If a behavior matters, it is written.
3. **Structured.** Entities, rules, states, interfaces and scenarios each have a fixed place.
4. **Verifiable.** Every rule and criterion can be checked pass/fail.
5. **Identified.** Everything has a stable id, so reviews and tests can point at it.
6. **Deterministic.** Same input, same decision.

## The quality bars

| Bar | What it means | Example |
|---|---|---|
| **Domain invariants** | Facts that must always hold for an entity, as predicates | `INV-01: policy.maxLiters > 0`; `INV-02: tenantId is not null` |
| **Business rules** | An id, a severity (`BLOCK`, `WARN`, `INFO`), a boolean expression of when it holds, and the exact behavior on violation | `RN-03 [BLOCK]: Holds when: request.liters <= policy.maxLiters. Violation: reject with 422, no state change` |
| **State machines with guards** | Allowed states and transitions, each with a guard; unlisted transitions are forbidden | `Requested -> Approved [score >= policy.threshold] (Reviewer)` |
| **Observability and audit** | What is logged or emitted, and an append-only trail for sensitive actions | event `authorization.denied` with reason and request id |
| **Traceability** | Requirement -> rule -> criterion -> test -> file, in both directions | `SC-02 -> RN-03 -> CA-F1-02 -> T-F1-01 -> src/authorization/service` |
| **Testable acceptance criteria** | Pass/fail statements with concrete values | Given limit 50, request 60, then decision is Denied |
| **Ambiguity-free wording** | Literal values, named baselines, explicit exclusions | "no new failure relative to the baseline recorded in section 13" |

**Severity and boolean expression are required parts of the AI-SPEC.** Every rule that falls in a phase is rewritten there as an expression over named fields:

```
RN-03 [BLOCK]: requested liters must not exceed the policy limit.
Holds when: request.liters <= policy.maxLiters
Violation: reject with 422 "volume exceeds policy"; no authorization is created
```

The expression must be deterministic and use only names the spec defines. It is the oracle: the code enforces it and a test asserts it. An agent can turn that into a validation and a test directly. "The volume should be reasonable" it cannot.

**Guarded state machines are required whenever an entity has a lifecycle.** The AI-SPEC lists the states (with the initial one), one transition per line as `From -> To [guard] (actor/event)`, the terminal states and any timed transitions; every transition not listed is forbidden and must be rejected. A diagram without guards is not enough. If there is no lifecycle, the spec says so.

## Who carries which bar

| Bar | Proposal (what/why) | AI-SPEC (how, per phase) |
|---|---|---|
| Domain invariants | Data model in the project's real schema syntax, with constraints, defaults and indexes | Section 4 Solution > Data model: schema delta plus `INV-NN` predicates |
| Business rules | Section 5: `RN-NN`, grouped by sub-domain, each testable, with its `Violation:` behavior | Section 4 Solution > Logic and business rules: each RN of the phase with `[BLOCK\|WARN\|INFO]`, `Holds when:` expression and exact violation outcome |
| State machines | Section 4 Data flow: lifecycle states of entities that have one | Section 4 Solution > State machine: guarded transitions, forbidden-by-default |
| Observability and audit | Section 10: events, logs, metrics | Section 9: telemetry and audit record (actor, action, target, before -> after, timestamp, reason) |
| Traceability | `SC-NN` -> `RN-NN` -> `CA-F<phase>-NN`; every rule covered by a criterion | Section 14 table: requirement -> RN -> CA -> test -> file/area |
| Testable criteria | Section 13: `CA-F<phase>-NN`, `CA-FINAL-NN` | Section 13: criteria refined to pass/fail, each with a verification method; section 10: tests `T-F<phase>-NN` |
| No ambiguity | No "TBD", "etc."; unknowns become `AQ-NN` with an owner | Same, plus no vague terms; every path verified real; self-check in section 15 |

The rule of thumb: the Proposal is precise about **behavior and scope**, so the author of an AI-SPEC never has to ask about them; the AI-SPEC is precise about **files, types, expressions and tests**, so the implementer never has to ask about those. The Proposal's `Implementation Plan` is a phase roadmap only; file-level detail there is a defect.

## Condensed example

A shortened Proposal and the AI-SPEC of its phase 1, for a fuel-authorization check. Section numbers match the templates.

**Proposal** (`Proposal_Fuel_Authorization.md`)

```markdown
# Proposal: Fuel_Authorization - Real-time volume check

**Status**: Approved

## 1. Problem and Motivation
- SC-01: A driver requests more fuel than the vehicle policy allows; today nothing stops it.
- SC-02: A request with no active policy must not be approved silently.

## 5. Business Rules
- RN-01: policy.maxLiters is positive. Violation: 422, policy not saved.
- RN-03: A request above the policy limit is denied. Violation: the request is approved.
- RN-04: A request with no active policy goes to review, never to approved. Violation: it is approved.

## 13. Acceptance Criteria
- CA-F1-01 (SC-01, RN-03): a request above the limit is denied.
- CA-F1-02 (SC-01, RN-03): a request within the limit is approved.
- CA-F1-03 (SC-02, RN-04): a request with no active policy is sent to review.
- CA-FINAL-01: no new test failure relative to the baseline recorded at the start (12 failing before).

## 14. Implementation Plan
| Phase | Name | Goal | Scope summary | Acceptance criteria covered | Depends on | Size |
|---|---|---|---|---|---|---|
| 1 | Policy and decision | Decide Approved, Denied or Review | Policy model, decision endpoint | CA-F1-01..03, CA-FINAL-01 | None | M |

## 15. Open Questions
- AQ-01: What is the default threshold when a tenant has several policies? Owner: operator.
```

**AI-SPEC** (`AI-SPEC_Fuel_Authorization_Phase_1.md`, produced by `/ai-spec Fuel_Authorization phase 1`)

```markdown
## 4. Solution
### Files
- `src/policy/policy.schema` (create), `src/authorization/authorization.service` (create)
- `src/authorization/authorization.spec` (create)

### Data model
model Policy {
  id        String  @id @default(uuid())
  tenantId  String
  maxLiters Decimal @db.Decimal(8,2)
  active    Boolean @default(true)
  @@index([tenantId, active])
}
INV-01: maxLiters > 0
INV-02: tenantId is not null

### Business rules
RN-03 [BLOCK]: request above the policy limit is denied.
  Holds when: request.liters <= policy.maxLiters
  Violation: decision = Denied, reason "volume-exceeds-policy"
RN-04 [BLOCK]: no active policy never yields Approved.
  Holds when: exists(policy WHERE tenantId = request.tenantId AND active = true)
  Violation: decision = Review

### State machine: Authorization
States: Requested (initial), Approved (terminal), Denied (terminal), Review
Requested -> Approved [RN-03 holds AND RN-04 holds] (system)
Requested -> Denied   [RN-03 violated] (system)
Requested -> Review   [RN-04 violated] (system)
Review -> Approved | Denied (operator)
Any other transition is forbidden and rejected.

## 10. Tests
T-F1-01 [unit] covers RN-03, CA-F1-01: deny when volume exceeds policy
  Given: policy.maxLiters = 50   When: request.liters = 60
  Then: decision = Denied   Assert: reason == "volume-exceeds-policy"
T-F1-02 [unit] covers RN-03, CA-F1-02: approve valid volume (request 40)
T-F1-03 [unit] covers RN-04, CA-F1-03: review without an active policy
T-F1-04 [unit] covers the state machine: Approved -> Denied is rejected
Run: <the project's test command>

## 14. Traceability
| Requirement | RN | CA | Test | File / area |
|---|---|---|---|---|
| Deny above the limit | RN-03 | CA-F1-01, CA-F1-02 | T-F1-01, T-F1-02 | `src/authorization/authorization.service` |
| No policy goes to review | RN-04 | CA-F1-03 | T-F1-03 | `src/authorization/authorization.service` |
```

From the AI-SPEC an agent can generate the schema, the service and the tests, and `/review` can check each rule, criterion and test by id.

## Writing guidelines

1. **Explore before writing.** `/proposal` and `/ai-spec` read the code first. Use real paths and the project's real syntax.
2. **One idea per rule.** If a rule contains "and", it probably needs two ids and two tests.
3. **State violations.** A rule without a violation behavior cannot be tested.
4. **Use literal values in criteria.** Numbers, names, status codes. Avoid adjectives.
5. **Keep ids stable.** `SC`, `P`, `RN`, `CA`, `AQ`, `D`, `R`, `B`, `T`, `INV` ids are never renamed or reused. The AI-SPEC uses the Proposal's `RN` and `CA` ids verbatim. New items take the next number. Reviews and tests cite them.
6. **Make unknowns explicit.** An open question with an owner (`operator`, `proposal`, `spike`, `deferred`) beats a guess. Blocking questions are answered before the phase that needs them.
7. **Measure honestly.** If a benefit cannot be measured in this delivery, say so instead of inventing a number.
8. **Name baselines.** "Tests pass" is not verifiable by someone whose change did not break them; "no new failure relative to the recorded baseline" is.
9. **Amend visibly.** When implementation disproves the spec, add an amendment note below the original text.

## Self-check before approving a Proposal

- Could the author of each phase's AI-SPEC write it from this document without asking about behavior, rules or scope?
- Is every rule testable, with its violation behavior, and covered by at least one criterion?
- Does every criterion trace to a scenario?
- Are there any "TBD", "etc.", "similar to", or unnamed baselines?
- Is the Implementation Plan a roadmap only, with every criterion in exactly one phase?
- Do open questions have owners, and are the blocking ones answered?

## Self-check before approving an AI-SPEC

- Could an agent implement the phase start to finish without asking a question?
- Does every rule have an id, a severity, a boolean expression over named fields and a violation outcome?
- Does every lifecycle have enumerated states and guarded transitions, with unlisted transitions rejected?
- Does every rule have a violating-case and a holding-case test, and every criterion a verification method?
- Does the traceability table cover every RN and CA of the phase, with files and tests that exist?
- Does each guarantee ("always", "never") state the condition under which it is false?
- Is the self-check section filled with real searches and counts that match its table?
