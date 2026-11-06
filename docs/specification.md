# Writing a specification an AI agent can execute

In Spectionflow the **Proposal** (`docs/features/<Feature>/Proposal_<Feature>.md`) is the single specification. There is no second technical spec. This page explains what makes a specification executable by an AI agent, and how the Proposal template carries it. See also [development.md](development.md).

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
| **Domain invariants** | Facts that must always hold for an entity | `Policy.maxLiters > 0`; `tenantId` is never null |
| **Business rules** | A testable statement, a severity of violation, and the behavior on violation | `RN-03: requested liters <= policy.maxLiters. Violation: reject with 422, no state change` |
| **State machines with guards** | Allowed states and transitions, each transition with a condition | `Requested -> Approved [score >= threshold]` |
| **Observability and audit** | What is logged or emitted, and when | event `authorization.denied` with reason and request id |
| **Traceability** | Requirement -> rule -> scenario -> test -> code, in both directions | `SC-02 -> RN-03 -> CA-F1-02 -> test name -> file` |
| **Testable acceptance criteria** | Pass/fail statements with concrete values | Given limit 50, request 60, then decision is Denied |
| **Ambiguity-free wording** | Literal values, named baselines, explicit exclusions | "no new failure relative to the baseline recorded in section 13" |

A useful way to write a rule is as a **boolean expression** plus its severity:

```
RN-03  (severity: BLOCK)
Expression: request.liters <= policy.maxLiters
Violation: reject with 422 "volume exceeds policy"; no authorization is created
```

An agent can turn that into a validation and a test directly. "The volume should be reasonable" it cannot.

## How the Proposal carries these bars

The `/proposal` template has these sections: Problem and Motivation, Solution Overview, Current State, Proposed Architecture, Business Rules, Security and Access Model, Performance and Scalability, Impact Analysis, Risks and Mitigations, Observability, Design Decisions, Expected Benefits, Acceptance Criteria, Implementation Plan, Open Questions, and an optional Glossary.

| Bar | Where it lives in the Proposal |
|---|---|
| Domain invariants | **Proposed Architecture > Data model**: full definitions in the project's real schema syntax, with constraints, defaults and indexes. State invariants that the schema cannot express as `RN-NN` rules. |
| Business rules | **Business Rules**: `RN-NN`, grouped by sub-domain, each testable and stating its `Violation:` behavior. |
| Severity and boolean expression | Not required by the template. **Recommended addition**: write the rule as an expression and add a severity word, as in the example above. |
| State machines with guards | **Proposed Architecture > Data flow** requires lifecycle states for entities that have one. **Recommended addition**: list transitions with their guard conditions, and make each guard an `RN-NN`. |
| Observability and audit | **Observability**: events emitted, what is logged (creation, deletion, state changes, errors), metrics. |
| Traceability | Scenarios `SC-NN` (Problem section) -> rules `RN-NN` -> criteria `CA-F<phase>-NN` -> tests per phase (Implementation Plan). The template requires that every rule is covered by a criterion and every criterion traces to a scenario. |
| Testable criteria | **Acceptance Criteria**: phase criteria `CA-F<phase>-NN`, final criteria `CA-FINAL-NN`, covering happy paths, key errors, authorization and data isolation where they apply. |
| No ambiguity | Writing rules: no "TBD", "similar to X", "etc."; real file paths only; anything undecided becomes an open question `AQ-NN` with an owner. |

Where the template does not ask for something you need (guards, severities), add it inside the section that fits. The checklist in `/proposal` and the checks in `/review` will still apply.

## Condensed example

A shortened Proposal for a fuel-authorization check. Section numbers match the template.

```markdown
# Proposal: Fuel_Authorization - Real-time volume check

**Status**: Approved

## 1. Problem and Motivation
- SC-01: A driver requests more fuel than the vehicle policy allows; today nothing stops it.
- SC-02: A request with no active policy must not be approved silently.

## 4. Proposed Architecture
### Data model (diff)
model Policy {
  id        String  @id @default(uuid())
  tenantId  String
  maxLiters Decimal @db.Decimal(8,2)
  active    Boolean @default(true)
  @@index([tenantId, active])
}
Invariant: maxLiters > 0 (enforced by RN-01).

### Lifecycle: Authorization
Requested -> Approved [RN-03 holds]
Requested -> Denied   [RN-03 violated]
Requested -> Review   [no active policy, RN-04]
Terminal states: Approved, Denied. Review -> Approved|Denied only by an operator.

## 5. Business Rules
- RN-01 (BLOCK): policy.maxLiters > 0. Violation: 422, policy not saved.
- RN-03 (BLOCK): request.liters <= policy.maxLiters. Violation: decision = Denied, reason "volume-exceeds-policy".
- RN-04 (ROUTE): no active policy for the vehicle's tenant. Violation: decision = Review, never Approved.

## 10. Observability
- Event authorization.decided {id, decision, reason}; one log line per state change.

## 13. Acceptance Criteria
- CA-F1-01 (SC-01, RN-03): Given maxLiters = 50, request 60, then decision = Denied with reason "volume-exceeds-policy".
- CA-F1-02 (SC-01, RN-03): Given maxLiters = 50, request 40, then decision = Approved.
- CA-F1-03 (SC-02, RN-04): Given no active policy, then decision = Review.
- CA-FINAL-01: no new test failure relative to the baseline recorded at the start (12 failing before, listed in section 14).

## 14. Implementation Plan
| Phase | Scope | Depends on | Deliverable |
| 1 | Policy model + decision endpoint | None | POST /authorizations |

#### Phase 1 - Policy model and decision
- Goal: decide Approved, Denied or Review for a request.
- Files: src/policy/policy.schema (new), src/authorization/authorization.service (new), tests in src/authorization/authorization.spec.
- Tests: deny_when_volume_exceeds_policy (RN-03), approve_valid_volume (RN-03), review_without_policy (RN-04).
- Criteria covered: CA-F1-01, CA-F1-02, CA-F1-03.
- Validation: <the project's test command>; expected: the three tests pass, no new failures.

## 15. Open Questions
- AQ-01: What is the default threshold when a tenant has several policies? Owner: operator.
```

From this, an agent can generate the schema, the service, the endpoint and the three tests, and `/review` can check each rule and criterion by id.

## Writing guidelines

1. **Explore before writing.** `/proposal` reads the code first. Use real paths and the project's real syntax.
2. **One idea per rule.** If a rule contains "and", it probably needs two ids and two tests.
3. **State violations.** A rule without a violation behavior cannot be tested.
4. **Use literal values in criteria.** Numbers, names, status codes. Avoid adjectives.
5. **Keep ids stable.** `SC`, `P`, `RN`, `CA`, `AQ`, `D`, `R`, `B` ids are never renamed or reused. New items take the next number. Reviews and tests cite them.
6. **Make unknowns explicit.** An open question with an owner (`operator`, `proposal`, `spike`, `deferred`) beats a guess. Blocking questions are answered before the phase that needs them.
7. **Measure honestly.** If a benefit cannot be measured in this delivery, say so instead of inventing a number.
8. **Name baselines.** "Tests pass" is not verifiable by someone whose change did not break them; "no new failure relative to the recorded baseline" is.
9. **Amend visibly.** When implementation disproves the spec, add an amendment note below the original text.

## Self-check before approving a Proposal

- Can an agent implement each phase from this document alone, with no questions?
- Is every rule testable, and covered by at least one criterion?
- Does every criterion trace to a scenario?
- Are there any "TBD", "etc.", "similar to", or unnamed baselines?
- Does every phase have files, tests mapped to rules, criteria and validation commands?
- Do open questions have owners, and are the blocking ones answered?
