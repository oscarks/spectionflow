# Getting started

This guide takes you from zero to a reviewed feature in about ten minutes of setup.

## 1. Install

Spectionflow skills are folders with a `SKILL.md` (the Agent Skills format used by Claude Code and compatible agents).

```sh
git clone <this repo> spectionflow
cd spectionflow
./install.sh /path/to/your/project     # copies skills to /path/to/your/project/.claude/skills
```

Other targets:

| Command | Installs into |
|---|---|
| `./install.sh --user` | `~/.claude/skills` (all your projects) |
| `./install.sh --dir some/dir` | any folder your agent reads skills from |
| `./install.sh --only "proposal review"` | only the listed skills |

The installer never overwrites: an existing skill folder is skipped. Remove it first to reinstall.

## 2. Let the skills learn your project

The skills have no config file. They discover how your project builds and tests from your repository:
README, `CLAUDE.md` / `AGENTS.md`, package manifests and the code itself. Two minutes spent on a
good README or `AGENTS.md` (how to build, test, lint; conventions) pays off in every skill.

## 3. Run your first feature

Pick a small feature. The names below are examples.

```text
/proposal Notification_Retry
```

The agent explores your code, asks about anything ambiguous and writes
`docs/features/Notification_Retry/Proposal_Notification_Retry.md`, including a phased
**Implementation Plan**. Read it. Edit it. **Approve it** (set `Status: Approved`) — this is the
main human checkpoint.

```text
/implement Notification_Retry phase 1
/review Notification_Retry phase 1
```

`/implement` codes phase 1 and runs your build, lint and tests. `/review` checks it against the
proposal and writes `Review_Phase_1_Notification_Retry.md` with a verdict. If the verdict is
`CHANGES REQUIRED`, fix the findings (ask the agent to, or run `/implement` again) and re-review.

Repeat for each phase, then close with:

```text
/review Notification_Retry final
```

## 4. Or run everything at once

```text
/pipeline Notification_Retry all
```

The pipeline drives proposal → implement → review for each phase, loops on fixes (bounded),
verifies all acceptance criteria and does the final review. It stops at the human checkpoints.
Resume an interrupted run with `/pipeline Notification_Retry resume`.

## 5. Starting from an idea instead of a feature

```text
/inception init <your product sketch>
/inception discovery
/inception scope
/inception finalize
```

This produces `docs/inception/` and a seed proposal per Milestone 1 feature. Expand a seed with `/proposal`.
Drop briefs, interview notes or an old spec into `docs/inception/sources/` before you start — the skill reads them.

## 6. When you are unsure *what* to build

Use `/analysis` before `/proposal`: `/analysis Search Backend Options decision` compares options in a matrix;
`/analysis rca <symptom>` finds a root cause. Its output hands off to `/proposal`.

## Working in an existing codebase

Nothing special is needed. `/analysis capability` or `/analysis item` is a good first step to map what
exists; `/proposal` records the current state of the code it touches (with real paths) before proposing changes.

## Tips

- One feature = one folder in `docs/features/`. Name it `PascalCase_With_Underscores`.
- Keep phases small enough to implement and review in one sitting.
- Commit the `docs/features/<Feature>/` folder with the code: the documents are the audit trail.
- The agent writes in your documentation language; headings stay in English.
- Never paste secrets into proposals or sources; the skills cite where a secret lives, not its value.
