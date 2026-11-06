# `/implement`

## Purpose

Implements **one phase** of the Implementation Plan in `docs/features/<Feature>/Proposal_<Feature>.md`, with its tests. The Proposal is the only spec.

## When to use / not use

Use it when a Proposal exists and you have approved it, or when a review returned `CHANGES REQUIRED` and the findings must be fixed.

Do not use it to change the Proposal's content, to implement several phases at once, or to start on an unresolved open question that blocks the phase.

## Invocation and arguments

```
/implement <Feature> [phase N]
```

Without a phase, the skill implements the first phase not yet implemented (and asks if unclear).

```
/implement Notification_Retry
/implement Notification_Retry phase 2
```

Fix pass: point it at the review file so it fixes exactly the listed findings, for example "fix the findings in `Review_Phase_1_Notification_Retry.md`".

## Inputs read

- The Proposal in full: the phase's goal, deliverables, files/areas, tests, acceptance criteria (`CA-F<N>-NN`), business rules (`RN-NN`), validation commands and the constraining decisions (`D-NN`).
- README, `CLAUDE.md` / `AGENTS.md`, manifests and layout: the stack, build/lint/format/test commands, naming and layering conventions.
- At least one similar existing module in each area it touches, to copy the real patterns.
- A design-system or style guide document, if the project has one, before writing interface code.
- The installed version and documentation of third-party libraries whose exact version matters.

## Outputs written

- Code and tests for the phase, in the project's layout.
- Exactly one edit to the Proposal: its `Status` line becomes `In Progress` when phase 1 starts. Nothing else in the Proposal may be changed; if the plan is wrong, the skill tells you.
- No tracking file. Deferred items are listed in the final message.

## What the skill does, step by step

**Step 0 - Preparation.** Read the Proposal; check prerequisites (an unresolved earlier phase or open question means STOP and tell you); learn the project; study existing code; set Status to `In Progress`; plan small tasks.

**Step 1 - Execution order** (strict; each step must build and pass its checks before the next; layers the project does not have are skipped):

1. **Data**: schema, models, migrations, seeds. Never drop data or columns without explicit confirmation; renames are add, migrate, drop. Seeds are idempotent.
2. **Contracts**: request/response types, validation schemas. Never expose secrets or hashes.
3. **Logic**: services/domain code. Every `RN-NN` of the phase is enforced and identifiable in the code. Access/ownership/tenant scoping on every query on scoped data; lists paginated and bounded; no N+1.
4. **Entry points**: handlers, routes, commands, jobs. Thin: parse and validate, authorize, delegate, map the result.
5. **Wiring**: register modules, routes, dependencies and configuration.
6. **Build gate**: build/type-check, lint, and a formatter on **changed files only**.
7. **Tests**: write the tests listed in the phase (happy path, error paths, scope isolation where applicable, at least one per business rule). Run the whole relevant suite; a broken old test means a regression to fix.
8. **Interface**: client models, client layer, state, views. Loading, error and empty states; translation keys in all locales if the project is multilingual; no `console.log`/`debugger`; no hardcoded mocks in place of real integration.
9. **Interface gate and tests**: type-check, build and test each affected surface. A surface with no test infrastructure is reported, not silently skipped.

**Step 2 - Consistency checks and completion checklist** (build, tests, completeness, security), then the final message.

## Rules and guardrails

- **Scope control**: only what the Proposal's plan describes for this phase. No future-phase work, no extra features, no refactoring of surrounding code. Ambiguity means ask you first.
- Check whether a file or module exists before creating it.
- Do not touch files the project asks agents to ignore.
- **Undoing a temporary edit** (an experiment or mutation test): restore from a backup copy and compare checksums. Never use `git checkout --`, `git restore`, `git stash`, `git reset --hard` or `git clean`: the working tree may hold uncommitted work.
- **Proving guards.** A guard is code that prevents a state (early return, rejecting validation, limit, authorization check). For every guard added: back up the file, remove or invert the guard, run the tests, confirm at least one fails (note which), restore, confirm the checksum, confirm green again. Coverage is not proof. If no test fails, write one, or state in the final message that the guard is unproven.
- Two traps give green but empty tests: assertions that must *find* something with no positive control, and assertions that iterate the very list under test. Assert literal expected values by name.
- A list consumed by another module has one owner; write a parity test against the owner's source, not a second copy.
- Fakes for third-party SDKs/APIs are typed against the vendor's types, derived from a recorded real sample (versioned fixture), ideally with a drift warning.

## Human checkpoints

- It stops and asks on a blocked prerequisite, an unresolved open question or an ambiguity.
- Destructive data operations need explicit confirmation.
- Your approval of the Proposal precedes it; your decision after the final message (review next) follows it.

## Common mistakes

- Starting before the Proposal is approved.
- "Helpful" extras: next-phase work, refactors, drive-by fixes.
- Editing the Proposal's plan or criteria because they seem wrong (tell the user instead).
- Repo-wide formatting.
- A guard with no test that would fail without it.
- Declaring the phase done without running the existing suite.

## Worked example

```
/implement Notification_Retry phase 1
```

Final message excerpt:

```markdown
Phase 1 implemented: retry scheduling.

Deliverables
- Migration `migrations/0042_add_attempts.sql` (attempts, next_attempt_at)
- `src/jobs/retry.ts` (new), `src/delivery/sender.ts` (enqueue on failure)
- Tests: `src/jobs/retry.test.ts` (RN-01)

Acceptance criteria: CA-F1-01 met (test `retry reschedules on 503`).

Commands
- npm run build: OK
- npm run lint: OK
- npm test: 214 passed, 0 failed (baseline: 212 passed, 0 failed)

Guards: the "only retry 5xx/network errors" check in retry.ts:27 was inverted;
`does not retry 400` failed; file restored, checksum matches.

Deferred / out of scope
- Backoff schedule (phase 2).
- `sender.ts` has a duplicated header-building block; not touched.

Next: run `/review Notification_Retry phase 1`.
```
