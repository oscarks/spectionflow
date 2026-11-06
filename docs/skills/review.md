# `/review`

## Purpose

Reviews an implemented phase (or the whole feature) against its AI-SPEC (the executable spec of the phase) and its Proposal (the what/why): spec compliance, business rules, acceptance criteria, code quality, tests, static analysis and build. A `final` review checks the whole feature against the Proposal and every phase's AI-SPEC. It writes a review document with evidence-backed findings and a verdict.

## When to use / not use

Use it after `/implement` for a phase, and once more for the whole feature (`final`).

Do not use it to fix code: the reviewer reports, the implementer fixes. Do not expect it to delegate to sub-agents; it investigates and measures itself.

## Invocation and arguments

```
/review <Feature> [phase N | final]
```

With no phase, the skill infers the latest implemented phase from the diff and the Proposal and states its inference.

```
/review Notification_Retry phase 1
/review Notification_Retry final
```

## Inputs read

- The Proposal in full (rules, criteria, decisions, principles, open questions, the phase roadmap) and the AI-SPEC of the phase in full (Scope, Solution, Tests, Acceptance Criteria, Traceability, validation commands). For `final`, every phase's AI-SPEC. If the Proposal is missing, or the AI-SPEC of a reviewed phase is missing, the skill stops and tells you (for the latter, to run `/ai-spec <Feature> phase N`).
- Earlier `Review_Phase_*_<Feature>.md` files of the same feature (so it does not contradict or re-report settled points).
- README, `CLAUDE.md` / `AGENTS.md`, manifests: stack and the build/lint/format/type-check/test commands.
- Architecture decision records the Proposal references (checked to be still in force).
- The git diff against the integration branch (`git -C <repo-root> diff <base> --stat`, `--name-only`, `log <base>..HEAD --oneline`), and **every new or modified file in full**. No spot-checking.

## Outputs written

- Phase review: `docs/features/<Feature>/Review_Phase_<N>_<Feature>.md`
- Final review: `docs/features/<Feature>/Review_Final_<Feature>.md`

The feature name is part of the file name. The skill never overwrites a `Review_*` file it did not produce in this run; it picks a distinct suffix and says so. Section list: [artifacts](../artifacts.md#review).

## What the skill does, step by step

Phase 0 prepares (argument, Proposal, earlier reviews, project, diff, files, date). Then the document sections:

1. **Spec compliance**: 1.1 AI-SPEC compliance: Scope (everything In scope exists; nothing Out of scope was built) and each Solution item (files, data model, contracts, logic, state machine, error handling) checked at its stated path, plus the AI-SPEC's Traceability table (every row's file and test exist). Deviations are classed MISSING = CRITICAL, DIVERGENT = MAJOR, EXTRA = MINOR. 1.2 Proposal alignment: no rule weakened or dropped between Proposal and AI-SPEC; decisions and principles followed. Open questions silently resolved by the code are reported.
2. **Business-rule traceability**: a row per `RN-NN` with implemented?, `File:line`, tested?, test. Verdicts COVERED, UNTESTED (MAJOR), PARTIAL, MISSING (CRITICAL). A rule implemented in several layers needs evidence in each layer.
3. **Acceptance criteria**: PASS / FAIL / NOT VERIFIABLE per `CA-F<N>-NN` with evidence. A phase review **never emits PASS or FAIL on a `CA-FINAL-*`**: they are `NOT VERIFIABLE` there; only the final review judges them.
4. **Code review**: architecture and patterns, data isolation (if multi-tenant or per-owner data), security, quality, error handling.
5. **Cross-layer consistency**: ALIGNED or DRIFT for data-model vs. contract fields, validation vs. rules, routes vs. API contract, response types vs. client models, client paths vs. server routes, i18n keys vs. locale files.
6. **Migrations and seeds** (if the project has them).
7. **Testing validation**: run the suites (never trust the implementation report), completeness table, every `T-F<N>-NN` of the AI-SPEC's Tests section exists in the code and covers its mapped RN/CA (`grep -rn '<ID>'`; a phantom test is traceability fiction), **invariant guards - mutation sampling (mandatory)**, duplicated catalogs, test doubles for third-party dependencies.
8. **Static analysis and build**: lint, type check, format *check*, schema validation, build; a check that did not run is `NOT RUN` with the reason, never counted as PASS.
9. **Documentation and best practices**.
10. **Findings register and verdict**: findings `F-NN`, statistics, positive highlights, what to do with findings, **Deferred items**.

### Mutation sampling (7.5)

For each guard the phase introduced or changed: back up the file and record its checksum, make the temporary edit, run the tests, restore **by copying the backup over the original**, compare checksums. Report a table naming the test that went red. A guard with no discriminating test is MAJOR; the fix is one test. For guards that recognize N syntactic forms (regex, parser, filter), one test case per form. The sampling fraction is declared (for example "3 of 5", or "0 of 4"). "The line is covered" and "the suite passes" are not proof.

### Verdict

- **APPROVED**: zero CRITICAL, zero MAJOR; all tests pass; all in-scope acceptance criteria PASS.
- **APPROVED WITH OBSERVATIONS**: zero CRITICAL, zero MAJOR; MINOR findings or observations exist.
- **CHANGES REQUIRED**: any CRITICAL or MAJOR, any criterion FAIL, or any failing test.

The verdict must be coherent with the register.

## Rules and guardrails

- **Evidence over assertion**: every verdict cites a real path (and line) or a command output you ran.
- **The reviewer does not fix.** Findings go into the document. When the fix is trivial, write a suggested diff inside the finding. Never rewrite a verdict after the fix; a new review pass issues the new verdict. Only errors in the review document itself (typos, numbering) are fixed.
- Verification edits (mutation) are allowed and must be undone by backup copy and checksum, never by `git checkout --`, `git restore`, `git stash`, `git reset --hard` or `git clean`.
- **No sub-agents.** If the scope is too large for one session, the verdict says so.
- Never transcribe secrets; cite the path only.
- Files the project marks as ignored are not reviewed.
- Severity scale: CRITICAL and MAJOR block merge; MINOR and OBSERVATION do not.

## Human checkpoints

- Asks you when a build/test command is unclear.
- Its verdict is advisory to you: `CHANGES REQUIRED` sends the phase back to `/implement`; you decide about deferred items.

## Common mistakes

- Judging `CA-FINAL-*` criteria in a phase review.
- Reviewing against the Proposal only: the AI-SPEC's Scope, Solution, Tests and Traceability table are what the phase was built from.
- Letting a rule weakened between Proposal and AI-SPEC go unreported.
- Crediting "the suite passes" as proof that a guard is observed.
- Citing a test id without grepping that it exists.
- Quoting the implementer's claims instead of running the commands.
- Editing the reviewed code, or changing a verdict after the fix.
- Counting a check that was not run as PASS.
- Declaring "adequate coverage" without the sampling fraction.

## Worked example

```
/review Notification_Retry phase 1
```

Excerpt of `docs/features/Notification_Retry/Review_Phase_1_Notification_Retry.md`:

```markdown
# Review - Notification_Retry - Phase 1: Retry scheduling

**Date**: 2026-11-06
**Proposal reviewed**: docs/features/Notification_Retry/Proposal_Notification_Retry.md
**AI-SPEC reviewed**: docs/features/Notification_Retry/AI-SPEC_Notification_Retry_Phase_1.md
**Phase / scope**: phase 1
**Verdict**: CHANGES REQUIRED

## 2. Business-rule traceability
| Rule | Implemented? | File:line | Tested? | Test |
|---|---|---|---|---|
| RN-01 | YES | `src/jobs/retry.ts:27` | YES | `src/jobs/retry.test.ts:retry reschedules on 503` |

## 3. Acceptance criteria
- CA-F1-01: PASS (test above, run: 1 passed)
- CA-FINAL-01: NOT VERIFIABLE (cross-phase; depends on phase 2)

## 7.5 Invariant guards - mutation sampling
Sampled 2 of 2 guards.
| Guard | File:line | Mutation applied | Test that failed | Verdict |
|---|---|---|---|---|
| only 5xx/network retried | `src/jobs/retry.ts:27` | inverted the condition | `does not retry 400` | ✅ proven |
| missing job id rejected | `src/jobs/retry.ts:14` | deleted `if (!id) throw` | none | ❌ no discriminating test |

## 10. Findings register and verdict
| Id | Severity | Section | Description | File:line | Suggested fix |
|---|---|---|---|---|---|
| F-01 | MAJOR | 7.5 | Guard against a missing job id has no discriminating test | `src/jobs/retry.ts:14` | add a test calling `retry(undefined)` and expecting a throw |

### Deferred items
None.
```
