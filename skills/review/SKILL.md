---
name: review
description: Review an implemented phase (or the whole feature) against its Proposal - business rules, acceptance criteria, code quality, tests, static analysis and build - and write Review_Phase_<N>_<Feature>.md or Review_Final_<Feature>.md with evidence-backed findings and a verdict. Use when the user asks to review a phase or a feature implementation.
argument-hint: <Feature> [phase N | final]
---

# Implementation Review (Spectionflow)

Review the implementation of **$ARGUMENTS** against its Proposal. The Proposal is the single source of truth: there is no separate spec. You verify business rules (`RN-NN`), acceptance criteria (`CA-F<phase>-NN`, `CA-FINAL-NN`) and the phase's Implementation Plan.

Write the review document in the language the project docs use. Section headings stay in English.

## Ground rules

- **Evidence over assertion.** Every verdict cites a real file path (and line) or a command output you ran. Never invent paths, test names or results.
- **The reviewer does not fix what it finds.** A finding goes into the review document, never into the code. A reviewer that fixes what it finds merges "who finds" with "who fixes" and the verdict stops measuring what was delivered. Only exception: errors in the review document itself (typos, numbering). When the fix is trivial, write it as a **suggested diff inside the finding**; the implementer applies it. Never rewrite a verdict after the fix; a new review pass issues the new verdict.
- **Verification edits are allowed, and must be undone safely** (see 7.5). Never undo with `git checkout --`, `git restore`, `git stash`, `git reset --hard` or `git clean`: the working tree may hold uncommitted work you cannot see. Use backup copy, restore by copy, compare checksums.
- **Do not dispatch sub-agents.** Investigate, read and measure yourself. Delegated reviewers have written concurrent reviews and edited code outside their mandate. If the scope is too large for one session, say so in the verdict instead of outsourcing.
- **Never transcribe secrets.** If you find a credential or token, cite the file path only, never the value.
- Do not review files the project marks as ignored (e.g. `.gitignore`, agent-ignore files).

## Phase 0 - Preparation (mandatory)

1. **Parse the argument.** `<Feature>` is PascalCase_With_Underscores; `phase N` reviews that phase; `final` reviews the whole feature (cross-phase). No phase given: infer the latest implemented phase from the diff and Proposal, and state your inference.
2. **Read the Proposal** `docs/features/<Feature>/Proposal_<Feature>.md` completely: business rules, acceptance criteria, decisions (`D-NN`), principles, open questions, and the Implementation Plan for the phase (goal, deliverables, files/areas, tests to write, criteria covered, validation commands). If the Proposal is missing, stop and tell the user.
3. **Read earlier reviews** of the same feature (`Review_Phase_*_<Feature>.md`) so you do not contradict or re-report settled points.
4. **Learn the project.** Read README, CLAUDE.md / AGENTS.md (if any), build manifests. Derive stack, code layout, and the build/lint/format/type-check/test commands. If a command is unclear, ask the user. Every stack-specific check below applies only if the project actually uses that technology.
5. **Read any architecture decision records** the Proposal references (if the project keeps them), and check each is still in force before using it as a premise.
6. **Analyze the diff.** Use `git -C <repo-root> ...` (resolve the root first). Compare against the integration branch (`main`, `master`, or what the project uses):
   ```bash
   git -C <repo-root> diff <base> --stat
   git -C <repo-root> diff <base> --name-only
   git -C <repo-root> log <base>..HEAD --oneline
   ```
7. **Read every new or modified file** in full. Do not spot-check.
8. **Get the date** from the shell `date` command. Never invent it.

### Where the review goes

`docs/features/<Feature>/Review_Phase_<N>_<Feature>.md` or `docs/features/<Feature>/Review_Final_<Feature>.md`. The feature name is part of the file name. Never overwrite a `Review_*` file you did not produce in this run; if the target exists and is not yours, pick a distinct suffix and say so.

### Document header

Start the document exactly with:

```markdown
# Review - <Feature> - Phase <N>: <subtitle>    (or: Review Final - <Feature>)

**Date**: YYYY-MM-DD
**Proposal reviewed**: <path>
**Phase / scope**: <phase N | final>
**Verdict**: <filled at the end, identical to section 10>
```

## 1. Spec compliance

Compare what was implemented against what the Proposal specifies for this phase.

### 1.1 Plan compliance

For each deliverable of the phase's Implementation Plan, check it exists and matches. Adapt to the stack; typical layers:

- **Data layer**: models/entities, fields, types, defaults, relations, indexes, enums/value sets, migrations consistent with the schema, seed data idempotent.
- **Service/API layer**: every specified endpoint/command (method, path, auth, request/response), input validation, pagination on list operations.
- **Business logic**: every `RN-NN` in scope is enforced in code.
- **Interface layer** (UI/CLI): every specified view, route, command, component; i18n keys present in every locale (if the project is multilingual).
- **Integrations**: events, shared services and external calls wired as specified; new modules registered in the composition root.

Classify each deviation:

| Class | Meaning | Default severity |
|---|---|---|
| **MISSING** | Specified, not implemented | CRITICAL |
| **DIVERGENT** | Implemented differently from the spec (explain how) | MAJOR |
| **EXTRA** | Implemented, not in the spec | MINOR (acceptable if justified) |

### 1.2 Proposal alignment

- The implementation follows the Proposal's decisions (`D-NN`) and principles; the chosen option is the approved one.
- Integration points match what was proposed.
- No contradiction with referenced decision records.
- Open questions (`AQ-NN`) that the code silently resolved are reported (the decision belongs to the Proposal).

## 2. Business-rule traceability

For each `RN-NN` in scope, build a row. Write paths from the repo root (e.g. `src/orders/service.ts:42`), never relative to the feature directory, so the layer of each file is unambiguous.

| Rule | Implemented? | File:line | Tested? | Test |
|---|---|---|---|---|
| RN-01 | YES / NO / PARTIAL | `path:line` | YES / NO | `path:test_name` |

Verdict per rule:
- **COVERED**: implemented and tested.
- **UNTESTED**: implemented, no test covers it - **MAJOR**.
- **PARTIAL**: partly implemented (say what is missing).
- **MISSING**: not implemented - **CRITICAL**.

**Layer check.** A rule implemented in several layers (e.g. service and UI, or two services) must have evidence in each layer, not one test credited for all. Compare the `File:line` and `Test` columns row by row: any layer implemented but with no test in that layer is a MAJOR (an exception is a test in another layer that demonstrably exercises that code path - then cite that test in the row). Say honestly how many rows you actually compared; if most rows cite no resolvable path, that is a gap in the matrix, not proof of "no divergence".

## 3. Acceptance criteria

### 3.1 Per-phase criteria (`CA-F<N>-NN`)

For each criterion give **PASS**, **FAIL** or **NOT VERIFIABLE** (with the reason), and the evidence (command output, test name, code reference). For FAIL: what is wrong, where, and a suggested fix (as text or diff, not applied).

### 3.2 Final criteria (`CA-FINAL-NN`)

A **phase review never emits PASS or FAIL on a `CA-FINAL-*`**: the final criteria are cross-phase and no single phase can judge them. In a phase review, every `CA-FINAL-*` is `NOT VERIFIABLE` with the reason (typically "depends on phase N"). Only the **final review** emits PASS/FAIL/NOT VERIFIABLE on them. `NOT VERIFIABLE` is not evasive; claiming a verification you did not do is the violation.

### 3.3 Summary

| Type | Total | Pass | Fail | Not verifiable |
|---|---|---|---|---|
| Per-phase (CA-F<N>) | | | | |
| Final (CA-FINAL) | | | | |

## 4. Code review

Severity scale (use it for every finding in the document):

| Severity | Meaning | Blocks merge? |
|---|---|---|
| **CRITICAL** | Broken functionality, security vulnerability, data leak, missing core feature | Yes |
| **MAJOR** | Significant quality issue, untested critical path, architecture violation, guard with no discriminating test | Yes |
| **MINOR** | Quality improvement, naming inconsistency, missing edge-case handling | No |
| **OBSERVATION** | Suggestion, alternative, cosmetic | No |

### 4.1 Architecture and patterns
- The project's layering is respected (no shortcuts across layers; handlers/controllers stay thin).
- Import and naming conventions of the project are followed.
- New modules are registered; dependencies are injected/composed the way the project does it, no ad-hoc instantiation.
- Interface code does not call infrastructure directly when the project routes it through a client/service layer.

### 4.2 Data isolation (only if the project is multi-tenant or has per-owner data)
- New data carries the tenant/owner key; queries go through the project's scoping mechanism.
- Single-record access validates the scope. Think adversarially: what if the scope key is spoofed in the request?
- No scoped data in error messages or logs.

### 4.3 Security
- Every entry point has proper authentication/authorization wiring; public endpoints are justified by the spec.
- Role/permission restrictions follow least privilege (if the project has roles).
- No sensitive data in responses (passwords, tokens, hashes, internal ids).
- All external input is validated before reaching the data store; no injection vectors (check raw queries and shell calls); no XSS vectors (raw HTML rendering, dynamic attributes).
- No secrets committed.

### 4.4 Code quality
- No dead code, commented-out blocks, stray TODO/FIXME, debug output (`console.log`, `debugger`, prints).
- No duplicated logic that belongs in a shared utility; no magic strings/numbers that should be constants.
- No untyped escape hatches where a proper type exists; no unused imports.
- Async work is awaited; no fire-and-forget without justification.

### 4.5 Error handling
- Errors are handled at external boundaries and not swallowed or needlessly caught-and-rethrown.
- For APIs, check status codes: 201 created, 204 deleted, 400 invalid input, 403 cross-scope, 404 not found, 409 conflict. Consistent error format across new endpoints.

## 5. Cross-layer consistency

Read the actual values; do not just tick a box. Skip rows for layers the project does not have. Report each row **ALIGNED** or **DRIFT** (with details).

| From | To | Check |
|---|---|---|
| Data-model fields | DTO / schema fields | Names and types match (or the mapping is documented) |
| Validation rules | Business rules (`RN-NN`) | Each rule has a corresponding validator |
| Handler routes | API contract (if the project keeps one) | Identical method and path |
| Response types | Client-side models | Field names and types match |
| Client request paths | Server routes | Identical URLs and methods |
| i18n keys in code | Locale files | Every key exists in every locale |

## 6. Migrations and seeds (only if the project has them)

- A migration exists and matches the schema change; no destructive operation without explicit justification; renames on populated tables are two-step; new required columns have defaults; indexes exist for filtered, unique and scope-key fields; rollback path is reversible or documented.
- Seeds are idempotent, respect business rules (valid enum values, required relations) and contain no real or sensitive data.

## 7. Testing validation

Run the project's own test commands. Do not trust claims from the implementation report; run them and quote results.

### 7.1 Unit and integration tests
- Run the full suite of every affected area, including pre-existing tests: zero regressions.
- New logic has co-located tests covering success paths **and** error paths, and each in-scope `RN-NN` (cross-check with section 2).
- No `.skip`/disabled tests without documented justification.
- Areas with no test infrastructure: note the gap, do not invent coverage.

### 7.2 End-to-end tests
Run them where the project has them. Cross-module or multi-step flows specified in the Proposal need an E2E or integration test.

### 7.3 Completeness assessment

| Layer | New files | With test | Without test |
|---|---|---|---|
| Services / domain | | | |
| Handlers / API | | | |
| Interface (stores, components, commands) | | | |

Flag untested critical paths (complex rules, error handling on external calls, scope isolation). This table measures *breadth* (which file has a test), not *discriminating power* (would the test fail if the code were wrong) - that is 7.5.

### 7.4 Planned test scenarios exist

Every test id or scenario the Proposal's plan names must exist in the code. Run `grep -rn '<ID>' <test dirs>`. An id that does not exist is `NO`, never `YES` because "other tests probably cover it". A phantom test cited as evidence is traceability fiction. Also report **orphans**: tests that exist and are cited nowhere (not a defect; they signal behavior beyond the contract).

### 7.5 Invariant guards - mutation sampling (mandatory)

Coverage finds code that never runs. This section finds code that **runs but is never observed**: a guard every test passes through and none would notice if you deleted it. Line and branch coverage cannot see this; only mutation can.

1. **Enumerate** the guards the phase introduced or changed. A guard is code whose purpose is to *prevent a state*: early return, a `catch` that denies, validation that rejects, a cap/limit, a defensive branch, an "already resolved" check.
2. **Mutate each one** (or a justified sample), with this safe procedure:
   - copy the file to a backup (e.g. into a scratch directory) and record its checksum (`md5sum` or `sha256sum`);
   - make the temporary edit (delete or invert the guard);
   - run the relevant tests;
   - **restore by copying the backup file back** over the original, then compare the checksum: it must match the first one. If it does not, say so in the report instead of continuing.
   Never restore with git commands that discard working-tree changes.
3. **Report a table**, naming the test that went red:

   | Guard | File:line | Mutation applied | Test that failed | Verdict |
   |---|---|---|---|---|
   | ... | `path:123` | deleted `if (!x) return` | `test_name` | ✅ proven |
   | ... | `path:88` | inverted the cap | none | ❌ no discriminating test |

4. **Classify.** A guard with no discriminating test is **MAJOR**: the code may be right, but nothing stops someone removing it tomorrow. The fix is *one test*, not a behavior change; say so in the finding.
5. **For guards that recognize N syntactic forms** (regex, parser, filename filter, extractor), require one test case per form, not one in total. A matcher that matches too little does not fail - it approves. A recognized form with no case is MAJOR by the same rule.

Not acceptable as proof: "the line is covered", "the suite passes" (it would pass without the guard too), or a test credited to the guard without the mutation having been run.

Also check **assertion power**: an assertion that depends on *finding* something needs a positive control (otherwise renaming the target silently empties it), and an assertion that iterates the list under test goes green exactly when a name disappears from that list.

**Declare the sampling fraction**: how many guards you mutated out of how many plausible. If zero, say zero. "Adequate coverage" is an adjective, not a measurement.

### 7.6 Duplicated catalogs (only if the phase adds an item to an enumeration or creates a second copy of a list)

If a list consumed by another module (tools, modes, error codes, types) exists in more than one place: it must have a declared owner file, and the consumer must have a parity test against the source (not against its own copy). Divergence is MAJOR; the typical symptom is an item silently denied or ignored with a clean log.

### 7.7 Test doubles for third-party dependencies (only if the phase involves an external SDK/API/CLI with fakes)

A fake simpler than the real contract blinds the whole suite while it stays green. Check: fixtures are typed against the vendor's published types where available (look for omitted required fields); a recorded real sample (with package version and date) exists and the fake derives from it; drift between sample version and installed version is detected. Missing all three in such a phase is MAJOR.

## 8. Static analysis and build

Run the project's commands, scoped to what changed. Quote counts of errors and warnings.

- **Lint**: no errors in new or modified files; review warnings.
- **Type check** (if the stack is typed): no errors in changed files.
- **Formatting**: use a format *check* mode. Do **not** run a repo-wide formatter that rewrites unrelated files.
- **Schema validation** (if the data layer has one): schema valid, migrations consistent.
- **Build**: every affected project builds; no new build warnings.

| Check | Status | Errors | Warnings |
|---|---|---|---|
| Lint | PASS/FAIL | | |
| Type check | PASS/FAIL | | |
| Formatting | PASS/FAIL | | - |
| Schema | PASS/FAIL/- | | - |
| Build | PASS/FAIL | | |

A check that did not run (missing tool, environment limit) is reported as **NOT RUN** with the reason and listed under Deferred items. It is never silently counted as PASS.

## 9. Documentation and best practices

- API contract / docs updated for new or changed endpoints (if the project keeps them) and matching the implemented types and routes.
- **Database**: indexes for query patterns; no N+1 loops (data-store calls inside iteration); only needed fields fetched; migrations reversible.
- **API design**: conventional verbs, pagination or limits on every list (no unbounded queries), consistent error shape, correct status codes.
- **Interface UX** (if there is a UI): no hardcoded user-facing strings in a multilingual project; loading, error, empty and success states; form validation feedback; new views reachable from navigation.
- **Performance**: no unbounded queries, no redundant fetches on mount/navigation, no heavy synchronous work on a hot path, large lists paginated or virtualized.
- **Events** (if used): emitted where specified, handlers idempotent, payload sufficient without extra queries, no synchronous cross-module call where an event is specified.
- **Dependencies** (if packages were added): necessary, not duplicating existing ones, appropriate versions, correct dev/prod placement, consistent with the stack.

## 10. Findings register and verdict

Consolidate every finding from sections 1-9 into one prioritized register. Give each an id `F-NN` and cite file and line.

| Id | Severity | Section | Description | File:line | Suggested fix (text or diff, not applied) |
|---|---|---|---|---|---|
| F-01 | CRITICAL / MAJOR / MINOR / OBSERVATION | | | | |

### Verdict

- **APPROVED**: zero CRITICAL, zero MAJOR; all tests pass; all in-scope acceptance criteria PASS.
- **APPROVED WITH OBSERVATIONS**: zero CRITICAL, zero MAJOR; MINOR findings or observations exist but do not block.
- **CHANGES REQUIRED**: any CRITICAL or MAJOR finding, or any acceptance criterion FAIL, or any failing test. The phase goes back to `/implement`.

The verdict must be coherent with the register: a document with a MAJOR in its own table cannot say APPROVED.

### Statistics

| Category | Pass | Fail | N/A |
|---|---|---|---|
| Spec compliance | | | |
| Rule traceability | | | |
| Acceptance criteria | | | |
| Code review | | | |
| Cross-layer consistency | | | |
| Migration and seed | | | |
| Tests | | | |
| Invariant guards (7.5) | | | |
| Static analysis and build | | | |
| Documentation and best practices | | | |

| Severity | Count |
|---|---|
| CRITICAL | |
| MAJOR | |
| MINOR | |
| OBSERVATION | |

### Positive highlights

Note well-implemented patterns and good decisions worth keeping. It encourages consistency.

### What to do with the findings

1. **CRITICAL / MAJOR**: register and emit `CHANGES REQUIRED`. The implementer fixes; you do not edit the reviewed code.
2. **MINOR**: register; fixed in the implementer's next pass or moved to Deferred items.
3. **OBSERVATION**: register; a trivial fix is a suggested diff inside the finding, not an edit.

When the fix pass runs (implementer, in priority order CRITICAL, then MAJOR, then MINOR), it records in the review document which finding it closed (file and line) and re-runs sections 7 and 8. A new review pass issues the new verdict.

### Deferred items

Anything **not** fixed in this pass must not die in the review file. Add a "Deferred items" section listing each: deferred or won't-fix finding, acceptance criterion left UNVERIFIED (e.g. performance without a load test), environment limitation (tests or checks not run), non-trivial observation deferred. For each: id, one-line description, reason for deferral, severity, and what would resolve it. Items fixed in this pass are not listed.

## Quality checklist (self-check before finishing)

- Every verdict has evidence you actually produced (command run, file read), with real paths.
- The traceability matrix lists every in-scope `RN-NN`; every in-scope `CA-*` has a verdict.
- Phase review: no PASS/FAIL on any `CA-FINAL-*`.
- Mutation table present, with the sampling fraction declared, and every temporary edit restored with matching checksums.
- You edited no reviewed code and dispatched no sub-agents.
- Verdict matches the register; Deferred items section present (even if "none").
- The date came from `date`.
