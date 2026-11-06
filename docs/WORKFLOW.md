# The Spectionflow workflow

Spectionflow turns an idea into reviewed code through small, document-driven steps. Each skill reads
the previous step's document and writes its own, so the work is auditable and resumable.

```mermaid
flowchart LR
    I["/inception<br/>(optional)"] --> A["/analysis<br/>(optional)"]
    A --> P["/proposal<br/>what and why"]
    I --> P
    P -->|approve| S["/ai-spec<br/>phase N"]
    S -->|review spec| M["/implement<br/>phase N"]
    M --> R["/review<br/>phase N"]
    R -->|CHANGES REQUIRED| M
    R -->|APPROVED| N{more phases?}
    N -->|yes| S
    N -->|no| F["/review final"]
    PL["/pipeline"] -.drives.-> P
    PL -.drives.-> S
    PL -.drives.-> M
    PL -.drives.-> R
    PL -.drives.-> F
```

## Who does what

- **You decide**: what the product is, which option wins, whether the proposal is approved, whether each phase spec is right, what is deferred.
- **The agent executes**: explores the code, drafts documents, implements a phase, reviews with evidence.
- **Two levels of spec**: the Proposal says what and why for the whole feature; the AI-SPEC says how, for one phase, precisely enough to implement without questions.
- **Documents carry state**: the Proposal and AI-SPEC status lines and the review verdicts say where a feature stands.

## Stages and artifacts

| Stage | Skill | Writes | Reads |
|---|---|---|---|
| Inception | `/inception` | `docs/inception/*`, seed proposals | `docs/inception/sources/` |
| Research | `/analysis` | `docs/features/<Feature>/Analysis_<Feature>.md` | project docs, code |
| Planning | `/proposal` | `Proposal_<Feature>.md` (what/why, rules, criteria, phase roadmap) | analysis, inception, code |
| Specification | `/ai-spec` | `AI-SPEC_<Feature>_Phase_<N>.md` (one per phase) | the approved proposal, code |
| Implementation | `/implement` | code and tests for one phase | the AI-SPEC, the proposal |
| Review | `/review` | `Review_Phase_<N>_<Feature>.md`, `Review_Final_<Feature>.md` | the AI-SPEC, the proposal, the code |
| Orchestration | `/pipeline` | `Progress_<Feature>.md` | all of the above |

## Human checkpoints

1. After `/proposal`: you approve (or edit) the Proposal. Nothing is specified or implemented before that.
2. After each `/ai-spec`: you review the phase spec before `/implement`. (`/pipeline` in `all` mode accepts the Draft and continues unless you asked to review specs; in a `phase N` run it stops for your OK.)
3. After each `/review`: you see the verdict; `CRITICAL` findings block progress.
4. After the final review: you decide what to do with the deferred items.

## Going deeper

- [Methodology](methodology.md) — why the workflow looks like this
- [Getting started](getting-started.md) — install and first run
- [Skills reference](skills/README.md) — one page per skill
- [Artifacts reference](artifacts.md) — file layout, ids, statuses, templates
- [Inception](inception.md), [Development](development.md), [Writing executable specs](specification.md)
