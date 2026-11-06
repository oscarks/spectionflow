---
name: pipeline
description: Orchestrate a whole feature in the current session - optional analysis, proposal, then per phase ai-spec, implement and review (with a bounded fix loop), acceptance-criteria verification, final review, fix and summary. Use when the user wants to run or resume the full development flow for a feature.
argument-hint: "<Feature> [all | phase N | resume]"
---

# Feature Pipeline (Spectionflow)

Run the full development flow for **$ARGUMENTS** by chaining the sibling skills. The pipeline only **orchestrates**: `/analysis`, `/proposal`, `/ai-spec`, `/implement` and `/review` do the work and write their own artifacts. Invoke each by name, read what it produced, decide the next step. Never copy or reimplement their content here.

All steps run in the current session. Documents are written in the language the user and project docs use; headings stay in English.

## Flow

```
[/analysis (optional advisory)] -> /proposal -> HUMAN APPROVAL
  -> per phase: /ai-spec -> /implement -> /review -> (fix loop) until APPROVED
  -> acceptance-criteria verification (all phases)
  -> final /review -> fix -> completion summary
```

## Step 0 - Arguments and state

### 0.1 Parse arguments

`<Feature> [all | phase N | resume]`

| Token | Meaning |
|---|---|
| `all` (or nothing) | every phase in scope |
| `phase N` (or a bare integer `N`) | only phase N; skip steps 4-6 (cross-phase) |
| `resume` | continue from the first incomplete step; never ask to restart |

Anything left after removing these tokens is the feature name. Normalize it to `PascalCase_With_Underscores` for paths: `docs/features/<Feature>/`. If the name is ambiguous, match it against existing directories under `docs/features/` (case-insensitive, non-alphanumerics equal) before creating anything.

### 0.2 Derive state from artifacts

There is no state file. Read the artifacts in `docs/features/<Feature>/`:

| Artifact | What it tells you |
|---|---|
| `Analysis_<Feature>.md` | An analysis exists (advisory only). |
| `Proposal_<Feature>.md` | Proposal exists; its `Status` line: Draft / Approved / In Progress / Implemented / Superseded. |
| Proposal "Implementation Plan" | The phase roadmap (number, name, goal, scope summary, acceptance criteria). |
| `AI-SPEC_<Feature>_Phase_<N>.md` | The phase spec exists; its `Status`: Draft / Approved / Implemented / Superseded. |
| `Review_Phase_<N>_<Feature>.md` | Latest verdict of phase N: APPROVED, APPROVED WITH OBSERVATIONS or CHANGES REQUIRED. |
| `Review_Final_<Feature>.md` | Final review done; its verdict and findings. |
| `Progress_<Feature>.md` | Optional checklist this skill writes (see 0.4). |

Phase status, derived in this order (artifacts first, checklist second; if they disagree, trust the artifacts and correct the checklist):

- Phase **done**: its review file exists, is non-empty, and the verdict is APPROVED or APPROVED WITH OBSERVATIONS.
- Phase **needs fixes**: review verdict is CHANGES REQUIRED.
- Phase **implemented, unreviewed**: the AI-SPEC Status is Implemented (or the checklist says implement is done, or the AI-SPEC's files exist) but there is no review file. Treat it as needing `/review`.
- Phase **specified**: an AI-SPEC exists (Draft or Approved) but is not Implemented. Treat it as needing `/implement`.
- Phase **pending**: no AI-SPEC yet. Treat it as needing `/ai-spec`.

Print a status table (step, status, scope) before acting, marking phases outside the requested scope as skipped.

### 0.3 Resume or restart

- If artifacts show prior progress and the user did not pass `resume`, ask once: **resume** from the first incomplete step, or **restart** from scratch?
- Restart never deletes files silently: tell the user which artifacts exist and that the new run will overwrite or supersede them, and confirm before proceeding. A re-review must keep the previous pass: `/review` appends a short revision-history table (pass, date, verdict, CRITICAL/MAJOR counts, what changed) instead of erasing the earlier verdict.
- Never move a finished phase back to pending unless the user asked for a restart.

### 0.4 Progress checklist (optional, human-readable)

Maintain `docs/features/<Feature>/Progress_<Feature>.md`, written **only by this skill**, so a person (or a later run) can see where things stand. No other skill reads or depends on it. Update it right after each step completes. Dates come from the shell `date` command, never from memory.

```markdown
# Progress - <Feature>

**Last update**: YYYY-MM-DD HH:MM

- [x] Analysis (optional) - Analysis_<Feature>.md
- [x] Proposal - Proposal_<Feature>.md (Status: Approved)
- [x] Human approval of the proposal
- [ ] Phase 1 - ai-spec (AI-SPEC_<Feature>_Phase_1.md) | implement | review (verdict: -) | fix rounds: 0/3
- [ ] Phase 2 - ...
- [ ] Acceptance-criteria verification (X/Y passed)
- [ ] Final review (verdict: -)
- [ ] Final fixes
- [ ] Completion summary
```

### 0.5 Phase-count sanity warning

If the scope is `all` and the roadmap has more than 5 phases, warn before starting:

> N phases detected. Quality drops on long runs; consider batches of 3-4 phases (e.g. `/pipeline <Feature> phase 1`, then the next). Continue with all N, or pick a range?

If the user picks a narrower scope, apply it and restart Step 0.

## Step 1 - Proposal

If `Proposal_<Feature>.md` already exists with a non-empty body and Status is not Draft/Superseded, log "proposal found" and skip to Step 2.

Otherwise:

1. **Analysis advisory (informational, never blocking)**. Look for `docs/features/<Feature>/Analysis_<Feature>.md`.
   - Found: note it; `/proposal` will consume it.
   - Not found: mention once that if the feature carries real technical or decision uncertainty, `/analysis` before `/proposal` can reduce risk (a short timeboxed spike). It is only a reminder; continue.
2. Invoke `/proposal` for the feature. Do not write the proposal yourself.
3. Verify the file exists and is non-empty, and that it has a phase roadmap (Implementation Plan) and acceptance criteria. If either is missing, say so and stop for the user.

### Human checkpoint: approve the proposal

Never implement on an unapproved proposal. Present the proposal path, a 5-line summary (problem, solution, phases, acceptance criteria count, open questions with owner `operator`), and ask for approval. Proceed only when the user approves (or the Proposal Status already reads Approved/In Progress). Open questions owned by `operator` must be answered first. On approval, make sure the Status line reads Approved. If the user asks for changes, re-run `/proposal` with their feedback and ask again.

## Step 2 - Identify phases

Read the Proposal's "Implementation Plan" (the phase roadmap) and list its phases (number, name, goal). If the section has no phases, ask the user to define them (or send the proposal back to `/proposal`) before continuing. Phase numbers are identities: never renumber. Apply the scope from 0.1 and run the sanity warning from 0.5. Set the Proposal Status to In Progress when the first phase starts.

## Step 3 - Phase loop

For each in-scope phase, in plan order, run 3-spec, 3a and 3b and handle the fix loop before moving to the next phase. Skip any step already satisfied by the derived state.

### 3-spec. AI-SPEC

If `AI-SPEC_<Feature>_Phase_<N>.md` does not exist, invoke `/ai-spec <Feature> phase N`; do not write it yourself. Verify the file exists and is non-empty. Show the user a short summary (scope, main files, tests, criteria covered). In `all` mode, proceed automatically unless the user asked to review specs; in a `phase N` run, stop for the user's OK before implementing, since the AI-SPEC is the contract `/implement` will follow. If the user asks for changes, re-run `/ai-spec` with their feedback. A Draft AI-SPEC accepted this way counts as approved.

### 3a. Implement

Invoke `/implement` for the feature's phase N (it follows the AI-SPEC and sets its Status to Implemented). After it returns:

1. Check completeness: every file the AI-SPEC's Solution lists exists.
2. Run the project's build/type-check and test commands (discovered from README, manifests or CLAUDE.md/AGENTS.md; ask if unclear). New build errors or test failures that were not present before the phase mean the implementation failed: report them, fix them (re-invoke `/implement` for the failures) before reviewing.
3. Update the checklist.

### 3b. Review and fix loop

Invoke `/review` for phase N. It writes `Review_Phase_<N>_<Feature>.md`. Read the **verdict** and the CRITICAL/MAJOR counts from that file:

- **APPROVED** or **APPROVED WITH OBSERVATIONS**: phase done. Observations are not blockers; leave them in the review's "Deferred items".
- **CHANGES REQUIRED**: branch on the **verdict**, not on the CRITICAL count - a MAJOR finding, a failing acceptance criterion or failing tests also produce it. Start a fix round:
  1. Invoke `/implement` for the same phase, pointing it at the review file so it fixes exactly the listed findings (no unrelated changes).
  2. Re-run build/tests as in 3a.
  3. Invoke `/review` again (the review file keeps the earlier pass in its revision history).
  4. Repeat until APPROVED / APPROVED WITH OBSERVATIONS.

**Bounded loop.** At most **3 fix rounds** per phase. If the verdict is still CHANGES REQUIRED after round 3, **stop and hand over to the human**: summarize the remaining findings (especially any CRITICAL), what was tried each round, and ask whether to continue (grant more rounds), change the approach, amend the proposal, or abort. Never loop forever and never approve a phase yourself.

If the review file is missing or empty after `/review`, do not count the phase as reviewed; report and stop.

### 3c. Amend the proposal now, not at the end

If the phase or its review refuted something the Proposal asserts (a mechanism that is not implementable, a rule already implemented, a wrong count, a guarantee stated without its limit), amend the Proposal **in this iteration**. Use an amendment note: keep the original text and add below it what is true now and which phase showed it. Later phases then read a correct document. Do not rewrite silently.

## Step 4 - Acceptance-criteria verification

Skip unless the scope is `all` (criteria are cross-phase). Log that it was skipped.

1. Read the Proposal's acceptance criteria (`CA-F<phase>-NN`, `CA-FINAL-NN`).
2. For each criterion, check in the repository that its evidence exists: referenced files, endpoints/entry points, UI or interface pieces, tests, traceable behavior.
3. `grep` every test ID the specs or reviews cite as evidence; a cited test that does not exist means the criterion is **not** covered by it, however plausible it looks.
4. Classify criteria that cannot be verified statically (they need the running app, a real credential, a browser or a third-party call) as **NOT VERIFIED (needs execution)**. Never count them as passed. If the project lets you run them (app available, credentials provided), run them and record evidence; if a precondition depends on a decision of the user (credentials, environment, cost), ask instead of concluding it is impossible.
5. Print the result:

```
Acceptance criteria
CA-F1-01  PASS      (Phase 1: <evidence>)
CA-F2-03  FAIL      (<what is missing>)
CA-FINAL-01 NOT VERIFIED (needs running app; blocked by: <reason>)
Result: X/Y passed, F failed, U not verified
```

If any criterion FAILs, ask the user: **fix the failed criteria [f] or continue anyway [c]**. On `f`, return to Step 3 for the affected phases (a normal fix round, bounded as above). On `c`, record the failures in the progress checklist and in the summary.

## Step 5 - Final review and fixes

Skip unless the scope is `all`.

1. Invoke `/review` in final mode, giving it the Proposal and all phase review files as context. Focus: integration between phases, cross-cutting concerns (security and access model, performance, observability, and tenant isolation only if the project is multi-tenant), overall acceptance criteria, duplication or contradictions between phases. It writes `Review_Final_<Feature>.md`.
2. If the verdict is APPROVED / APPROVED WITH OBSERVATIONS: nothing to fix.
3. If CHANGES REQUIRED: fix the CRITICAL, MAJOR and MINOR findings (not OBSERVATIONS) via `/implement` pointed at the final review file, read every file before touching it, run the full build/test/lint for affected areas, then re-run the final `/review`. Same bound: at most **3 fix rounds**; if the verdict is still CHANGES REQUIRED, stop and hand over to the human with a summary (a CRITICAL is always a stop).
4. Proposal amendments made at this step should be rare; if many appear, Step 3c was skipped.

When the final review passes, set the Proposal Status to Implemented.

## Step 6 - Completion summary

Show:

```
Pipeline finished: <Feature>
Scope            : all | phase N
Phases processed : X of Y   (fix rounds per phase: ...)
Acceptance crit. : P/T passed, F failed, U not verified
Final review     : <verdict>
Deferred items   : <count and where (Review files, "Deferred items" section)>
Not verified     : <criteria that nobody saw working, why, what closes them>
Next step        : <when scoped: run /pipeline <Feature> without a filter>
```

State plainly that "not verified" criteria are not "almost passed": the feature delivers what it delivers, and that part was not seen working. Finish the checklist and report the paths of the artifacts produced.

## Execution rules

1. **Orchestrate, don't duplicate.** Invoke the sibling skills by name and read their artifacts; do not write proposals, AI-SPECs, code or reviews in their place, and do not paste their content into this skill's output beyond summaries.
2. **Artifacts are the source of truth.** Derive progress from the Proposal and AI-SPEC Status lines and review verdicts; the checklist is a convenience and never overrides them. Never mark a step done without its artifact existing and being non-empty.
3. **Skip what is already done**, unless the user asked for a restart. Never regress a finished phase on your own.
4. **Gates.** No implementation without an approved proposal and an AI-SPEC for the phase. No phase counts as complete without a review file whose verdict is APPROVED or APPROVED WITH OBSERVATIONS.
5. **Bounded fix loops.** Maximum 3 fix rounds per phase and for the final review; then stop and ask the human. Stop immediately for the human on a CRITICAL that survives round 3.
6. **Reviewers do not fix; fixers do not approve.** The fix goes through `/implement`; the verdict always comes from a fresh `/review`.
7. **Scope control.** Fix only what the findings list. Do not fold unrelated improvements into a fix round.
8. **Errors halt the run.** If a step fails (skill error, missing artifact, build/test failure you cannot fix), say what failed and where, update the checklist, and stop; the next `/pipeline <Feature> resume` continues from there.
9. **Honest evidence.** Never invent paths, results or dates. Timestamps come from the shell `date` command. Never print secrets found in config or env files; cite the path only.
10. **Phase filter.** A phase-scoped run suppresses steps 4, 5 and 6 and tells the user to run without a filter to finish.
