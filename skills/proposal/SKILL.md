---
name: proposal
description: Write a solution Proposal for a feature - the what and why (problem, solution, business rules, acceptance criteria, risks, decisions and a phase roadmap) from which /ai-spec derives one detailed spec per phase. Use before specifying or implementing a feature.
argument-hint: <Feature Name>
---

# Proposal

Write the solution Proposal for **$ARGUMENTS** (Spectionflow).

The Proposal is the **what and why** of the feature: the problem, the solution vision, the business rules, the acceptance criteria and a phase roadmap. It is not an implementation spec. After approval, `/ai-spec <Feature> phase N` derives the executable spec of each phase (files, contracts, tests), `/implement` builds from that AI-SPEC, and `/review` checks the code against the AI-SPEC and this Proposal. Be precise about behavior and rules; leave file-level detail to the AI-SPEC.

Write the document in the language the user and the project docs use. Section headings stay in English.

## Phase 0 - Exploration (mandatory before writing)

Never write from assumptions. Do all of the following first:

1. **Clarify the request.** If the scope is vague, ask. A proposal with the wrong scope wastes everyone's time.
2. **Discover the project.** Read the README, `CLAUDE.md` / `AGENTS.md` (if any), package/build manifests, and the existing docs. Derive stack, directory layout, test/lint/build commands, conventions, doc language. Do not assume a stack; if build/test commands are unclear, ask.
3. **Read optional inputs, if present.**
   - `docs/inception/` (`Product_Definition.md`, `Scope_and_Milestones.md`, `sources/`): the source of what/why. Align with it (problem, value, scope, constraints) and cite it; do not re-derive it.
   - `docs/features/<Feature>/Analysis_<Feature>.md`: read it first. Inherit its current-state findings and verdict. Every open question (`AQ-NN`) owned by `proposal` or `spike` and still unanswered is a **stop-and-ask**: ask the operator, do not guess. An unanswered `spike` means a recommended experiment never ran; do not proceed on that untested assumption unless the operator answers inline or explicitly waives it. Record the resolution in Design Decisions. If you diverge from the analysis verdict, say so there explicitly.
   - Related proposals under `docs/features/` and any architecture decision records: avoid contradicting them.
4. **Explore the code.** Find and read the modules, data models/schema, services, handlers/APIs, UI and tests this feature will touch or depend on. Record the real file paths.
5. **Declare the boundary of every measurement.** When a scan, benchmark or spike backs a claim, write next to the result what universe was swept and what was excluded and why. Exclusions hidden inside a script (a filter, a skipped range, a single encoder chosen) are the dangerous kind: the result inherits a boundary nobody declared.

Summarize what you found in "Current State". This prevents duplicate implementations.

## Location and naming

- Save as `docs/features/<Feature>/Proposal_<Feature>.md`. `<Feature>` is PascalCase_With_Underscores (e.g. `Notification_Retry`). Features live directly under `docs/features/`; there is no module level.
- If the file already exists, read it and ask whether to update it or write a new version.
- Take dates from the shell `date` command, never invent them.

## Document template

Use exactly this structure. Omit a section only if it genuinely does not apply, and say so in one line instead of deleting it silently.

### Header

```markdown
# Proposal: {Title} - {Subtitle}

**Date**: YYYY-MM-DD
**Status**: Draft | Approved | In Progress | Implemented | Superseded
**Affected areas**: {real modules/layers/surfaces of the project}
**Prerequisites**: {features/modules that must exist, with status: Implemented / In progress / Pending}
**External dependencies**: {libraries, APIs, services with exact versions, or "None new"}
**Estimated complexity**: Low | Medium | High | Very High
```

### 1. Problem and Motivation
- Current state and its limits, with real file paths.
- Concrete scenarios to address, numbered `SC-01`, `SC-02`...
- Consequences of doing nothing. The reader must be convinced WHY this matters.
- If an Inception or Analysis exists, cite it.

### 2. Solution Overview
- 1-3 paragraphs describing the solution; a diagram (ASCII or Mermaid) of the high-level shape.
- **Principles** `P-01`, `P-02`...: guiding principles that `/review` will later verify.
- **In scope** and **Out of scope**, each exclusion with its justification.

### 3. Current State
Table of what exists today, adapted to the project's real layers:

| Aspect | State (Exists / Partial / Missing) | Path / reference |
| --- | --- | --- |

Say what is stub vs. fully implemented, what is missing, and what must be **modified** (not just created).

### 4. Proposed Architecture
- **Data model**: full definitions in the project's actual schema syntax (not pseudo-code): fields, types, defaults, relations, indexes, constraints. For existing models show only the diff. Entity-relationship sketch.
- **Data flow**: diagram of how data moves across layers (user action -> interface -> API -> service -> store and back); lifecycle states for entities that have one; a sequence diagram for the main happy path and the most important error path.
- **Integrations**: how this connects to existing modules and external systems (direction, mechanism, payloads). Event handlers must be idempotent. Justify direct cross-module calls over events.
- **Components**: the modules/areas involved, following the project's real layout and naming; the operations/endpoints at contract level (purpose, auth, success and error behavior); UI views and state handling where there is a UI. Exact file lists, signatures and code structure are left to the AI-SPEC.
- **Alternatives**: for non-obvious choices, compare Options A/B/C in a table (simplicity, performance, extensibility, impact on existing code) and give a clear recommendation with the trade-offs accepted.

### 5. Business Rules
Numbered `RN-01`, `RN-02`..., grouped by sub-domain. Each rule must be **testable** (pass/fail, a developer can write a test from it) and state the violation behavior:

`RN-01: {rule}. Violation: {expected behavior - status code, error message, state}`

### 6. Security and Access Model
Only the parts that apply to the project's real access model: authentication/authorization (who can do what, and why), data isolation between tenants/owners (and how every query is scoped), sensitive fields that must never appear in responses, critical input validation, cross-scope leak scenarios and how each is prevented.

### 7. Performance and Scalability
Frequent queries and their indexes, pagination (defaults and max), N+1 / heavy-query risks and mitigations, expected data volume, caching.

### 8. Impact Analysis
Table of files/modules changed (change type, risk, description). Then: breaking changes (APIs, schema, contracts), migration path for existing data, rollback strategy. State explicitly anything this feature makes obsolete and how it is removed or migrated (or "Nothing becomes obsolete").

### 9. Risks and Mitigations

| # | Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R-01 | | Low/Med/High | Low/Med/High | concrete, not "we'll handle it later" |

Cover technical, dependency and business (misunderstanding) risks.

### 10. Observability
Events emitted, what is logged (creation, deletion, state changes, errors), metrics worth measuring.

### 11. Design Decisions
`D-01`, `D-02`...: WHY each key choice was made (structure, integration approach, trade-offs accepted). Include decisions inherited from the Analysis and any divergence from it. Recommend a separate architecture decision record when the choice is far-reaching. Cite only real existing decision records.

### 12. Expected Benefits
Numbered `B-01`... Each benefit resolves one or more `SC-NN` and states how success would be observed (a real, existing measure - a test, a query, an event - or an honest "not objectively measurable in this delivery, because ..."). Never invent a plausible number.

### 13. Acceptance Criteria
- Phase criteria: `CA-F<phase>-NN` (e.g. `CA-F1-03`) - objectively verifiable, pass/fail, tied to the phase that delivers them.
- Cross-phase / final criteria: `CA-FINAL-NN`.
- Cover: happy paths, key error scenarios, authorization and data isolation where they apply, i18n where the project is multilingual, performance if required.
- Every business rule `RN-NN` is covered by at least one criterion; every criterion traces to at least one scenario `SC-NN`.
- A criterion about a test suite must name its **baseline**: "no new failure relative to the baseline recorded at the start of the feature", never "the suite is green". The absolute form cannot be verified by whoever must satisfy it, because unrelated work can turn the suite red. Record the baseline numbers in the Proposal.

### 14. Implementation Plan (mandatory) - phase roadmap only
Break the work into **phases sized to be specified, implemented and reviewed one at a time**: each phase is independently deployable (no half-implemented feature in production) and can be verified on its own. This section is a roadmap; **no file-level detail** (paths to create, signatures, test files) goes here - that is the job of the per-phase AI-SPEC. One table:

| Phase | Name | Goal | Scope summary | Acceptance criteria covered | Depends on | Size |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | | one sentence | 1-3 lines of what is in | `CA-F1-01`.. | None | S / M / L |

Every `CA-F<N>-NN` belongs to exactly one phase; `CA-FINAL-NN` closes in the last phase. A small feature may have a single phase. Order phases so each leaves the system working. Validation commands (build / test / lint, with the baseline) are discovered in Phase 0 and recorded in the AI-SPEC of each phase.

### 15. Open Questions
`AQ-NN` with **question**, **owner** and **status**. Owner is one of: `operator` (must answer before approval), `proposal` (answer it here before finalizing), `spike` (needs a timeboxed experiment first), `deferred` (consciously postponed, with the reason and trigger). Questions that block a phase must be answered before that phase is implemented. Never rename or reuse an `AQ-NN`.

### Glossary (optional)
Only domain-specific or ambiguous terms.

## Writing rules

1. Explore before writing; reference real file paths; never invent paths, APIs or facts.
2. Use the project's actual schema/code syntax, not descriptions.
3. No placeholder text: never "TBD", "similar to X", "etc.", "as needed". Spell it out, or mark it OUT OF SCOPE with a justification, or raise it as an `AQ-NN`.
4. Present alternatives with a clear recommendation where the choice is non-obvious.
5. Keep IDs stable: once published, `SC`, `P`, `RN`, `CA`, `AQ`, `D`, `R`, `B` ids are never renamed or reused. New items take the next number.
6. Keep it actionable: someone writing the AI-SPEC of a phase from this document must not need to ask about behavior, rules or scope.
7. Check the proposal does not contradict existing decision records or approved proposals.
8. Status changes (Draft -> Approved -> In Progress -> Implemented) are made by editing the `Status` line; set `Approved` only when the operator approves in the conversation. Never write the proposal as already approved.

## Quality checklist (self-check before finishing)

- Phase 0 done; every referenced path is real.
- Current State reflects what actually exists today.
- Every new model has relations, indexes and constraints per the project's data layer.
- Every endpoint/operation has access rules, request/response and error cases.
- Every `RN-NN` is testable; every `RN-NN` is covered by a `CA`; every `CA` traces to an `SC`.
- Security and performance sections address the project's real access model and bottlenecks.
- Risks have concrete mitigations; benefits are measured honestly.
- The Implementation Plan is a roadmap only (no file-level detail), covers every acceptance criterion, and each phase is reviewable on its own.
- Open questions have owners; blocking ones are flagged.
- No contradiction with existing decisions; no placeholder text.

When done, report the path of the Proposal, the number of phases, and the open questions the operator must answer. Suggest the next step: review and approve the Proposal, then run `/ai-spec <Feature> phase 1` to produce the phase spec, then `/implement` and `/review` for that phase (repeat per phase).
