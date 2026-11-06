---
name: ai-spec
description: Generate the AI-SPEC for one phase of an approved Proposal - an executable technical specification (design, rules, state machines, tests, traceability) that an AI agent can implement without asking questions. Use when the user asks for a spec or AI-SPEC for a feature or phase, after the Proposal is approved.
argument-hint: <Feature> [phase N]
---

# /ai-spec - Executable specification for one phase

Part of Spectionflow. The **Proposal** says WHAT and WHY. The **AI-SPEC** says HOW, for exactly one phase, precisely enough that an AI agent can implement it **without guessing and without asking**. If an implementer would have to ask a question, the spec has failed.

Input: `$ARGUMENTS` = `<Feature> [phase N]`. Without `phase N`, spec the next phase that has no AI-SPEC yet (Phase 1 if the Proposal has a single phase).

Output: `docs/features/<Feature>/AI-SPEC_<Feature>_Phase_<N>.md` (single-phase features still use `Phase_1`). `<Feature>` is PascalCase_With_Underscores. Write the document in the language the project docs use; keep the section headings in English.

## Preconditions

- Read `docs/features/<Feature>/Proposal_<Feature>.md`. If it does not exist or its Status is not `Approved` (or later), **stop** and tell the user to run `/proposal` and approve it first.
- Never invent scope. Everything in the spec must trace to the Proposal's rules (RN-NN) and acceptance criteria (CA-F<phase>-NN, CA-FINAL-NN) for this phase. If you find a gap in the Proposal, report it to the user instead of silently filling it.
- If an AI-SPEC already exists at the target path, read it and ask whether to update it or replace it.
- Dates come from the system `date` command, never from memory.

## Phase 0 - Exploration (mandatory before writing)

1. **Learn the project.** Read README, CLAUDE.md / AGENTS.md (if any), package/build manifests, and the test/lint/build commands. Never assume a stack; derive layout, naming, test framework and conventions from the repo. Ask only if something essential stays unclear.
2. **Read the Proposal thoroughly**: chosen option, decisions (D-NN), rules, criteria, risks, the phase roadmap entry for phase N (goal, scope, criteria covered, dependencies). The spec must not contradict any of it.
3. **Read upstream context if present**: `docs/features/<Feature>/Analysis_<Feature>.md`, `docs/inception/` (Product Definition, Scope and Milestones), and any architecture decision records the project keeps. Check that a decision you rely on is still current.
4. **Read the previous phases' AI-SPECs and the code they produced**, so this phase builds on what is real, not on what was planned.
5. **Explore the existing code the phase touches or depends on**: data definitions, services/logic, entry points (API handlers, commands, jobs, event consumers), interface code, and tests. Record real paths. **Verify every path you will cite**: files to modify must exist; files to create must have an existing parent directory that follows the project's layout.
6. **Find the patterns to follow.** For each kind of artifact you will specify (a new service, a new entry point, a new screen, a new test), locate one existing example and reference it by path.
7. **Find existing tests that read what you will change** (see Self-check, item 1).

Record findings in section 3 (Current State). Decisions taken during exploration (for example: how an ambiguity in the Proposal was resolved) go into the spec's Description or Scope, stated explicitly.

## Writing in two passes

Long specs are lost when the session dies mid-write, and the exploration is the expensive part. So:

**Pass 1 - skeleton** (one small write, right after Phase 0): the header, all 15 section headings in order, the IDs already allocated (RN, CA, T) with one line each, the decisions fixed during exploration, and a line `> SKELETON - body pending` under the header.

**Pass 2 - body**: write the sections and remove the skeleton line in the same write as the last section. A document that still carries that line is incomplete and says so.

## The document

Use exactly these headings, in this order. A section that does not apply stays, with one line saying why (for example "No integrations in this phase.").

```markdown
# AI-SPEC: <Title> - Phase <N>: <Phase name>

**Feature**: <Feature>
**Phase**: <N> of <M>
**Status**: Draft
**Date**: YYYY-MM-DD
**Proposal**: docs/features/<Feature>/Proposal_<Feature>.md
**Related**: <previous/next phase specs, analysis, decision records - or "None">
```

Status values: `Draft | Approved | Implemented | Superseded`. Write `Draft`. Set `Approved` only when the user says so in conversation. `/implement` sets `Implemented` when the phase is done.

### 1. Description
1-3 paragraphs: what this phase delivers and why, consistent with the Proposal's solution vision. Then a numbered list of the phase's capabilities, one sentence each. It must answer: what value does this phase deliver?

### 2. Scope
- **In scope**: numbered list of what this spec covers, tied to the Proposal's phase roadmap.
- **Out of scope**: numbered list of what is explicitly not covered, each with a reason and where it goes (a later phase, another feature). This is what stops scope creep during implementation.

### 3. Current State
What exists today, verified, with real paths. Use a table adapted to the project's layers:

| Aspect | State (Exists / Partial / Missing) | Path / reference |
|---|---|---|
| Data definitions | ... | `<path>` |
| Business logic | ... | `<path>` |
| Entry points | ... | `<path>` |
| Interface | ... | `<path>` |
| Tests | ... | `<path>` |

Also list what is stub vs. fully implemented, what is missing, and what must be **modified** (not just created). This prevents duplicated code and re-implementation.

### 4. Solution
The technical design, written **in execution order** so the implementer can follow it top to bottom. Think in layers, mapped onto the project's real structure: **data, contracts, logic, entry points, interface, tests**. Cover, in this order:

1. **Overview**: a short diagram (ASCII or Mermaid) showing how the pieces interact and where they plug into existing code. Use only the option approved in the Proposal.
2. **Files**: the exact files to create and to modify, with real paths and each file's responsibility. Mark modified files `MODIFY`. Follow the project's naming and layout.
3. **Data model**: complete definitions in the project's actual syntax (fields, types, defaults, relations, constraints, indexes, enums) - not pseudo-code, not descriptions. For changes to existing structures, show only the delta. For each entity list its **domain invariants** as machine-checkable predicates, for example `INV-01: quantity > 0`, `INV-02: endsAt >= startsAt`, `INV-03: status in {DRAFT, PUBLISHED, ARCHIVED}`. If an entity has no non-trivial invariant, say so.
4. **Contracts and interfaces**: every request/response shape, function signature, event payload or message the phase introduces, with field names, types, optionality and validation. Separate create/update/read shapes. Never expose sensitive fields in outputs.
5. **Logic and business rules**: the rules from the Proposal that apply to this phase, each as:
   `RN-NN [BLOCK|WARN|INFO]: <description>. Holds when: <boolean expression over named fields>. Violation: <exact outcome - error/status/message or log>.`
   - `BLOCK` = rejected; `WARN` = allowed but flagged/logged; `INFO` = informative.
   - The expression must be deterministic and reference only fields and inputs defined in this spec - no "if reasonable". It is the oracle the code enforces and the test asserts.
   - Do not write a rule's expression as a comparison against version-control state (`git diff` against `HEAD`): it cannot be evaluated when phases land uncommitted. Compare against a copy of the protected files taken at the start of the phase.
   - Every RN of the Proposal that falls in this phase's scope appears here.
6. **State machine** (for every entity with a lifecycle): the exact set of states with the initial state; transitions one per line as `From -> To [guard] (actor/event)`, for example `Requested -> Approved [score >= policy.threshold] (Reviewer)`; terminal states; auto/timed transitions. Any transition not listed is forbidden and must be rejected. If there is no lifecycle, say so.
7. **Flows**: sequence diagram for each non-trivial flow - at minimum the main path and the most important error path - showing which layer handles each step.
8. **Error handling**: a table of every error the phase can produce: where, condition, outcome (status/code), message. This is the contract between the logic and whatever consumes it.
9. **Limits of each guarantee**: for every guarantee the spec asserts ("X always wins over Y", "no path does Z"), state under which condition it is false, whether that state is reachable today and how, what actually happens there, and, if you chose not to close it, why. A false guarantee is worse than a missing one; an unstated capability is equally false. If you cannot list the limits, you have not understood the guarantee yet.

### 5. Interface
Only if the phase has a user-facing or consumer-facing surface (screens, CLI, public API). For each surface: where it lives (route/command/path), file(s), inputs and outputs, component or command hierarchy, states (loading, empty, error, success, validation), navigation entry, and an ASCII wireframe for non-trivial screens. User-visible strings follow the project's existing convention for text (constants, translation files, etc.); list new ones. Paths and names that must match the logic layer (endpoints, event names) are copied exactly. If none: "No interface in this phase."

### 6. Integrations
How the phase connects to existing modules and external systems: direction, endpoint/event/function, payload. Event and message handlers must be idempotent (safe to replay). If none: "No integrations in this phase."

### 7. Security
Cover the project's real access model; include only what applies: authentication and authorization per entry point (default to the most restrictive, open explicitly), data isolation/ownership if the project has multiple tenants or owners, and a data-sensitivity table (field, classification, handling - never returned, masked in logs, etc.). If nothing sensitive: say so.

### 8. Performance
Indexes or lookup structures with the query each one serves; pagination or batching limits (default and maximum); known risks (N+1 access, unbounded lists, full scans) with mitigation. Replace every vague word with a number and unit ("p95 < 200 ms", "at most 50 items").

### 9. Observability
- **Telemetry**: logs and events - what, when, level, payload, who consumes it.
- **Audit**: for sensitive or state-changing actions (money, permissions, sensitive data, lifecycle transitions), an append-only record of who did what to what and when. For each audited action: actor, action, target, before -> after, timestamp, reason; where it is stored and that it is immutable.
If nothing applies, say so explicitly.

### 10. Tests
Tests are mandatory for every new unit of logic, entry point and non-trivial interface component. Use the project's test framework and the patterns of the existing tests.

Each scenario has an ID `T-F<phase>-NN`, a level (`unit | integration | e2e`), the RN(s) and CA(s) it covers, and concrete steps and assertions:

```
T-F1-01 [unit] covers RN-02, CA-F1-01: <Class/function> - <behaviour>
  Given: <precondition>
  When: <action>
  Then: <observable result>
  Assert: <specific assertion, not "it works">
```

Rules for the scenarios:
- Every RN has at least one scenario for the violating case and one for the holding case. Every state-machine transition (allowed and forbidden) and every invariant is exercised.
- A check that depends on *finding* something (a log line, a key, "the file contains X") also needs a positive control that fails if the target disappears; otherwise it stays green and empty when the target is renamed.
- Assert on a list by naming its items; never iterate the list under test (`LIST.every(...)` goes green exactly when an item vanishes from the list).
- If the phase uses a third-party SDK/CLI/API, specify the test double here: the real type it must conform to, a recorded real sample (with package version and date), and a drift check against the installed version. A double simpler than the real contract leaves the suite blind and passing.
- End the section with how to run: the exact commands (unit, integration, e2e) discovered in Phase 0. If a layer has no test infrastructure, say so explicitly.

### 11. Migration / Seed
If the phase changes persisted data: the migration (name per the project's tool, what it does, flagged if destructive or lossy, and the transformation for existing data); exact seed data (not "add some examples"), idempotent; new configuration/environment variables (name, meaning, default, required). If none: "No migration or seed in this phase."

### 12. Dependencies
New packages with exact version range, layer, and justification. If none: "No new packages."

### 13. Acceptance Criteria
List the phase's `CA-F<phase>-NN` copied from the Proposal and refined until each is objectively verifiable (pass/fail), each with its **verification method** (which test ID, or which command/manual check). Add `CA-FINAL-NN` only if the Proposal assigns them to this phase. Cover happy paths, data integrity, error handling, edge cases (empty inputs, maximum lengths, boundaries), and authorization/isolation where the project has them.

A criterion that asserts "nothing changed" must name the reference state and the point at which it is measured ("after extraction, the output of the 8 routes is identical to the baseline at commit <sha>"). Never freeze a file and a constant derived from it at the same time - the two criteria would contradict each other at implementation time.

### 14. Traceability
One table for the whole phase:

| Requirement (Proposal) | RN | CA | Test | File / area |
|---|---|---|---|---|

Every RN and CA of the phase appears at least once; every row is complete; every test and file exists in the spec.

### 15. Self-check
The author's own cross-check, written into the document. Record what you searched for and what you found, not just "OK". See next section for the procedure and format.

## Self-check (procedure for section 15)

The target is narrow and verifiable: **collision between what this spec prescribes and a test** - one the spec prescribes itself, or a pre-existing test it promises not to break. In practice, specs have contradicted themselves in ways that only surfaced during implementation. Search deliberately:

1. **Who reads what you will write.** For each file the spec creates or modifies, search the repo for tests that read it - by path and by basename, across the whole test surface. When the spec **moves** content from one file to another, the source file still exists and a path search finds nothing: also search all test files (including oddly named ones) for the **literals** that will change file.
2. **Guards on the touched surface, read in full** - lint rules, contract tests, snapshot tests, naming checks - not by their name or header comment.
3. **Pre-existing assertions your prescriptions would violate.** For each literal, label, header, id or filename the spec orders written, look for an assertion that forbids it or derives it from another source.
4. **Every count in the spec** ("the 6 files", "the three checks", "the four layers"): recount against the table or list next to it. This is the class that repeats most and is the cheapest to catch.
5. **The spec against itself**: the tests this spec prescribes versus the content this spec prescribes.
6. **The new document against the corpus**: run the project's test suite with the document on disk; a repo-wide check can react to the file you just wrote.

Then verify the standing invariants of a good spec:
- Every CA has at least one test; every RN appears in Solution and in a test; every path cited was verified to exist (or its parent does, for new files); nothing outside Scope; no `TODO`/`TBD`/"etc."/"similar to X"; every count is right.

Format of section 15:
- A paragraph **What was searched, and how**, followed by a numbered list of at least 3 items, each citing the command, path or measurement that produced it (a result without its search cannot tell an empty sweep from a complete one).
- A table of candidate collisions: `| # | Candidate collision | Checked in | Verdict | What changed in the spec |` with verdict in the closed set `real | self-inflicted | discarded`.
- A final line with counts taken from the table, never estimated: `self-check: candidates=<N> real=<A> self-inflicted=<B> discarded=<C>` where `N = A + B + C`.

Be honest about the limit: this proves what was searched, not that the search was good. Fix every `real` and `self-inflicted` finding in the spec before finishing.

## Writing rules

1. **No ambiguity.** Every field, rule, flow and path is fully specified. If the implementer must ask, rewrite.
2. **No placeholders.** Never "TBD", "to be defined", "similar to X", "etc.", "as needed". Spell it out or mark it explicitly out of scope with a reason.
3. **Exact names.** File paths, entity names, function and endpoint names, component names - the exact ones to use, following the project's conventions.
4. **Reference existing code** when a pattern must be followed: cite the file and the pattern.
5. **Ban vague terms** ("fast", "adequate", "reasonable", "normal", "soon", "large"): replace with a threshold and unit, or name the policy value (`policy.maxQty`).
6. **Deterministic.** The same inputs always give the same decision. No rule, transition or scenario may depend on unstated context.
7. **Everything traceable has a stable ID**: invariants, rules, states, criteria, tests. Chain: requirement -> RN -> CA -> test -> file/area. IDs are never renumbered once written; if the Proposal's IDs are used, use them verbatim.
8. **Secure by default**: specify access for every entry point; default restrictive.
9. **Proposal alignment**: do not contradict its decisions, rules or chosen option. If the spec needs to change one, stop and tell the user.
10. **Concrete test assertions**: every scenario has specific `Assert` lines.
11. **Stack-agnostic wording**: describe layers in the project's own terms. Use framework-specific syntax only for what the project really uses, and only in code blocks.

## Quality checklist

Before finishing, verify:

**Executable-spec bars**
- [ ] Every entity with constraints lists domain invariants as predicates
- [ ] Every rule has an ID, a severity and a boolean expression over named fields, plus the violation outcome
- [ ] Every lifecycle has enumerated states and guarded transitions; unlisted transitions are rejected
- [ ] Telemetry and audit are specified for state-changing and sensitive actions (or explicitly "none")
- [ ] No vague terms; the spec is deterministic
- [ ] Each guarantee states its limits
- [ ] Traceability table complete: requirement -> RN -> CA -> test -> file/area

**Completeness**
- [ ] Files to create/modify listed with verified, real paths and execution order
- [ ] Contracts have types, optionality, validation; sensitive fields excluded from outputs
- [ ] Error table covers every failure path
- [ ] Access, isolation and data sensitivity covered per the project's real model
- [ ] Tests exist for every unit of logic, entry point and non-trivial component, with commands to run them
- [ ] Migration/seed idempotent and flagged if destructive
- [ ] Out of scope stated; nothing beyond the Proposal's phase scope
- [ ] Self-check section filled with searches, candidate table and counts that match the table
- [ ] An AI agent could implement this spec start to finish without asking a question

## Anti-patterns

- ❌ Writing the spec without exploring the code - invented paths and duplicate implementations follow.
- ❌ Rules in prose ("the system should validate sensibly") instead of an ID, a severity and a boolean expression.
- ❌ A state machine drawn as a diagram only, with no guards and no "unlisted transitions are forbidden".
- ❌ Scope added that the Proposal does not carry, or a decision of the Proposal quietly contradicted.
- ❌ Tests described as "verify it works", or a rule with no violating-case test.
- ❌ Guarantees asserted without their limits ("always", "never" with a reachable counter-case).
- ❌ Counts in prose that disagree with the table next to them.
- ❌ Moving content between files without searching for tests that assert the moved literals.
- ❌ Leaving `TBD`, "etc." or "similar to X" for the implementer to resolve.
- ❌ Dumping the whole spec in one write with no skeleton on disk first.
- ❌ Marking the spec `Approved` yourself.

## Finish

1. Re-read the Status line: `Draft`.
2. Summarize for the user in a few lines: the file path, phase scope, number of RN / CA / tests, any gap found in the Proposal, and any `real` self-check finding that was fixed.
3. Ask the user to review. Next steps: once the user approves the spec, run `/implement <Feature> phase <N>`.
