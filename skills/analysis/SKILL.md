---
name: analysis
description: Produce a pre-proposal analysis study (Analysis_<Feature>.md) — discovery, capability, decision, strategic, rca or item mode — with stable open questions (AQ-NN, each with an owner) and an explicit handoff to /proposal. Use when the user asks for an analysis, a study, feature discovery for a theme, an options/trade-off decision, a strategic assessment, or a root-cause analysis before proposing a solution.
argument-hint: <theme> [discovery|capability|decision|strategic|rca|item]
---

# Pre-Proposal Analysis

Perform the pre-proposal analysis for **$ARGUMENTS**.

This skill produces the **study that precedes** `/proposal`. It never implements anything. Every mode diverges before it converges, and ending with `Status: Exploratory — no decision` is a legitimate deliverable. Do not force a verdict where none is warranted. Stack-agnostic: learn the project from its files, never assume a stack.

## Argument parsing and mode inference

1. If any token (case-insensitive) is one of `discovery`, `capability`, `decision`, `strategic`, `rca`, `item`, that is the **mode**; the remaining tokens are the **theme**.
2. Otherwise infer the mode from the theme with the table below.
3. **Announce the mode before Phase 1** ("Inferred mode: `decision` — say so if that's not what you meant."). If the user corrects it, do not repeat Phase 0 — redo only Phase 1.
4. If the inference is not confident, ask, offering all six modes with their one-line question.
5. No theme at all: ask for one before starting.

| Mode | Method | Question it answers | Body of §3 |
| --- | --- | --- | --- |
| `discovery` | Opportunity-solution tree + SWOT | What features exist within this theme? | Theme → opportunities → solutions tree, plus a catalog of candidate features (id `F-NN`, name, what it solves, dependencies, priority) |
| `capability` | Domain/technology exploration | What does this territory/technology offer × our reality? | Capability inventory → applicability to the project → gap table, with real paths |
| `decision` | Feasibility + trade-off matrix + optional spike | Which option, and why not the others? | Enumerated options + options × criteria matrix + recommendation with rationale |
| `strategic` | Level taxonomy + verdict per level | Should we enter this territory? At what level? | A `N1..Nk` taxonomy + a verdict per level with justification |
| `rca` | Root cause analysis (5 Whys / causal chain) | Why does it break, and what is the plan? | Causal chain anchored in real code (`path:line`) + confirmed root cause + phased plan `D1..Dk` |
| `item` | Requirements as received → decisions | What does this request mean in this context? | Requirements transcribed as received + interpretation in the project's context + decisions |

## Phase 0 — Common exploration (mandatory, all modes)

Done once, regardless of mode.

1. **Learn the project** — read the README, `CLAUDE.md`/`AGENTS.md` (if present) and the docs. Derive the documentation language and conventions relevant to the theme.
2. **Choose the location** — features live in `docs/features/<Feature>/`. If the project already organizes docs differently, follow its convention and say so.
3. **Product context** — if `docs/inception/` exists, read it as the source of what/why.
4. **Related decisions and documents** — read existing decision records (ADRs), proposals and analyses that constrain the theme. Before using a decision as a premise, check it is still in force (not superseded).
5. **Explore the real codebase** — read the modules, files and paths the theme touches. Every path cited in the output must be real and verified, never invented.
6. **Secrets rule** — if exploration surfaces secrets, credentials, tokens or connection strings, never transcribe the value. Cite where it lives, not what it is.

## Phase 1 — Mode method (diverge → converge)

- **discovery** — build the opportunity tree from the theme down to concrete solution ideas; cross-check with a SWOT of the current state; converge into the candidate-feature catalog, each with an `F-NN` id.
- **capability** — inventory what the territory/technology actually offers; map each capability against the project's real state; converge into an applicability/gap table.
- **decision** — enumerate the real options (no strawmen); score them against explicit criteria in a trade-off matrix. If the matrix does not produce a clear winner, a **spike** is allowed: timeboxed, run only in a disposable area (scratch directory or throwaway worktree), whose product is knowledge written into the document, never product code. Converge into a recommendation with explicit rationale.
- **strategic** — define the level taxonomy (`N1..Nk`) that fits this territory; give a verdict per level (enter / don't enter / enter partially) with justification.
- **rca** — trace the causal chain from the observed symptom through the real code (cite `path:line` at each link) using 5 Whys or an equivalent method; confirm the root cause; converge into a phased remediation plan (`D1..Dk`).
- **item** — transcribe the request **as received**, verbatim where useful; interpret what each requirement means inside this project; converge into explicit decisions.

**Stop condition:** if the analysis starts specifying the solution at proposal level of detail, stop and go to the Handoff (§8). Designing the solution is `/proposal`'s job.

## Phase 2 — Consolidation with the user

Before writing the final document, review every open question (`AQ-NN`) with the user:

- Each `AQ-NN` has an explicit **Owner** ∈ `operator`, `proposal`, `spike`, `deferred`. A question may also be **answered inline** (the answer goes in "Answer"); answering does not remove the owner. The one exception is a question struck through as obsolete, which has no owner.
- Owner `deferred` means: record it as a deferred item to be tracked outside this study (e.g. in the project's issue tracker).
- Ending the session without a verdict is legitimate: `Status: Exploratory — no decision`, every `AQ-NN` owned, Handoff filled (even if just "none — archived").

## Document location and naming

- Save as `docs/features/<Feature>/Analysis_<Feature>.md`. The `Analysis_` prefix is mandatory.
- `<Feature>` is `PascalCase_With_Underscores`, matching the rest of that feature's directory.
- **If the file already exists**: read it, then ask whether to (a) update it in place (never renumber or remove existing `AQ-NN`), or (b) create a new analysis that supersedes it (add a banner at the top of the old one; leave its body intact).

## Template

Exactly 9 sections, in this order. A section that does not apply says so explicitly — it is never omitted. Write the prose in the project's documentation language; keep these headings.

```markdown
# Analysis — <Feature>

**Type**: discovery | capability | decision | strategic | rca | item
**Date**: YYYY-MM-DD   (from the system `date` command, never invented)
**Status**: Draft | Exploratory — no decision | Validated | Handed-off | Superseded
**Related**: decision records, features, inception docs, proposals

> This document is **not** a proposal. It is the study that precedes one. It implements nothing.

## 1. Question under analysis
## 2. Current state                 ← real, verified paths from Phase 0 (never placeholders)
## 3. <Mode body>                   ← taxonomy | matrix | discovery tree | RCA | …
## 4. Verdict / Recommendation      ← or "Exploratory — no decision"
## 5. Architecture fit              ← what runs where (local vs shared/central), if the project distinguishes; otherwise one line "N/A"
## 6. Risks of the recommendation
## 7. AQ — Open questions
## 8. Handoff                       ← /proposal <X>[, <Y>…] | decision record candidate | deferred item | "none — archived"
## 9. Sources
```

Rules for the sections:

- **Intro line first.** Each section starts with at least one line of prose before any sub-heading.
- **§7**: one bullet per question: `- **AQ-NN** — <question>. **Owner**: <owner>. **Answer**: <inline, once resolved>`. A bullet may span several indented blocks (a table, a caveat). Ids are sequential from `AQ-01` with no gaps or duplicates. They are **stable**: never renumber or delete. A resolved question gets an inline answer; an obsolete one is ~~struck through~~ with a reason.
- **§8 Handoff** is mandatory and never empty. Minimum: `none — archived` plus one sentence of justification. In `discovery` mode, list at least one candidate with its `/proposal <X>` command.
- **§5**: if the project has no local/central split, write only "N/A".

## Status lifecycle

- `Draft` (initial) → `Validated` (the user validated the verdict) → `Handed-off` (at least one derived proposal exists).
- `Draft` → `Exploratory — no decision` (closed with no verdict, every `AQ-NN` owned) → may later become `Validated` if resumed.
- Any state → `Superseded` when a later analysis replaces it: add a banner at the top, never rewrite the body.
- No other transitions. No automatic or timed transitions.

## Rules

- Write only to `docs/features/**/Analysis_*.md` (plus a scratch area for a spike). Never touch product code.
- A new feature directory or any other new top-level folder is created only after explicit user confirmation if it is ambiguous.
- Announce the mode before Phase 1.
- Never transcribe secrets.

## Quality checklist (self-check before finishing)

- [ ] Phase 0 was done for real — project docs, inception, related decisions and real code paths read.
- [ ] The mode was announced before Phase 1.
- [ ] All 9 sections are present, in order; Type and Status use the listed values.
- [ ] The "not a proposal" disclaimer sits between the header and §1.
- [ ] §3 matches the mode's method (catalog / matrix + recommendation / taxonomy + verdicts / root cause + plan / structured understanding).
- [ ] Every `AQ-NN` is sequential, stable, and has an owner (or is struck through with a reason).
- [ ] §8 Handoff is non-empty.
- [ ] Every cited path exists; no secret values appear.
- [ ] An existing analysis was updated in place or superseded with a banner — never silently overwritten.
- [ ] Nothing outside `docs/` (and an ephemeral scratch area, if a spike ran) was created or changed.

## Examples

```
/analysis Notification Retry Strategy               # mode inferred, announced, then Phases 0→2
/analysis Notification Retry Strategy discovery     # explicit mode (the token can be anywhere)
/analysis rca Webhook signature mismatch on retry   # root-cause investigation
/analysis Search Backend Options decision           # trade-off matrix + recommendation
```
