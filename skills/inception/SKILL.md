---
name: inception
description: Lightweight product inception. Turns a product sketch into the minimum needed for a first milestone — pain, customer, value hypothesis and the scope of Milestone 1 — and seeds the proposals that /proposal will expand. Use when starting a new product from an idea, or when the user asks for "inception", "define the product" or "first milestone".
argument-hint: "[init | discovery | scope | finalize | status]"
---

# Inception (lightweight) — from sketch to first milestone

This skill answers only the minimum: **what** to build first, **for whom**, and **how to know it worked** — enough to define Milestone 1 and give `/proposal` product context.

Out of scope here: market research, risk analysis, a refined backlog, architecture and stack decisions. Do not write them.

Write documents in the user's language (follow the project's README / CLAUDE.md / AGENTS.md; default: the language the user writes in).

## Principles

1. **The human decides.** Propose, ask, and record only what the user approves. If something is undefined, ask — never invent a pain, a customer or a number.
2. **Minimal, not shallow.** Each document is short, but every statement is specific and verifiable.
3. **Provenance.** End every statement with a bracketed tag:
   - `[from-source:<file>]` — came from a file in `docs/inception/sources/`
   - `[from-operator]` — the user said it
   - `[assumed]` — your hypothesis, to be validated

   Never claim market data or competitor facts; this skill does no research. A statement that came from a source and was then confirmed by the user keeps `[from-source:<file>]`.
4. **Non-destructive.** Create or append; never delete or overwrite existing documents.

## Sources — `docs/inception/sources/`

The user may drop briefs, interview notes, customer research or an old spec there. At `init` and at the start of `discovery` and `scope`:

1. **List** the folder and tell the user, one line per file, what is there. Missing or empty: say so in one line and move on.
2. **Read** the files about product, customer, pain or scope. For a `.pdf`/`.docx`, read a sibling `<name>.md` extraction if it exists; otherwise say the file could not be read and move on. Architecture or stack documents may be listed but are ignored here.
3. **Use** what you read to build the options for your questions and the text of the documents, tagging `[from-source:<file>]`.
4. **Contradictions**: when a source contradicts what the user wrote, write the source's statement and, **in the same turn**, tell the user in one line: what the sketch said, what the source says, which file. Never resolve it silently and never stop the flow — the user decides.

## Sub-modes

### `init`

If `docs/inception/` already holds a `Product_Definition.md` or `Scope_and_Milestones.md`, do not recreate anything: show what exists and suggest the next sub-mode. Otherwise:

1. Create `docs/inception/` and `docs/inception/sources/`.
2. Capture the product name and the sketch from what the user wrote after `init`. If the product has no name, ask once.
3. Create `docs/inception/README.md` (if absent):

```markdown
# docs/inception — the product inception

- `Product_Definition.md` — pain, customer, value hypothesis and how we will know it worked.
- `Scope_and_Milestones.md` — Milestone 1 and what was deliberately left for later.
- `sources/` — reference documents attached by the team; statements taken from them are tagged `from-source:<file>`.
```

4. Do the **Sources** reading. Finish by suggesting `/inception discovery`.

### `discovery` → `docs/inception/Product_Definition.md`

Read the **Sources**, then run a short conversation — at most **5 questions, one at a time** — to settle:

- **Pain** — specific, frequent, and relevant to the customer's decisions (one, at most two);
- **Customer** — the ideal customer profile and the first segment to serve;
- **Value hypothesis** — `If we offer X → the customer gets Y → with impact Z`;
- **How we will know it worked** — one observable signal.

Write a one-page document: product name and sketch at the top, the sources used, then one section per item above, with provenance tags on every statement. Suggest `/inception scope`.

### `scope` → `docs/inception/Scope_and_Milestones.md`

Read the **Sources**, then propose **Milestone 1** — the smallest cut that proves the value hypothesis — and ask for approval:

- **Title** and **outcome** (what becomes true when it closes);
- **Features** (2 to 5), each with a short `PascalCase_With_Underscores` name and one sentence, marked `committed` or `stretch`;
- **Exit criteria** (2 to 4, verifiable);
- **Out of scope** — what is deliberately left for later (you may list "Milestone 2+" with a title only).

Write the document with a `## Milestone 1` section in that format and provenance tags. Suggest `/inception finalize`.

### `finalize`

Requires both documents to exist and be approved by the user (otherwise say what is missing and stop).

1. For each Milestone 1 feature, create `docs/features/<Feature>/Proposal_<Feature>.md` as a **seed**: title, `**Status**: Seed (from Inception)`, the feature's sentence, its scope slice, and links to `../../inception/Product_Definition.md` and `../../inception/Scope_and_Milestones.md`. Never overwrite an existing proposal.
2. Report what was created and the next steps: `/proposal <first feature>` to expand the seed, or `/pipeline <first feature> all` to run the whole flow. Mention in one line that deeper inception (market research, risks, backlog, architecture) is out of scope for this lightweight version — without insisting.

### `status`

Print a table: document · exists? · one-line summary. Write nothing.

## Anti-patterns

- ❌ Researching the web, inventing competitors or numbers.
- ❌ Ignoring `docs/inception/sources/` when files are there.
- ❌ Detailing anything beyond Milestone 1.
- ❌ Writing risks, backlog, architecture or stack decisions.
- ❌ Deleting or rewriting existing documents.
- ❌ Writing product code.
