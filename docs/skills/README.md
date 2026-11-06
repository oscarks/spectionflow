# Skills reference

Spectionflow ships six skills. Each one reads the document written by the previous step and writes its own, so the work stays auditable and resumable.

| Skill | One-line purpose | Writes | Reference |
|---|---|---|---|
| `/inception` | Turn a product sketch into the minimum for a first milestone | `docs/inception/Product_Definition.md`, `docs/inception/Scope_and_Milestones.md`, seed proposals | [inception](inception.md) |
| `/analysis` | Study a theme before proposing a solution | `docs/features/<Feature>/Analysis_<Feature>.md` | [analysis](analysis.md) |
| `/proposal` | Write the single spec of a feature, with a phased plan | `docs/features/<Feature>/Proposal_<Feature>.md` | [proposal](proposal.md) |
| `/implement` | Implement one phase of the plan (code + tests) | code, tests; edits only the Proposal's `Status` line | [implement](implement.md) |
| `/review` | Verify one phase (or the whole feature) against the Proposal | `Review_Phase_<N>_<Feature>.md`, `Review_Final_<Feature>.md` | [review](review.md) |
| `/pipeline` | Orchestrate all of the above for one feature | `Progress_<Feature>.md` and drives the other skills | [pipeline](pipeline.md) |

All produced documents are described in the [artifact reference](../artifacts.md).

## How the skills chain

```mermaid
flowchart LR
    I["/inception<br/>(optional)"] --> A["/analysis<br/>(optional)"]
    I --> P
    A --> P["/proposal"]
    P --> H{{"Human approves<br/>the Proposal"}}
    H --> M["/implement phase N"]
    M --> R["/review phase N"]
    R -- "CHANGES REQUIRED" --> M
    R -- "APPROVED" --> N{"More phases?"}
    N -- yes --> M
    N -- no --> F["/review final"]
    F -- "CHANGES REQUIRED" --> M
    F -- "APPROVED" --> D["Proposal Status: Implemented"]
```

- `/inception` and `/analysis` are optional. `/proposal` uses them when their documents exist.
- The Proposal is the only spec. There is no separate technical specification.
- The human approves the Proposal before any code is written.
- The reviewer never fixes what it finds; the fix goes back through `/implement`, and a fresh `/review` issues the new verdict.
- `/pipeline` runs this whole loop in one session, with a limit of 3 fix rounds per phase.

## Command cheat-sheet

| I want to... | Run |
|---|---|
| Start a product from an idea | `/inception init <name and sketch>` |
| Define pain, customer and value hypothesis | `/inception discovery` |
| Define Milestone 1 | `/inception scope` |
| Create seed proposals from Milestone 1 | `/inception finalize` |
| See what inception documents exist | `/inception status` |
| Study a theme (mode inferred) | `/analysis Notification Retry Strategy` |
| Study with an explicit mode | `/analysis Search Backend Options decision` |
| Investigate a bug's root cause | `/analysis rca Webhook signature mismatch on retry` |
| Write the spec | `/proposal Notification_Retry` |
| Implement the first pending phase | `/implement Notification_Retry` |
| Implement a specific phase | `/implement Notification_Retry phase 2` |
| Review a phase | `/review Notification_Retry phase 2` |
| Review the whole feature | `/review Notification_Retry final` |
| Run everything for a feature | `/pipeline Notification_Retry all` |
| Run a single phase end to end | `/pipeline Notification_Retry phase 1` |
| Continue an interrupted run | `/pipeline Notification_Retry resume` |

## Conventions shared by all skills

- **Feature names** are `PascalCase_With_Underscores` (for example `Notification_Retry`). Features live directly under `docs/features/`; there is no module level.
- **Project discovery**: skills read your README, `CLAUDE.md` / `AGENTS.md` (if any), package or build manifests, existing code and docs. Build, test and lint commands come from the repository; when unclear, the skill asks.
- **Language**: documents are written in the language of your project docs. Section headings stay in English.
- **Dates** come from the shell `date` command, never from memory.
- **No invented facts**: every path cited in a document must exist; secrets are never transcribed (the document cites where they live, not their value).
- **Human decides**: status changes such as `Approved` happen only when you approve in the conversation.
