# `/pipeline`

## Purpose

Runs the whole development flow for one feature in the current session by chaining the other skills: optional analysis advisory, `/proposal`, human approval, then per phase `/ai-spec`, `/implement` and `/review` with a bounded fix loop, acceptance-criteria verification, a final review, fixes and a summary.

The pipeline only **orchestrates**. `/analysis`, `/proposal`, `/ai-spec`, `/implement` and `/review` do the work and write their own artifacts; the pipeline invokes each by name, reads what it produced and decides the next step.

## When to use / not use

Use it to run or resume the full flow for a feature. Do not use it for a single step; call that skill directly. For features with more than 5 phases, prefer batches of 3 to 4 phases (the skill warns you).

## Invocation and arguments

```
/pipeline <Feature> [A | B] [all | phase N | resume]
```

| Token | Meaning |
|---|---|
| `A` (default) | Mode A: every step runs in the current session |
| `B` (or `subagent`) | Mode B: every step runs in a fresh sub-agent (see [Execution modes](#execution-modes)) |
| `all` (or nothing) | every phase in scope |
| `phase N` (or a bare integer) | only phase N; steps 4 to 6 (cross-phase) are skipped |
| `resume` | continue from the first incomplete step; never asks to restart |

```
/pipeline Notification_Retry all
/pipeline Notification_Retry phase 1
/pipeline Notification_Retry resume
/pipeline Notification_Retry B all      # each step in a fresh sub-agent
```

The feature name is normalized to `PascalCase_With_Underscores` and matched against existing directories under `docs/features/` (case-insensitive) before anything is created.

## Execution modes

- **Mode A (default)**: the pipeline calls each skill in your current session. Simple; the whole history stays in one context, which can run out on long features.
- **Mode B (sub-agents)**: the pipeline is a thin orchestrator and dispatches every step (`/proposal`, `/ai-spec`, `/implement`, `/review`, each fix round) to a fresh sub-agent. Each step starts with a clean context, and the reviewer never inherits the implementer's reasoning. If your agent has no sub-agent tool, the pipeline says so and continues in Mode A.

Mode B rules: one step at a time, never in parallel; the orchestrator keeps the human checkpoints, the progress file and the conversation with you (sub-agents never ask you anything — they return the question); each sub-agent gets a complete brief (feature, step, artifact paths, project commands, scope) and returns at most 10 lines; the orchestrator verifies the artifact on disk instead of trusting the report; `/review` always runs in a different sub-agent than the `/implement` of the same phase; a failed or empty result is retried once, then the run halts. Fix-round limits and stop conditions are the same as in Mode A.

## Inputs read

There is no state file. State is derived from the artifacts in `docs/features/<Feature>/`:

| Artifact | What it tells the pipeline |
|---|---|
| `Analysis_<Feature>.md` | an analysis exists (advisory only) |
| `Proposal_<Feature>.md` | its `Status`; its Implementation Plan (the phase roadmap) lists the phases |
| `AI-SPEC_<Feature>_Phase_<N>.md` | the phase spec exists; its `Status` (Draft / Approved / Implemented / Superseded) |
| `Review_Phase_<N>_<Feature>.md` | latest verdict of phase N |
| `Review_Final_<Feature>.md` | final review done, verdict |
| `Progress_<Feature>.md` | optional checklist (convenience only) |

A phase is **done** if its review exists, is non-empty and the verdict is APPROVED or APPROVED WITH OBSERVATIONS; **needs fixes** if CHANGES REQUIRED; **implemented, unreviewed** if the AI-SPEC Status is Implemented (or its files exist) but there is no review; **specified** if an AI-SPEC exists but is not Implemented (needs `/implement`); **pending** if there is no AI-SPEC yet (needs `/ai-spec`). If artifacts and checklist disagree, the artifacts win.

## Outputs written

- `docs/features/<Feature>/Progress_<Feature>.md`: a human-readable checklist, written only by this skill and updated after each step; no other skill depends on it.
- Everything the sibling skills write (Proposal, AI-SPECs, code, reviews). The checklist has one line per phase covering ai-spec, implement, review and fix rounds.
- Proposal `Status` changes: `Approved` (after your approval), `In Progress` (first phase starts), `Implemented` (final review passes).

## What the skill does, step by step

0. **Arguments and state.** Parse, derive state, print a status table. If prior progress exists and you did not pass `resume`, ask once: resume or restart. Restart never deletes silently: it lists the artifacts and asks for confirmation. A re-review keeps the earlier pass in a revision-history table. If scope is `all` with more than 5 phases, warn and offer a range.
1. **Proposal.** Skip if a non-empty Proposal exists with a Status other than Draft/Superseded. Otherwise note any Analysis (or mention once that `/analysis` can reduce risk when uncertainty is real; never blocking), invoke `/proposal`, verify the file has an Implementation Plan (phase roadmap) and acceptance criteria. **Checkpoint: you approve the Proposal.**
2. **Identify phases** from the Implementation Plan roadmap. Phase numbers are identities and are never renumbered.
3. **Phase loop**, for each in-scope phase, in roadmap order:
   - **3-spec** if `AI-SPEC_<Feature>_Phase_<N>.md` does not exist, invoke `/ai-spec <Feature> phase N` (the pipeline never writes it itself) and show you a short summary: scope, main files, tests, criteria covered. In `all` mode it proceeds automatically unless you asked to review specs; in a `phase N` run it stops for your OK, because the AI-SPEC is the contract `/implement` follows. If you ask for changes, `/ai-spec` is re-run with your feedback. A Draft AI-SPEC accepted this way counts as approved.
   - **3a** invoke `/implement` (it follows the AI-SPEC and sets its Status to `Implemented`); check every file the AI-SPEC's Solution lists exists; run build and tests; new failures mean the implementation failed and are fixed before review.
   - **3b** invoke `/review`; on CHANGES REQUIRED start a fix round: `/implement` pointed at the review file, rebuild/retest, `/review` again; repeat until APPROVED or APPROVED WITH OBSERVATIONS. **At most 3 fix rounds per phase**, then stop and hand over to you.
   - **3c** if the phase refuted something the Proposal asserts, amend the Proposal now with an amendment note (original text kept, what is true now added), not silently and not at the end.
4. **Acceptance-criteria verification** (scope `all` only): check evidence for each `CA-F<phase>-NN` and `CA-FINAL-NN`, grep every cited test id, classify what needs execution as **NOT VERIFIED (needs execution)**, print the result block. On FAIL ask: fix [f] or continue anyway [c].
5. **Final review and fixes** (scope `all` only): `/review final`; fix CRITICAL, MAJOR and MINOR findings through `/implement` (same bound of 3 rounds; a surviving CRITICAL always stops). On success, Proposal Status becomes `Implemented`.
6. **Completion summary**: scope, phases processed and fix rounds, acceptance criteria counts, final verdict, deferred items, criteria not verified, next step.

## Rules and guardrails

- Orchestrate, do not duplicate: never write proposals, AI-SPECs, code or reviews in place of the sibling skills.
- Artifacts are the source of truth; a step is never marked done without its non-empty artifact.
- Gates: no implementation without an approved Proposal and an AI-SPEC for the phase; no phase is complete without a review whose verdict is APPROVED or APPROVED WITH OBSERVATIONS.
- Reviewers do not fix; fixers do not approve. The verdict always comes from a fresh `/review`.
- Fix rounds fix only the listed findings.
- A failing step halts the run; `resume` continues from there.
- Timestamps come from `date`; secrets found in config or env files are never printed.
- "Not verified" criteria are not "almost passed".

## Human checkpoints

- Answering `operator`-owned open questions and approving the Proposal.
- Reviewing the AI-SPEC of a phase before implementation (automatic in `all` mode unless you asked to review specs; a stop in a `phase N` run).
- Choosing resume vs. restart; confirming a restart.
- Narrowing scope after the phase-count warning.
- Deciding what to do after 3 failed fix rounds (more rounds, change approach, amend the Proposal, abort).
- Choosing fix vs. continue when acceptance criteria fail.

## Common mistakes

- Running `phase N` and expecting the final review and Proposal `Implemented` status; those need a run without a filter.
- Editing `Progress_<Feature>.md` by hand and expecting it to override the artifacts.
- Running `all` on a 9-phase plan in one go.
- Treating "not verified" criteria as passed.

## Worked example

```
/pipeline Notification_Retry all
```

Initial status table and the end of the run:

```
Step                         Status
Analysis (advisory)          found
Proposal                     Draft  -> awaiting approval
Phase 1 - Retry scheduling   pending (no AI-SPEC)
Phase 2 - Backoff and limit  pending (no AI-SPEC)
AC verification              pending
Final review                 pending
```

After you approve and the phases pass:

```
Pipeline finished: Notification_Retry
Scope            : all
Phases processed : 2 of 2   (fix rounds: phase 1 = 1, phase 2 = 0)
Acceptance crit. : 4/5 passed, 0 failed, 1 not verified
Final review     : APPROVED WITH OBSERVATIONS
Deferred items   : 2 (Review_Final_Notification_Retry.md, "Deferred items")
Not verified     : CA-FINAL-02 (needs a real customer endpoint; needs a staging environment)
```

Excerpt of `Progress_Notification_Retry.md`:

```markdown
# Progress - Notification_Retry

**Last update**: 2026-11-06 15:42

- [x] Analysis (optional) - Analysis_Notification_Retry.md
- [x] Proposal - Proposal_Notification_Retry.md (Status: Implemented)
- [x] Human approval of the proposal
- [x] Phase 1 - ai-spec (AI-SPEC_Notification_Retry_Phase_1.md) | implement | review (verdict: APPROVED) | fix rounds: 1/3
- [x] Phase 2 - ai-spec (AI-SPEC_Notification_Retry_Phase_2.md) | implement | review (verdict: APPROVED) | fix rounds: 0/3
- [x] Acceptance-criteria verification (4/5 passed)
- [x] Final review (verdict: APPROVED WITH OBSERVATIONS)
- [x] Final fixes
- [x] Completion summary
```
