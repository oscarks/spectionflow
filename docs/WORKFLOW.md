# The Spectionflow workflow

Spectionflow turns a feature idea into reviewed code through a chain of small, document-driven steps.
Each skill reads the previous step's document and writes its own, so the work is auditable and resumable.

```
/inception ──► /analysis ──► /proposal ──► /implement ──► /review ──► (repeat per phase) ──► final /review
 (optional)    (optional)     the spec       one phase     one phase
                         └──────────────── /pipeline runs it all ───────────────┘
```

| Skill | Produces | Reads |
|---|---|---|
| `/inception` | `docs/inception/Product_Definition.md`, `Scope_and_Milestones.md`, seed proposals | `docs/inception/sources/` |
| `/analysis` | `docs/features/<Feature>/Analysis_<Feature>.md` | project docs, code |
| `/proposal` | `docs/features/<Feature>/Proposal_<Feature>.md` (includes the phased Implementation Plan) | analysis, inception, code |
| `/implement` | code + tests for one phase | the Proposal |
| `/review` | `Review_Phase_<N>_<Feature>.md`, `Review_Final_<Feature>.md` | the Proposal, the code |
| `/pipeline` | `Progress_<Feature>.md` (checklist) and drives the others | everything above |

## Conventions

- `<Feature>` is `PascalCase_With_Underscores`; features live in `docs/features/<Feature>/`.
- The **Proposal is the single spec**: business rules `RN-NN`, acceptance criteria `CA-F<phase>-NN`,
  open questions `AQ-NN`. Implementation and review trace back to those ids.
- Skills discover your build, test and lint commands from the repository (README, manifests); they ask if unclear.
- Documents are written in the language of your project docs.
- Inception here is the **lightweight** version: pain, customer, value hypothesis and Milestone 1.
