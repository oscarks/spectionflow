# `/inception`

## Purpose

Lightweight product inception. It answers the minimum: **what** to build first, **for whom**, and **how to know it worked**, enough to define Milestone 1 and to give `/proposal` product context.

Out of scope for this skill: market research, risk analysis, a refined backlog, architecture and stack decisions. It does not write them.

## When to use / not use

Use it when:
- you are starting a new product from a sketch;
- you want Milestone 1 defined before writing proposals.

Do not use it when:
- the product already exists and you only need to specify one feature (go to `/proposal`, or `/analysis` first if there is uncertainty);
- you expect market data or competitor research: the skill never researches or invents them.

## Invocation and arguments

```
/inception [init | discovery | scope | finalize | status]
```

| Sub-mode | Writes | Notes |
|---|---|---|
| `init <name and sketch>` | `docs/inception/`, `docs/inception/sources/`, `docs/inception/README.md` | If `Product_Definition.md` or `Scope_and_Milestones.md` already exist, creates nothing and shows what exists. |
| `discovery` | `docs/inception/Product_Definition.md` | At most 5 questions, one at a time. |
| `scope` | `docs/inception/Scope_and_Milestones.md` | Proposes Milestone 1 and asks for approval. |
| `finalize` | `docs/features/<Feature>/Proposal_<Feature>.md` (seeds) | Requires both documents to exist and be approved. |
| `status` | nothing | Prints a table: document, exists?, one-line summary. |

Examples:

```
/inception init Notifier - a service that delivers webhooks reliably to customer endpoints
/inception discovery
/inception scope
/inception finalize
/inception status
```

## Inputs read

- What you wrote after `init` (name and sketch).
- `docs/inception/sources/`: briefs, interview notes, customer research, an old spec. At `init` and at the start of `discovery` and `scope` the skill lists the folder (one line per file) and reads files about product, customer, pain or scope. For a `.pdf` or `.docx` it reads a sibling `<name>.md` extraction if one exists; otherwise it says the file could not be read and moves on. Architecture or stack documents are listed but ignored.
- The project's README / `CLAUDE.md` / `AGENTS.md` to pick the documentation language.

## Outputs written

```
docs/inception/README.md
docs/inception/Product_Definition.md
docs/inception/Scope_and_Milestones.md
docs/inception/sources/                       (you put files here)
docs/features/<Feature>/Proposal_<Feature>.md (seed, one per Milestone 1 feature)
```

## What the skill does, step by step

1. **`init`**: create the folders, capture the product name (asks once if missing), write `docs/inception/README.md` if absent, read the sources, and suggest `/inception discovery`.
2. **`discovery`**: read the sources, then ask at most 5 questions, one at a time, to settle: the **pain** (specific, frequent, relevant to the customer's decisions; one, at most two), the **customer** (ideal customer profile and first segment), the **value hypothesis** (`If we offer X -> the customer gets Y -> with impact Z`) and **how we will know it worked** (one observable signal). It writes a one-page document with product name and sketch at the top, the sources used, and one section per item. Suggests `/inception scope`.
3. **`scope`**: read the sources, propose **Milestone 1** (the smallest cut that proves the value hypothesis) and ask for approval. The milestone has a title, an outcome, 2 to 5 features (each with a short `PascalCase_With_Underscores` name, one sentence, and a `committed` or `stretch` mark), 2 to 4 verifiable exit criteria, and an out-of-scope list. Writes a `## Milestone 1` section. Suggests `/inception finalize`.
4. **`finalize`**: for each Milestone 1 feature, create a **seed** proposal with the title, `**Status**: Seed (from Inception)`, the feature's sentence, its scope slice, and links to the two inception documents. Never overwrites an existing proposal. Reports next steps: `/proposal <first feature>` to expand the seed, or `/pipeline <first feature> all`.

## Rules and guardrails

- **The human decides.** The skill proposes, asks and records only what you approve. It never invents a pain, a customer or a number.
- **Provenance tags.** Every statement ends with a bracketed tag:
  - `[from-source:<file>]`: came from a file in `docs/inception/sources/`;
  - `[from-operator]`: you said it;
  - `[assumed]`: the skill's hypothesis, to be validated.
  A statement from a source that you then confirmed keeps `[from-source:<file>]`.
- **Contradictions are surfaced, not resolved.** If a source contradicts what you wrote, the skill records the source's statement and tells you in the same turn: what the sketch said, what the source says, which file. You decide.
- **Non-destructive.** It creates or appends; it never deletes or overwrites existing documents.
- It does no research and writes no product code.

## Human checkpoints

- Answering the (at most 5) discovery questions.
- Approving Milestone 1 before `finalize`. `finalize` stops and says what is missing if either document is absent or unapproved.

## Common mistakes

- Putting files in `sources/` and expecting the skill to know about a PDF it cannot read: add a `.md` extraction next to it.
- Asking inception for risks, backlog or architecture. They are out of scope here.
- Running `finalize` before approving both documents.
- Expecting competitor analysis: the skill has no research capability and will not make numbers up.

## Worked example

Sample product: Notifier, which delivers webhooks reliably.

```
/inception init Notifier - reliable webhook delivery for customer endpoints
/inception discovery
```

Excerpt of `docs/inception/Product_Definition.md`:

```markdown
# Product Definition - Notifier

**Sketch**: reliable webhook delivery for customer endpoints
**Sources used**: sources/support-tickets-summary.md

## Pain
Customers lose events when their endpoint is down for a few minutes, and
support cannot tell which events were lost. [from-source:support-tickets-summary.md]

## Customer
Backend teams of B2B SaaS products that notify their own customers by webhook. [from-operator]

## Value hypothesis
If we retry failed deliveries automatically and show delivery status -> the
customer stops losing events -> with fewer than 1 "missing event" ticket per week. [assumed]

## How we will know it worked
Support tickets tagged "missing event" drop below 1 per week. [from-operator]
```

Excerpt of `docs/inception/Scope_and_Milestones.md` after `/inception scope`:

```markdown
## Milestone 1 - Reliable delivery

**Outcome**: no event is lost when an endpoint is down for up to 24 hours. [assumed]

**Features**
- `Notification_Retry` - retry failed deliveries with backoff (committed) [from-operator]
- `Delivery_Log` - show the status of each delivery attempt (committed) [from-operator]
- `Replay_Button` - resend a delivery manually (stretch) [assumed]

**Exit criteria**
- A delivery that fails is retried automatically until it succeeds or the limit is reached.
- Support can see every attempt of a delivery.

**Out of scope**: Milestone 2+ - payload transformation
```

`/inception finalize` then creates `docs/features/Notification_Retry/Proposal_Notification_Retry.md` with `**Status**: Seed (from Inception)`, and suggests `/proposal Notification_Retry`.
