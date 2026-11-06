# Spectionflow

Document-driven skills that take a feature from idea to reviewed code with an AI coding agent.
Plain instructions, no runtime, no dependencies.

| Skill | What it does |
|---|---|
| `/inception` | Lightweight inception: pain, customer, value hypothesis and Milestone 1 scope |
| `/analysis` | Pre-proposal study (discovery, capability, decision, strategic, root cause, item) |
| `/proposal` | The what and why: problem, solution, business rules, acceptance criteria and a phase roadmap |
| `/ai-spec` | The how, for one phase: an executable spec (design, rules, state machines, tests, traceability) |
| `/implement` | Implements one phase from its AI-SPEC |
| `/review` | Reviews a phase (or the whole feature) against the AI-SPEC and the proposal and writes a verdict |
| `/pipeline` | Runs proposal → (ai-spec → implement → review) per phase → final review, with human checkpoints |

Documentation: [docs/README.md](docs/README.md) — start with [getting started](docs/getting-started.md) and the [workflow overview](docs/WORKFLOW.md).

## Install

Skills are folders with a `SKILL.md` (the Agent Skills format used by Claude Code and compatible agents).

```sh
./install.sh /path/to/your/project        # -> /path/to/your/project/.claude/skills
./install.sh --user                       # -> ~/.claude/skills
./install.sh --dir some/skills/dir        # any agent that reads skills from a folder
./install.sh --only "proposal ai-spec implement review"     # a subset
```

Or copy the folders from `skills/` by hand. `/implement` and `/review` read the AI-SPEC that `/ai-spec` writes, and `/pipeline` calls all of them, so install them together (a subset such as `"proposal ai-spec implement review"` works).

## Use

```
/inception init My product idea…
/analysis Notification Retry Strategy
/proposal Notification_Retry
/ai-spec Notification_Retry phase 1
/implement Notification_Retry phase 1
/review Notification_Retry phase 1
/pipeline Notification_Retry all
```

Artifacts land in `docs/` of your project (`docs/features/<Feature>/…`).

## License

MIT — see [LICENSE](LICENSE).
