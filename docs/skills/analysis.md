# `/analysis`

## Purpose

Produces the **study that precedes** `/proposal`. It diverges before it converges, never implements anything, and may legitimately end with `Status: Exploratory — no decision`. The output is `Analysis_<Feature>.md`: a nine-section document with stable open questions (`AQ-NN`, each with an owner) and an explicit handoff.

## When to use / not use

Use it when:
- you need to discover which features exist within a theme;
- you must choose between options and want the trade-offs written down;
- something breaks and you need a root-cause analysis before planning a fix;
- the feature carries real technical or decision uncertainty.

Do not use it when the problem and solution are already clear: go straight to `/proposal`. If the study starts specifying the solution at proposal level of detail, the skill stops and hands off to `/proposal`.

## Invocation and arguments

```
/analysis <theme> [discovery|capability|decision|strategic|rca|item]
```

The mode token (case-insensitive) can be anywhere; the remaining tokens are the theme. Without a mode token, the skill infers one from the theme, **announces it before Phase 1** ("Inferred mode: `decision` — say so if that's not what you meant."), and asks if it is not confident. With no theme at all it asks for one.

| Mode | Method | Question it answers | Body of section 3 |
|---|---|---|---|
| `discovery` | Opportunity-solution tree + SWOT | What features exist within this theme? | Tree plus a catalog of candidate features (`F-NN`, name, what it solves, dependencies, priority) |
| `capability` | Domain/technology exploration | What does this territory offer vs. our reality? | Capability inventory, applicability, gap table with real paths |
| `decision` | Feasibility + trade-off matrix + optional spike | Which option, and why not the others? | Options, options x criteria matrix, recommendation |
| `strategic` | Level taxonomy + verdict per level | Should we enter this territory, at what level? | `N1..Nk` taxonomy and a verdict per level |
| `rca` | 5 Whys / causal chain | Why does it break, and what is the plan? | Causal chain anchored in `path:line`, confirmed root cause, phased plan `D1..Dk` |
| `item` | Requirements as received -> decisions | What does this request mean here? | Requirements transcribed as received, interpretation, decisions |

Examples:

```
/analysis Notification Retry Strategy               # mode inferred, announced, then Phases 0-2
/analysis Notification Retry Strategy discovery     # explicit mode
/analysis rca Webhook signature mismatch on retry   # root-cause investigation
/analysis Search Backend Options decision           # trade-off matrix + recommendation
```

## Inputs read

- README, `CLAUDE.md` / `AGENTS.md` (if present) and project docs, to derive documentation language and conventions.
- `docs/inception/` if it exists (the what/why).
- Existing decision records, proposals and analyses that constrain the theme. A decision is checked to be still in force (not superseded) before being used as a premise.
- The real codebase paths the theme touches.

## Outputs written

`docs/features/<Feature>/Analysis_<Feature>.md` (the `Analysis_` prefix is mandatory). If the project already organizes docs differently, the skill follows that convention and says so. A spike may use a disposable scratch area; no product code is touched.

If the file already exists, the skill reads it and asks whether to (a) update it in place (never renumbering or removing existing `AQ-NN`) or (b) create a new analysis that supersedes it (a banner at the top of the old one; its body stays intact).

## What the skill does, step by step

1. **Parse arguments and announce the mode.** If you correct the mode, only Phase 1 is redone.
2. **Phase 0 - common exploration** (all modes): learn the project; choose the location; read inception docs; read related decisions; explore the real code (every cited path must be real); never transcribe secrets.
3. **Phase 1 - mode method (diverge, then converge)**: build the tree, inventory, matrix, taxonomy, causal chain or requirement interpretation. In `decision` mode, if the matrix gives no clear winner, a timeboxed **spike** is allowed, run only in a disposable area; its product is knowledge written into the document, never product code.
4. **Phase 2 - consolidation with you.** Every `AQ-NN` is reviewed with you. Each has an **Owner**: `operator`, `proposal`, `spike` or `deferred` (to be tracked outside this study, for example in your issue tracker). A question can also be answered inline; answering does not remove the owner. A question struck through as obsolete has no owner.
5. **Write the document** using the template (see [artifacts](../artifacts.md#analysis)).

## Rules and guardrails

- Writes only `docs/features/**/Analysis_*.md` (plus a scratch area for a spike). Never touches product code.
- A new feature directory or top-level folder is created only after explicit confirmation if it is ambiguous.
- The mode is announced before Phase 1.
- Secrets are never transcribed.
- Status lifecycle: `Draft` -> `Validated` -> `Handed-off`; `Draft` -> `Exploratory — no decision` (may later become `Validated`); any state -> `Superseded` (banner at the top, body never rewritten). No automatic or timed transitions.

## Human checkpoints

- Confirming or correcting the announced mode.
- Phase 2: reviewing each open question and its owner; validating the verdict (which moves `Draft` to `Validated`).
- Choosing update-in-place vs. supersede when the file exists.

## Common mistakes

- Treating an analysis as a proposal and specifying endpoints and schemas in it.
- Forcing a verdict when the evidence does not support one. `Exploratory — no decision` is valid.
- Citing paths that were not verified.
- Renumbering or deleting `AQ-NN` after publication.
- Leaving section 8 (Handoff) empty. The minimum is `none — archived` plus one sentence of justification; in `discovery` mode list at least one `/proposal <X>` candidate.
- Using `deferred` as a way to avoid deciding without recording a reason.

## Worked example

```
/analysis Notification Retry Strategy decision
```

Excerpt of `docs/features/Notification_Retry/Analysis_Notification_Retry.md`:

```markdown
# Analysis — Notification_Retry

**Type**: decision
**Date**: 2026-11-06
**Status**: Validated
**Related**: docs/inception/Scope_and_Milestones.md

> This document is **not** a proposal. It is the study that precedes one. It implements nothing.

## 1. Question under analysis
How should failed webhook deliveries be retried: in-process timers, a database-backed
queue polled by a worker, or an external message broker?

## 2. Current state
Deliveries are sent once in `src/delivery/sender.ts:31`; a failure is logged and dropped.
The project already has a `jobs` table used by `src/jobs/worker.ts`.

## 3. Options and trade-off matrix
| Criterion | A. In-process timers | B. DB-backed queue | C. External broker |
|---|---|---|---|
| Survives restart | No | Yes | Yes |
| New infrastructure | None | None | Yes |
| Operational effort | Low | Low | High |

## 4. Verdict / Recommendation
Option B: it survives restarts and reuses the existing worker.

## 5. Architecture fit
N/A

## 6. Risks of the recommendation
Polling latency; a poison message can block a worker (mitigated by an attempt limit).

## 7. AQ — Open questions
- **AQ-01** — What is the maximum number of attempts? **Owner**: operator. **Answer**: 8 attempts over 24 hours.
- **AQ-02** — Is the existing `jobs` table safe for concurrent workers? **Owner**: spike.

## 8. Handoff
/proposal Notification_Retry

## 9. Sources
- src/delivery/sender.ts, src/jobs/worker.ts
```

Note that `AQ-02` has owner `spike`: `/proposal` will refuse to proceed on it until it is answered or waived.
