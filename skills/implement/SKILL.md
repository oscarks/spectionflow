---
name: implement
description: Implement one phase of the Proposal's Implementation Plan. Use when the user asks to implement, build or code a feature that already has an approved Proposal in docs/features/<Feature>/.
argument-hint: <Feature> [phase N]
---

# Implement

Implement one phase of the "Implementation Plan" in `docs/features/<Feature>/Proposal_<Feature>.md`. Argument: `$ARGUMENTS` = `<Feature> [phase N]`. If no phase is given, implement the first phase not yet implemented (ask if unclear). The Proposal is the only spec; there is no separate technical spec.

Write code comments, test names and any user-facing text in the language the project already uses.

---

## Step 0 — Preparation (mandatory before any code)

1. **Read the Proposal in full.** Locate the Implementation Plan and the exact phase. Note its goal, deliverables, files/areas to touch, tests to write, acceptance criteria (`CA-F<N>-NN`), business rules (`RN-NN`), validation commands, and the decisions (`D-NN`) that constrain it.
2. **Check prerequisites.** If the phase depends on an earlier phase or an open question (`AQ-NN`) that is unresolved, STOP and tell the user. Do not guess.
3. **Learn the project.** Read README, CLAUDE.md / AGENTS.md (if present), package/build manifests and the directory layout. Discover the stack, the build / lint / format / test commands, naming and layering conventions, and the test style. If a command cannot be found, ask the user.
4. **Study existing code.** Before touching an area, read at least one similar existing module and copy its real patterns (structure, naming, error handling, test style). Use what the repo does, not generic templates. If the project has a design-system or style guide document, read it before writing interface code.
5. **Update the Status line** of the Proposal to `In Progress` when starting phase 1. This is the only edit you may make to the Proposal; never change its content, plan or criteria. If the plan is wrong or incomplete, tell the user and let them fix the Proposal.
6. **Plan the work.** Break the phase into small tasks in the execution order below and track them with the task tool if available.

---

## Step 1 — Execution order (follow strictly)

Implement in this order. Each step must build and pass its checks before the next one starts. Skip layers the project or the phase does not have.

1. **Data** — schema, models, migrations, seeds. Follow the Proposal's fields, types, defaults, relations and indexes exactly. Migrations: never drop data or columns without explicit user confirmation; renames are add → migrate → drop. Seeds must be idempotent. Regenerate any generated client. Run the schema validation command if one exists.
2. **Contracts** — request/response types, validation schemas, shared interfaces. Match the Proposal exactly; never expose secrets, hashes or internal identifiers that should stay opaque. Keep names aligned with the data model (or document the mapping).
3. **Logic** — services / domain code. Respect the project's layering. Enforce every business rule (`RN-NN`) in this phase, each one identifiable in the code. Use the project's error types for not found, conflict, forbidden and invalid input; do not catch errors only to re-throw them. Apply the project's access/ownership/tenant scoping to every query on scoped data. Lists must be paginated and bounded; avoid N+1 queries; fetch only what is needed.
4. **Entry points** — handlers, routes, commands, jobs, event consumers. Keep them thin: parse and validate input, check authorization, delegate to the logic layer, map the result. Use correct status/exit codes. Update the API contract document (e.g. OpenAPI) if the project keeps one.
5. **Wiring** — register modules, routes, dependencies and configuration in the project's composition root. Import dependencies explicitly.
6. **Build gate** — run build / type-check, lint, and a formatter on **changed files only** (never a repo-wide reformat). Fix every error before continuing.
7. **Tests** — write the tests listed in the phase, co-located and in the project's style. Cover the happy path, error paths, authorization/scope isolation (if applicable), and at least one test per business rule in this phase. Run the whole relevant suite, including pre-existing tests; if an old test breaks, you probably caused a regression — fix it.
8. **Interface** — client models matching the response shapes exactly, then the HTTP/client layer, then state, then views/components. Call the API only through the project's client layer, never directly from components. Provide loading, error and empty states. Use the project's translation mechanism for every user-facing string if it has one, adding keys to all locales. Register routes. Leave no `console.log` or `debugger`. Never use hardcoded mocks or fake data in place of real integration.
9. **Interface gate and tests** — run type-check, build and tests for each affected interface surface. If a surface has no test infrastructure, say so explicitly rather than silently skipping.

If the project has another service (different language or framework), follow that service's own architecture, dependency manager and test command; do not impose the conventions of the main service on it.

When code depends on a third-party library whose exact version matters, check the installed version and its documentation; do not rely on memory for signatures.

---

## Scope control

- Implement only what the Proposal's plan describes for this phase. No future-phase work, no extra features, no refactoring of surrounding code.
- If something is ambiguous or undefined, ask the user before assuming.
- Before creating any file or module, check whether it exists; if it does, modify only what is necessary.
- Do not touch files the project asks agents to ignore.
- To undo a temporary edit (experiment, mutation test), restore from a backup copy and compare checksums. Never use destructive git commands (`checkout --`, `restore`, `stash`, `reset --hard`, `clean`): the working tree may hold uncommitted work you do not know about.

---

## Consistency checks (before completing)

Skip rows for layers the project does not have.

- [ ] Data-model field names match contract field names (or the mapping is documented)
- [ ] Validation rules match the business rules in the Proposal
- [ ] Route paths in handlers match the API contract document and the client layer, exactly
- [ ] Response shapes match the client-side models (names and types)
- [ ] State actions call the right client methods
- [ ] Translation keys used in views exist in all locale files
- [ ] New modules and routes are registered in the composition root

### Proving guards

A guard is code that prevents a state rather than producing a result: early return, rejecting validation, limit, defensive branch, authorization check. For every guard you add, prove a test notices it: back up the file, remove or invert the guard, run the tests, confirm at least one fails (note which), restore the file, confirm the checksum matches, and confirm the suite is green again. Coverage is not proof; it only shows the line ran. If no test fails, write one that does, or state in your final message that the guard is unproven.

Two traps give green but empty tests: assertions that need to find something (a log line, a key) with no positive control, and assertions that iterate the very list under test. Assert literal expected values by name.

### Lists that live in two places

When you add an item to a list that another module consumes and must recognize (tools exposed vs. tools authorized, error codes emitted vs. messages mapped, modes declared vs. modes accepted), the list has one owner. Write a parity test comparing the consumer against the owner's source, not a second copy of the list.

### Test doubles for third-party dependencies

When faking an SDK, CLI or external API: type the fake against the vendor's published types where they exist (first check that your type-check actually covers test files); derive the fake's shape from a real recorded sample, stored as a versioned fixture with the vendor version and date; and, if feasible, add a test that warns when the installed vendor version differs from the one the sample was captured with. A fake simpler than the real contract makes the suite blind to what the vendor really emits.

---

## Completion checklist

Verify all of these before declaring the phase done; skip rows that do not apply.

**Build and static analysis**
- [ ] Build / type-check passes with zero errors
- [ ] Lint passes with zero errors
- [ ] Formatter run on changed files only
- [ ] Schema validation passes (if the project has one)
- [ ] Every affected interface surface builds and type-checks

**Tests**
- [ ] All unit tests pass, including pre-existing ones
- [ ] End-to-end / integration tests pass (if the phase defines them)
- [ ] No skipped tests without a documented reason
- [ ] Every guard added has a test that fails when the guard is removed

**Completeness**
- [ ] Every data model, endpoint/command and screen listed in the phase exists
- [ ] Every business rule (`RN-NN`) in this phase is enforced in code
- [ ] Every acceptance criterion (`CA-F<N>-NN`) of this phase is met and has a test or a stated verification
- [ ] Every test listed in the phase is written
- [ ] API contract document updated (if the project keeps one)
- [ ] Translation keys in all locales (if the project is multilingual)

**Security**
- [ ] Every non-public entry point has its authentication and authorization
- [ ] No sensitive data in responses or logs
- [ ] Input validated at every boundary
- [ ] Scope/tenant isolation enforced on all queries (if applicable)

---

## Final message

Report concisely:

- what was implemented, mapped to the phase's deliverables and acceptance criteria;
- the commands run and their results (build, lint, tests), plus any test or check that could not be run and why;
- any guard left unproven, and any gap you could not close;
- **deferred / out-of-scope items**: everything you noticed but deliberately did not do (future-phase work, refactors, ambiguities, environment limitations). List them so the reviewer and the user can decide; do not create a separate tracking file.

End by telling the user: **run `/review <Feature> phase N`** to review this phase.
